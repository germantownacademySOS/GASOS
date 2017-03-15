import XCTest
import AVFoundation
@testable import Cephalopod

class FadeInTests: XCTestCase {
  
  var player: AVAudioPlayer!
  var cephalopod: Cephalopod!
    
  override func setUp() {
    super.setUp()
    
    player = TestBundle.soundPlayer()
    player.volume = 0
    cephalopod = Cephalopod(player: player)
  }
  
  func testStartVolume() {
    XCTAssertEqual(0.0, player.volume)
  }
  
  func testFadeIn_callFinishClosure() {
    let testExpectation = expectation(description: "test expectation")
    
    var finishedArgument: Bool?
    
    cephalopod.fadeIn(duration: 0.1, velocity: 1, onFinished: { finished in
      finishedArgument = finished
      testExpectation.fulfill()
    })
    
    waitForExpectations(timeout: 0.2) { error in }
    
    XCTAssert(finishedArgument!)
    XCTAssertEqual(1.0, player.volume)
  }
  
  func testFadeIn_cancelByCallingStop_callFinishClosure() {
    let testExpectation = expectation(description: "test expectation")
    
    var finishedArgument: Bool?
    
    cephalopod.fadeIn(duration: 0.1, velocity: 1, onFinished: { finished in
      finishedArgument = finished
      testExpectation.fulfill()
    })
    
    cephalopod.stop()
    
    waitForExpectations(timeout: 0.2) { error in }
    
    XCTAssertFalse(finishedArgument!)
    XCTAssertEqual(0.0, player.volume)
  }
  
  func testFadeIn_cancelByCallingFadeAgain_callFinishClosure() {
    let testExpectation = expectation(description: "test expectation")
    
    var finishedArgument: Bool?
    
    cephalopod.fadeIn(duration: 0.1, velocity: 1, onFinished: { finished in
      finishedArgument = finished
      testExpectation.fulfill()
    })
    
    cephalopod.fadeIn()
    
    waitForExpectations(timeout: 0.2) { error in }
    
    XCTAssertFalse(finishedArgument!)
    XCTAssertEqual(0.0, player.volume)
  }

}
