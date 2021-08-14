//
//  File.swift
//  
//
//  Created by Joseph Lord on 10/07/2021.
//

import XCTest

@available(iOS 15.0, macOS 12.0, *)
actor SUTActor {
    var continuation: CheckedContinuation<(),Never>?
    var canGo = false
    
    func pause() async {
        if canGo { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) -> Void in
            if canGo {
                continuation.resume()
            } else {
                self.continuation = continuation
            }
        }
    }
    
    func go() {
        canGo = true
        continuation?.resume()
    }
}

@available(iOS 15.0, macOS 12.0, *)
final class ActorContinuationTests : XCTestCase {
    func testPauseGo() {
        let sut = SUTActor()
        let exp = expectation(description: "Will resume")
        
        Task.detached(priority: .high) {
            await sut.pause()
            exp.fulfill()
        }
            
        Task.detached (priority: .medium) {
        //    await Task.sleep(10_000)
            await sut.go()
        }
            
        waitForExpectations(timeout: 0.2, handler: nil)
        _ = sut // Ensure lifetime sufficient
    }
}
