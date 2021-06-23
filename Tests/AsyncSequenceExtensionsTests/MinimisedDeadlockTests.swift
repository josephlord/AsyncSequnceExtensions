//
//  File.swift
//  
//
//  Created by Joseph on 16/06/2021.
//

import Foundation

import XCTest
import AsyncSequenceExtensions
import Foundation
import Combine


@available(iOS 15.0, macOS 12.0, *)
final class MinimisedDeadlockTests: XCTestCase {
    
    func testDeadlockCase() throws {
        for _ in 0...100 {
            let itemsToExpect = 1
            let val = 1
            var received: Int? = nil
            let asyncSequence = AsyncTimerSequence(interval: 0.01)
                .prefix(itemsToExpect)
                .map { val }
            let sut = asyncSequence.deadlockPublisher
            
            let e = expectation(description: "Receive completion")
            let cancellable = sut
                .sink { completion in
                print(completion)
                e.fulfill()
            } receiveValue: { val in
                print("received \(val)")
                received = val
            }
            waitForExpectations(timeout: 0.5, handler: { _ in
                
            })
            XCTAssertEqual(val, received)
            _ = cancellable // Retain until end of the test run
        }
    }
}
