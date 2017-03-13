//
//  ViewController.swift
//  GASOS
//
//  Created by Perry Fraser on 2/4/17.
//  Copyright © 2017 Perry Fraser. All rights reserved.
//


import CoreLocation
import UIKit
import SwiftyJSON
import SwiftyButton
import Alamofire
import ChameleonFramework


// the following UUID's were generated on 1/15/2017 using https://www.uuidgenerator.net
//let uuid1 = "57ee374b-4369-47de-bf34-ed42cb45dbe8"
//let uuid2 = "d3830e87-9b71-4797-af49-f16e754dc44b"
//let uuid3 = "eff06ca8-ec39-4d22-9aed-418d60b16239"
//let uuid4 = "39f326bb-7a23-42a7-9a1d-fd4a8da16f0e"
//let uuid5 = "681879d3-9ea2-409d-a14e-22dc6992f4aa"


class ViewController: UIViewController {
    
    @IBOutlet weak var debugInfo: UITextView!
    @IBOutlet weak var startExploringMessage: UILabel!
    
    let locationManager = CLLocationManager()
    
    let soundPlayer = SOSSoundEngine()
    
    var mapBeaconInfo = [String: BeaconInfo]()
    
    @IBOutlet weak var startButton: FlatButton!
    
    var monitoring: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if DEBUG
                debugInfo.isHidden = false
        #endif
        
        
        // Multiline UILable
        startExploringMessage.lineBreakMode = .byWordWrapping
        startExploringMessage.numberOfLines = 0 // For stupid resons this isn't working FIXME. For now, reduce to one line? Original text: Begin exploring.\nMake sure you have your headphones on!
        
        

        // Disable sleep - you don't want to have to keep tapping your phone to keep it awake
        UIApplication.shared.isIdleTimerDisabled = true
        
        // make sure we can use location services
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        
        startButton.color = .flatRed
        startButton.highlightedColor = .flatRedDark
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func startMonitor(_ sender: UIButton) {
        startExploringMessage.isHidden = false
        
        if monitoring {
            sender.setTitle("Start!", for: .normal)
            monitoring = false
            StopMonitoringForBeacons()
        } else {
            StartMonitoringForBeacons()
            sender.setTitle("Listening!", for: .normal)
            monitoring = true
        }
        
    }
    
    
    func BleLog(_ msg: String) {
        #if DEBUG // Only runs in debug mode
            debugInfo.text = msg + "\n" + debugInfo.text
            print(msg)
        #endif
    }
    
    private func StopMonitoringForBeacons() {
        
        // stop monitoring for the beacons we know about...
        for beaconInfo in mapBeaconInfo {
            stopMonitoringItem(item: beaconInfo.value)
        }

        // make sure the sound engine shuts all the sounds down too
        soundPlayer.silenceAllSounds()
    }
    
