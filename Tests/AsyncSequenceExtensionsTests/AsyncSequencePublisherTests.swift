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
final class AsyncSequencePublisherTests: XCTestCase {
    
    func testAsyncSequencePublisherBasic() throws {
        var counter = 0
        let itemsToExpect = 100
        let asyncSequence = AsyncTimerSequence(interval: 0.001)
            .prefix(itemsToExpect)
            .map { _ -> Int in
                counter += 1
                return counter
            }
        let sut = asyncSequence.publisher
        var lastReceivedValue = 0
        let e = expectation(description: "Receive completion")
        let cancellable = sut.sink { completion in
            print(completion)
            XCTAssertEqual(itemsToExpect, lastReceivedValue)
            e.fulfill()
        } receiveValue: { val in
            print("received \(val)")
            XCTAssertEqual(lastReceivedValue + 1, val)
            lastReceivedValue = val
        }
        waitForExpectations(timeout: 0.5, handler: nil)
        _ = cancellable
    }
}


final class SubscriptionDemandExperimentTests: XCTestCase {
    func testAddUnlimitedDemand() {
        let unlimited = Subscribers.Demand.unlimited
        
        XCTAssertEqual(unlimited, unlimited + .max(1))
        XCTAssertEqual(unlimited, unlimited + .none)
        XCTAssertEqual(unlimited, unlimited + .unlimited)
        XCTAssertEqual(unlimited, unlimited + .max(.max))
        var unl = unlimited
        unl -= 1
        XCTAssertEqual(unlimited, unl)
        XCTAssert(unl > 1)
    }
    
    func testAddLimitedDemand() {
        let three = Subscribers.Demand.max(3)
        
        XCTAssertEqual(.max(4), three + .max(1))
        XCTAssertEqual(.max(3), three + .none)
    }
}
