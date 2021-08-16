//
//  File.swift
//  
//
//  Created by Joseph Lord on 14/07/2021.
//

import XCTest
import AsyncSequenceExtensions
import Combine

@available(macOS 12.0, iOS 15.0, *)
class PublisherAsyncSequenceTests : XCTestCase {
    
    static let timerInterval = 0.01
    
    let publisher = Timer.publish(
        every: PublisherAsyncSequenceTests.timerInterval,
        tolerance: PublisherAsyncSequenceTests.timerInterval / 10,
        on: .main, in: .default)
            .autoconnect()
            .map { _ in CFAbsoluteTimeGetCurrent() }
            .setFailureType(to: Error.self)
            
    
    func testPublisherSanityCheck() {
        let expect = expectation(description: "SomeValues")
        var deltas: [CFAbsoluteTime] = []
        let startTime = CFAbsoluteTimeGetCurrent()
        var previousTime = startTime
        let cancellable = publisher
            .sink(
                receiveCompletion: { _ in XCTFail() },
                receiveValue: { time in
                deltas.append(time - previousTime)
                previousTime = time
                if deltas.count >= 10 { expect.fulfill() }
            })
        waitForExpectations(timeout: 2, handler: nil)
        _ = cancellable // lifetime extension
    }
    
    func testPublisherAsyncSequenceBasic() async throws {
        let sut = publisher.asyncSequence
        let startTime = CFAbsoluteTimeGetCurrent()
        var previousTime = startTime
        var deltas: [CFAbsoluteTime] = []
        for try await time in sut {
            deltas.append(time - previousTime)
            previousTime = time
            if deltas.count >= 10 { break }
        }
        let endTime = CFAbsoluteTimeGetCurrent()
        
        
        let gapsRelativeToTarget = deltas.dropFirst().map { $0 / Self.timerInterval }
        // Enable this too look at the jitter between calls
        // gapsRelativeToTarget.forEach { print($0) }
        let averageGap = gapsRelativeToTarget.reduce(0.0, +) / Double(gapsRelativeToTarget.count)
        print("Average relative time: \(averageGap)")
        XCTAssert((0.9...2.5).contains(averageGap))
        
        XCTAssertLessThan(startTime - endTime, 0.2)
    }
}