    private func StartMonitoringForBeacons() {
        // let's try and load the JSON from the intarnets!!!
        //let configuration = URLSessionConfiguration.ephemeral
        //configuration.urlCache?.removeAllCachedResponses()
        //let sessionManager = Alamofire.SessionManager(configuration: configuration)
        
        // using an ephemeral session manager, which means things should not get cached
        // after you shut the app down. So every time you re-run the app I think this means
        // the JSON will get redownloaded: https://developer.apple.com/reference/foundation/urlsessionconfiguration/1855950-ephemeral
        // let sessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.ephemeral)
        
        URLCache.shared.removeAllCachedResponses()
        
        // this next complex bit of code downloads the manifest from Amazon S3,
        // parses it and then starts monitoring for the beacons listed in it
        
        Alamofire.request("https://s3.amazonaws.com/sfraser/ExampleSOSManifest.json")
            // URLCache.shared.removeAllCachedResponses()
            // sessionManager.request("https://s3.amazonaws.com/sfraser/ExampleSOSManifest.json")
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseString { response in
                
                switch response.result {
                case .success:
                    // convert string to JSON - based on examples from https://github.com/SwiftyJSON/SwiftyJSON
                    if let dataFromString = response.result.value?.data(using: .utf8, allowLossyConversion: false) {
                        
                        let json = JSON(data: dataFromString)
                        
                        // loop through all the beacons defined in the JSON and start monitoring for them
                        if json["soundsOfSelf"].exists() {
                            
                            for (_,beaconJson):(String, JSON) in json["soundsOfSelf"] {
                                
                                self.startMonitoringItem(item: BeaconInfo(name: beaconJson["beaconAlias"].stringValue,
                                                                          uuid: UUID(uuidString: beaconJson["beaconUuid"].stringValue)!,
                                                                          majorValue: CLBeaconMajorValue(beaconJson["major"].intValue),
                                                                          minorValue: CLBeaconMinorValue(beaconJson["minor"].intValue),
                                                                          sound: beaconJson["soundName"].stringValue,
                                                                          panning: beaconJson["pan"].floatValue,
                                                                          immediateVolume: beaconJson["immediateVolume"].floatValue,
                                                                          farVolume: beaconJson["farVolume"].floatValue,
                                                                          nearRssiParameter: beaconJson["nearRssiParameter"].floatValue,
                                                                          backgroundSound: beaconJson["backgroundSound"].stringValue,
                                                                          backgroundVolume: beaconJson["backgroundVolume"].floatValue
                                ))
                                
                            }
                        }
                        else {
                            self.BleLog("Failed to parse JSON: \(response.result.value)")
                        }
                    }
                    else {
                        self.BleLog("Failed to read JSON: \(response.result.value)")
                    }
                case .failure(let error):
                    self.BleLog("Failed to load SOS Manifest: \(error)")
                }
                
        }
        
        
    }
    
}


//
// The following extension allows our ViewController to get events related
// to location services
//
extension ViewController : CLLocationManagerDelegate {
    
    private func beaconRegionWithItem(item:BeaconInfo) -> CLBeaconRegion {
        let beaconRegion = CLBeaconRegion(proximityUUID: item.uuid,
                                          //major: item.majorValue,
                                          //minor: item.minorValue,
                                          identifier: item.name)
        return beaconRegion
    }
    
    func startMonitoringItem(item: BeaconInfo) {
        let beaconRegion = beaconRegionWithItem(item: item)
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
        mapBeaconInfo[item.uuid.uuidString] = item
        BleLog("LISTENING for \(item.name)")
    }
    
