//
//  AsyncPubTest.swift
//  AsyncSequenceExtensionsApp
//
//  Created by Joseph Lord on 23/06/2021.
//

import Foundation
import AsyncSequenceExtensions
import Combine

class AsyncPubTest {
    private var cancellable: Cancellable?
    private var counter = 0
    lazy var asyncSequence = { AsyncTimerSequence(interval: 0.1)
//        .prefix(itemsToExpect)
        .map { _ -> Int in
            self.counter += 1
            return self.counter
        }
    }()
    
    init() {
        cancellable = asyncSequence
            .publisher
            .sink { completion in
                switch completion {
                case .finished: print("Finished")
                case .failure: print("ERrrored")
                }
            } receiveValue: { val in
                print(val)
            }

    }
}


//var counter = 0
//let itemsToExpect = 1
//let asyncSequence = AsyncTimerSequence(interval: 0.01)
//    .prefix(itemsToExpect)
//    .map { _ -> Int in
//        counter += 1
//        return counter
//    }
//let sut = asyncSequence.publisher
//var lastReceivedValue = 0
//let e = expectation(description: "Receive completion")
//let cancellable = sut.sink { completion in
//    print(completion)
//    XCTAssertEqual(itemsToExpect, lastReceivedValue)
//    e.fulfill()
//} receiveValue: { val in
//    print("received \(val)")
//    XCTAssertEqual(lastReceivedValue + 1, val)
//    lastReceivedValue = val
//}
//waitForExpectations(timeout: 0.5, handler: nil)
//_ = cancellable
