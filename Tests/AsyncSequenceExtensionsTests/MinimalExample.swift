//
//  File.swift
//  
//
//  Created by Joseph Lord on 23/06/2021.
//

import Foundation
import XCTest


// This is too minimised - not reproducing it here

@available(iOS 15.0, macOS 12.0, *)
actor MinimalDeadlock {
    nonisolated init(completion: @escaping () -> Void) {
        async {
            await mainLoop(completion: completion)
        }
        async {
            for _ in 0...1000 {
                await asyncSomething()
                await Task.sleep(1)
            }
        }
    }
    
    private func mainLoop(completion: @escaping  () -> Void) {
        detach {
            let url = Bundle.module.url(forResource: "TestFile", withExtension: "md")!
            let bytes = try await URLSession.shared.bytes(from: url, delegate: nil)
            var lastByte: UInt8? = nil
            for try await byte in bytes.0 {
                await self.asyncSomething()
                lastByte = byte
            }
            print(lastByte!)
            completion()
        }
    }
    
    private func asyncSomething() async {
        
    }
}

@available(iOS 15.0, macOS 12.0, *)
final class MinimalDeadlockTest: XCTestCase {
    
    func testDeadlockCase() throws {
        let e = expectation(description: "completion")
        let md = MinimalDeadlock {
            e.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
        _ = md
    }
}
