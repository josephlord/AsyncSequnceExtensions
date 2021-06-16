//
//  File.swift
//  
//
//  Created by Joseph on 16/06/2021.
//

import Foundation
import XCTest
import AsyncSequenceExtensions

@available(iOS 15.0, macOS 12.0, *)
final class AsyncTimerSequenceTests: XCTestCase {
    func testTimerPublisher() throws {
        let e = expectation(description: "Asynccomplete")
        let timerInterval = 0.0001
        let timerSequence = AsyncTimerSequence(interval: timerInterval)
        async(priority: .userInteractive) {
            let iterations = 30
            var deltas: [CFAbsoluteTime] = []
            deltas.reserveCapacity(iterations)
            var previousTime = CFAbsoluteTimeGetCurrent()
            for try await time in (timerSequence.prefix(iterations).map { _ in CFAbsoluteTimeGetCurrent() }) {
                deltas.append(time - previousTime)
                previousTime = time
            }
            
            let gapsRelativeToTarget = deltas.dropFirst().map { $0 / timerInterval }
            // Enable this too look at the jitter between calls
            // gapsRelativeToTarget.forEach { print($0) }
            let averageGap = gapsRelativeToTarget.reduce(0.0, +) / Double(gapsRelativeToTarget.count)
            print("Average relative time: \(averageGap)")
            XCTAssert((0.9...1.1).contains(averageGap))
            e.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}