    func stopMonitoringItem(item: BeaconInfo) {
        let beaconRegion = beaconRegionWithItem(item: item)
        locationManager.stopMonitoring(for: beaconRegion)
        locationManager.stopRangingBeacons(in: beaconRegion)
        mapBeaconInfo.removeValue(forKey: item.uuid.uuidString)
        BleLog("STOPPED listening for \(item.name)")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        BleLog("Failed monitoring region \(region?.identifier): \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        BleLog("Location manager failed: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        // print(">>> didRangeBeacons in \(region.proximityUUID)")
        
        do {
            if beacons.isEmpty {
                 // BleLog("No Beacons nearby")
                // soundPlayer.silenceAllSounds()
                if let beaconInfo = mapBeaconInfo[region.proximityUUID.uuidString] {
                    
                    if soundPlayer.isSoundPlaying(named: beaconInfo.sound) {
                        soundPlayer.silenceSound(named: beaconInfo.sound)
                        beaconInfo.currentVolume = 0
                        
                        let newStatus = "[\(beaconInfo.name)],Out of Range"
                        
                        if(beaconInfo.currentStatus != newStatus) {
                            beaconInfo.currentStatus = newStatus
                            BleLog(newStatus)
                        }
                        
                        // turn off the background sound if there was one for this beacon
                        if !beaconInfo.backgroundSound.isEmpty {
                            soundPlayer.silenceSound(named: beaconInfo.backgroundSound)
                        }
                    }
                }
            }
            else {
                
                for rangedBeacon in beacons {
                    
                    //BleLog("FOUND: \(nameForProximity(proximity: rangedBeacon.proximity)))")
                    
                    if let beaconInfo = mapBeaconInfo[rangedBeacon.proximityUUID.uuidString] {
                        
                        let newStatus = "[\(beaconInfo.name)],\(nameForProximity(proximity: rangedBeacon.proximity))"
                        
                        if(beaconInfo.currentStatus != newStatus) {
                            beaconInfo.currentStatus = newStatus
                            BleLog(newStatus)
                        }
                        
                        if rangedBeacon.proximity == CLProximity.unknown {
                            
                            // not sure what to do here - for now we shall ignore
                            
                            //soundPlayer.silenceSound(named: (beaconInfo.sound))
                            //beaconInfo.currentVolume = 0
                            
                            // if there was a background sound turn it off
                            //if beaconInfo.backgroundSound.isEmpty {
                            //    soundPlayer.silenceSound(named: beaconInfo.backgroundSound)
                            //}
                        }
                        else if rangedBeacon.proximity == CLProximity.immediate {
                            
                            // no matter what if there was a background sound play it
                            if !(beaconInfo.backgroundSound.isEmpty) {
                                // BleLog("Playing background sound: \(beaconInfo.backgroundSound) at \(beaconInfo.backgroundVolume)")
                                try soundPlayer.playSound(named: (beaconInfo.backgroundSound), atVolume: (beaconInfo.backgroundVolume))
                            }
                            
                            beaconInfo.currentVolume = beaconInfo.immediateVolume
                            try soundPlayer.playSound(named: (beaconInfo.sound), atVolume: beaconInfo.currentVolume, panned: (beaconInfo.pan))
                            
                            
                        }
                        else if rangedBeacon.proximity == CLProximity.far {
                            if !(beaconInfo.backgroundSound.isEmpty) {
                                // BleLog("Playing background sound: \(beaconInfo.backgroundSound) at \(beaconInfo.backgroundVolume)")
//                                try soundPlayer.playSound(named: (beaconInfo.backgroundSound), atVolume: (beaconInfo.backgroundVolume))
                                try soundPlayer.playSound(named: beaconInfo.backgroundSound, atVolume: beaconInfo.farVolume)
                            }
                            
                            beaconInfo.currentVolume = beaconInfo.farVolume
                            try soundPlayer.playSound(named: (beaconInfo.sound), atVolume: beaconInfo.currentVolume, panned: (beaconInfo.pan))
                            
                        }
                        else {
                            
                            // no matter what if there was a background sound play it
                            if !(beaconInfo.backgroundSound.isEmpty) {
                                // BleLog("Playing background sound: \(beaconInfo.backgroundSound) at \(beaconInfo.backgroundVolume)")
                                try soundPlayer.playSound(named: (beaconInfo.backgroundSound), atVolume: (beaconInfo.backgroundVolume))
                            }
                            
                            beaconInfo.currentVolume = (1 - (Float(-rangedBeacon.rssi)/beaconInfo.nearRssiParameter))
                            try soundPlayer.playSound(named: (beaconInfo.sound), atVolume: (beaconInfo.currentVolume), panned: (beaconInfo.pan))
                            
                        }
                        
                    }
                    
                }
                
            }
            
        } catch SOSError.fileAssetNotFound(let fileName){
            BleLog("Could not find file " + fileName)
        } catch {
            BleLog("Unknown Error")
        }
        
    }
    
    
}

func ==(item: BeaconInfo, beacon: CLBeacon) -> Bool {
    return ((beacon.proximityUUID.uuidString == item.uuid.uuidString)
        && (Int(beacon.major) == Int(item.majorValue))
        && (Int(beacon.minor) == Int(item.minorValue)))
}

func nameForProximity(proximity: CLProximity) -> String {
    switch proximity {
    case .unknown:
        return "Unknown"
    case .immediate:
        return "Immediate"
    case .near:
        return "Near"
    case .far:
        return "Far"
    }
}

//func volumeForProximity(proximity: CLProximity) -> Float {
//    switch proximity {
//    case .unknown:
//        return 0
//    case .immediate:
//        return 1
//    case .near:
//        return 0.6
//    case .far:
//        return 0.1
//    }
//}

