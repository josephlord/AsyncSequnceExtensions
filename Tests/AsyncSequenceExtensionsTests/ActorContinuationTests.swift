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
        print("in pause")
        if canGo {
            print("canGo true before awat")
            return
        }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) -> Void in
            print("in withCheckedContinuation operation")
            if canGo {
                print("canGo true after awit")
                Task.detached { continuation.resume() }
            } else {
                self.continuation = continuation
            }
            print("completing withCheckedOperation closure")
        }
        print("awaitedContinuation resumed")
    }
    
    func go() {
        print("in go")
        canGo = true
        let continuation = self.continuation
        print(continuation == nil ? "nil cont" : "has cont")
        self.continuation = nil
        Task.detached {
            print("resuming continuation")
            continuation?.resume()
            print("did resume continuation")
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
final class ActorContinuationTests : XCTestCase {
    func testPauseGo() {
        let sut = SUTActor()
        let exp = expectation(description: "Will resume")
        
        Task.detached(priority: .high) {
            print("will await pause")
            await sut.pause()
            print("pause returned")
            exp.fulfill()
        }

        Task.detached(priority: .medium) {
            print("will await go")
            await sut.go()
            print("Boom")
        }
        waitForExpectations(timeout: 0.2, handler: nil)
        _ = sut // Ensure lifetime sufficient
    }
}
