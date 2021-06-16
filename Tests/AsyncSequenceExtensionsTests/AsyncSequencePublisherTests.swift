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


@available(iOS 15.0, *)
final class AsyncSequencePublisherTests: XCTestCase {
    
    func testAsyncSequencePublisherBasic() throws {
        var counter = 0
        let itemsToExpect = 5
        let asyncSequence = AsyncTimerSequence(interval: 0.1)
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
            XCTAssertEqual(lastReceivedValue + 1, val)
            lastReceivedValue = val
        }
        //cancellable.request(Subscribers.Demand.unlimited)
        waitForExpectations(timeout: 8, handler: nil)
        _ = cancellable
    }
}
