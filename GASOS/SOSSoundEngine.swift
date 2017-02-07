//
//  SOSSoundEngine.swift
//  AudioTest4
//
//  Created by Scott Fraser on 1/10/17.
//  Copyright © 2017 Scott Fraser. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import Cephalopod

class SOSSoundEngine {
    
    var mapCephs = [String: Cephalopod]()
    var mapPlayers = [String: AVAudioPlayer]()
    var mapSounds = [String: NSDataAsset]()
    var currentBaseSound = ""
    
    init() {
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try! AVAudioSession.sharedInstance().setActive(true)
    }
    
    func silenceAllSounds() {
        for cephPod in mapCephs {
            
            cephPod.value.fadeOut()
            
            //avPlayer.value.setVolume( 0, fadeDuration: 1)
            //avPlayer.value.pause()
        }
    }
    
    func isSoundPlaying( named nameOfAudioFileInAssetCatalog: String ) -> Bool {
     
        if let player = mapPlayers[nameOfAudioFileInAssetCatalog] {
            return player.isPlaying
        }
        
        return false
    }
    
    
    
    // 
    // There can always be one base sound constantly playing. Call this to set it.
    // This base sound will eventually get silenced once the SOSSoundEngine realizes there are no 
    // other sounds playing, or if a new base sound is set.
    //
    func setBaseSound(named nameOfAudioFileInAssetCatalog: String, atVolume volume: Float) {
        
        // if the named sound passed in is different than what we are already playing, silence
        // the old sound
        if currentBaseSound != nameOfAudioFileInAssetCatalog {
            silenceSound(named: currentBaseSound)
        }
        
        currentBaseSound = nameOfAudioFileInAssetCatalog
        
        do {
            try playSound(named: nameOfAudioFileInAssetCatalog, atVolume: volume)
        }
        catch {
            print("Error playing \(nameOfAudioFileInAssetCatalog)")
        }
    }
    
    func silenceSound(named nameOfAudioFileInAssetCatalog: String) {
        
        do {
            try playSound(named: nameOfAudioFileInAssetCatalog, atVolume: 0)
            
            // if NO sounds are left playing - 
            
        }
        catch {
            print("Error silencing \(nameOfAudioFileInAssetCatalog)")
        }
    }
    
    func playSound(named nameOfAudioFileInAssetCatalog: String, atVolume newVolume: Float, panned: Float = 0) throws {
        
        // first check to see if we have already loaded this sound
        if mapSounds[nameOfAudioFileInAssetCatalog] == nil {
            guard let sound = NSDataAsset(name: nameOfAudioFileInAssetCatalog) else {
                throw SOSError.fileAssetNotFound(called: nameOfAudioFileInAssetCatalog)
            }
            
            mapSounds[nameOfAudioFileInAssetCatalog] = sound
        }
        
        do {
            
            // check to see if we already have a player for this sound
            
            if let ceph = mapCephs[nameOfAudioFileInAssetCatalog] {
                
                // if volume is zero make sure we pause the sound
                if newVolume == 0
                { ceph.fadeOut() }
                else {

                    if let player = mapPlayers[nameOfAudioFileInAssetCatalog] {
                        let oldVolume = player.volume
                        
                        if(!player.isPlaying) { player.play() }
                        player.pan = panned
                        
                        ceph.fade(fromVolume: Double(oldVolume), toVolume: Double(newVolume)) { finished in
                            // after the sound fades we check to see if nothing is left but the base sound
                            // if only the base sound is left playing, we silence it too - it should only
                            // be playing when we are picking up beacons from somewhere
                            if finished && !self.areAnySoundsPlayingOtherThanCurrentBase() {
                                self.silenceSound(named: self.currentBaseSound)
                            }
                            
                        }
                    }
                    
                }
            }
            else {
                let newPlayer = try AVAudioPlayer(data: (mapSounds[nameOfAudioFileInAssetCatalog]?.data)!)
                mapPlayers[nameOfAudioFileInAssetCatalog] = newPlayer
                mapCephs[nameOfAudioFileInAssetCatalog] = Cephalopod(player: newPlayer)
                newPlayer.volume = 0
                newPlayer.numberOfLoops = 0 // will loop forever
                newPlayer.pan = panned
                newPlayer.setVolume( newVolume, fadeDuration: 1)
                newPlayer.play()
            }
            
        } catch {
            print("error initializing AVAudioPlayer")
        }
    }
    
    private func areAnySoundsPlayingOtherThanCurrentBase() -> Bool {
        // loop through all sounds playing, ignoring the base sound -
        // we want to see if anything is playing that's not the base
        for player in mapPlayers {
            if player.key != currentBaseSound && player.value.volume > 0 && player.value.isPlaying {
                return true
            }
        }
        
        return false
    }
    
}

