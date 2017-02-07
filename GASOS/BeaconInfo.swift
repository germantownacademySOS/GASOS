import Foundation
import CoreLocation

class BeaconInfo {
    let name: String
    let uuid: UUID
    let majorValue: CLBeaconMajorValue
    let minorValue: CLBeaconMinorValue
    let sound: String
    let backgroundSound: String
    let backgroundVolume: Float
    
    // we store a little bit of information about the current known status of the beacon here
    var currentStatus: String
    
    // this is the last volume setting that was made related to the sound for this beacon
    var currentVolume: Float
    
    let pan: Float /* panning. -1.0 is left, 0.0 is center, 1.0 is right. */
    
    init(name: String, uuid: UUID, majorValue: CLBeaconMajorValue, minorValue: CLBeaconMinorValue, sound: String, panning: Float,
         backgroundSound: String = "", backgroundVolume: Float = 0) {
        self.name = name
        self.uuid = uuid
        self.majorValue = majorValue
        self.minorValue = minorValue
        self.sound = sound
        self.pan = panning
        self.backgroundSound = backgroundSound
        self.backgroundVolume = backgroundVolume
        
        currentStatus = ""
        currentVolume = 0
    }
    
    func getCurrentStatus() -> String { return currentStatus }
    
    func getCurrentVolumer() -> Float { return currentVolume }
    
}
