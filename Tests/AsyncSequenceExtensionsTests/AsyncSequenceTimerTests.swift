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
final class OriginalAsyncTimerSequenceTests: XCTestCase {
    func testTimerPublisher() throws {
        let e = expectation(description: "Asynccomplete")
        let timerInterval = 0.0001
        let timerSequence = AsyncTimerSequenceOriginal(interval: timerInterval)
        Task {//(priority: .userInteractive) {
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
            XCTAssert((0.9...1.9).contains(averageGap))
            e.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
        _ = timerSequence
    }
    
    func testTimerIterator() throws {
        let e = expectation(description: "Asynccomplete")
        let timerInterval = 0.0001
        let timerSequence = AsyncTimerSequenceOriginal(interval: timerInterval)
        Task {//(priority: .userInteractive) {
            let iterations = 30
            var deltas: [CFAbsoluteTime] = []
            deltas.reserveCapacity(iterations)
            var previousTime = CFAbsoluteTimeGetCurrent()
            let timerIterator = timerSequence.makeAsyncIterator()
            while deltas.count < iterations, let _ = try await timerIterator.next() {
            //for try await time in (timerSequence.prefix(iterations).map { _ in CFAbsoluteTimeGetCurrent() }) {
                let time = CFAbsoluteTimeGetCurrent()
                deltas.append(time - previousTime)
                previousTime = time
            }
            
            let gapsRelativeToTarget = deltas.dropFirst().map { $0 / timerInterval }
            // Enable this too look at the jitter between calls
            // gapsRelativeToTarget.forEach { print($0) }
            let averageGap = gapsRelativeToTarget.reduce(0.0, +) / Double(gapsRelativeToTarget.count)
            print("Average relative time: \(averageGap)")
            XCTAssert((0.9...1.9).contains(averageGap))
            e.fulfill()
            _ = timerIterator
        }
        waitForExpectations(timeout: 3, handler: nil)
        _ = timerSequence
    }

    func testTimerPublisher2() async throws {
//        let e = expectation(description: "Asynccomplete")
        let timerInterval = 0.10
        let timerSequence = AsyncTimerSequenceOriginal(interval: timerInterval)
        //async {//(priority: .userInteractive) {
            let iterations = 30
            var deltas: [CFAbsoluteTime] = []
            deltas.reserveCapacity(iterations)
            var previousTime = CFAbsoluteTimeGetCurrent()
        for try await _ in (timerSequence.prefix(iterations)) { //.map { _ in CFAbsoluteTimeGetCurrent() }) {
                let time = CFAbsoluteTimeGetCurrent()
                deltas.append(time - previousTime)
                previousTime = time
            }
            
            let gapsRelativeToTarget = deltas.dropFirst().map { $0 / timerInterval }
            // Enable this too look at the jitter between calls
            // gapsRelativeToTarget.forEach { print($0) }
            let averageGap = gapsRelativeToTarget.reduce(0.0, +) / Double(gapsRelativeToTarget.count)
            print("Average relative time: \(averageGap)")
            XCTAssert((0.9...1.9).contains(averageGap))
//            e.fulfill()
//        }
//        waitForExpectations(timeout: 3, handler: nil)
        _ = timerSequence
    }
    
    
    func testTimerMap() throws {
        let itemsToExpect = 5
        var counter = 0
        let asyncSequence = AsyncTimerSequenceOriginal(interval: 0.1)
            .prefix(itemsToExpect)
            .map { _ -> Int in
                counter += 1
                return counter
            }
        let e = expectation(description: "complete")
        Task {
            for try await i in asyncSequence {
                print(i)
            }
            for try await i in asyncSequence {
                print(i)
            }
            e.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}


@available(iOS 15.0, macOS 12.0, *)
final class AsyncTimerSequence2Tests: XCTestCase {
    func testTimerPublisher() throws {
        let e = expectation(description: "Asynccomplete")
        let timerInterval = 0.0001
        let timerSequence = AsyncTimerSequence(interval: timerInterval)
        Task {//(priority: .userInteractive) {
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
            XCTAssert((0.9...1.9).contains(averageGap))
            e.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
        _ = timerSequence
    }
    
    func testTimerIterator() throws {
        let e = expectation(description: "Asynccomplete")
        let timerInterval = 0.0001
        let timerSequence = AsyncTimerSequence(interval: timerInterval)
        Task {//(priority: .userInteractive) {
            let iterations = 30
            var deltas: [CFAbsoluteTime] = []
            deltas.reserveCapacity(iterations)
            var previousTime = CFAbsoluteTimeGetCurrent()
            let timerIterator = timerSequence.makeAsyncIterator()
            while deltas.count < iterations, let _ = try await timerIterator.next() {
            //for try await time in (timerSequence.prefix(iterations).map { _ in CFAbsoluteTimeGetCurrent() }) {
                let time = CFAbsoluteTimeGetCurrent()
                deltas.append(time - previousTime)
                previousTime = time
            }
            
            let gapsRelativeToTarget = deltas.dropFirst().map { $0 / timerInterval }
            // Enable this too look at the jitter between calls
            // gapsRelativeToTarget.forEach { print($0) }
            let averageGap = gapsRelativeToTarget.reduce(0.0, +) / Double(gapsRelativeToTarget.count)
            print("Average relative time: \(averageGap)")
            XCTAssert((0.9...1.9).contains(averageGap))
            e.fulfill()
            _ = timerIterator
        }
        waitForExpectations(timeout: 3, handler: nil)
        _ = timerSequence
    }

    func testTimerPublisher2() async throws {
//        let e = expectation(description: "Asynccomplete")
        let timerInterval = 0.10
        let timerSequence = AsyncTimerSequence(interval: timerInterval)
        //async {//(priority: .userInteractive) {
            let iterations = 30
            var deltas: [CFAbsoluteTime] = []
            deltas.reserveCapacity(iterations)
            var previousTime = CFAbsoluteTimeGetCurrent()
        for try await _ in (timerSequence.prefix(iterations)) { //.map { _ in CFAbsoluteTimeGetCurrent() }) {
                let time = CFAbsoluteTimeGetCurrent()
                deltas.append(time - previousTime)
                previousTime = time
            }
            
            let gapsRelativeToTarget = deltas.dropFirst().map { $0 / timerInterval }
            // Enable this too look at the jitter between calls
            // gapsRelativeToTarget.forEach { print($0) }
            let averageGap = gapsRelativeToTarget.reduce(0.0, +) / Double(gapsRelativeToTarget.count)
            print("Average relative time: \(averageGap)")
            XCTAssert((0.9...2.6).contains(averageGap))
//            e.fulfill()
//        }
//        waitForExpectations(timeout: 3, handler: nil)
        _ = timerSequence
    }
    
    
    func testTimerMap() throws {
        let itemsToExpect = 5
        var counter = 0
        let asyncSequence = AsyncTimerSequence(interval: 0.1)
            .prefix(itemsToExpect)
            .map { _ -> Int in
                counter += 1
                return counter
            }
        let e = expectation(description: "complete")
        Task {
            for try await i in asyncSequence {
                print(i)
            }
            for try await i in asyncSequence {
                print(i)
            }
            e.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}


@available(iOS 15.0, macOS 12.0, *)
final class AsyncTimerSequenceActorTests: XCTestCase {
    func testTimerPublisher() throws {
        let e = expectation(description: "Asynccomplete")
        let timerInterval = 0.0001
        let timerSequence = AsyncTimerActorSequence(interval: timerInterval)
        Task {//(priority: .userInteractive) {
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
            XCTAssert((0.9...1.9).contains(averageGap))
            e.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
        _ = timerSequence
    }
    
    func testTimerIterator() throws {
        let e = expectation(description: "Asynccomplete")
        let timerInterval = 0.0001
        let timerSequence = AsyncTimerActorSequence(interval: timerInterval)
        Task {//(priority: .userInteractive) {
            let iterations = 30
            var deltas: [CFAbsoluteTime] = []
            deltas.reserveCapacity(iterations)
            var previousTime = CFAbsoluteTimeGetCurrent()
            let timerIterator = timerSequence.makeAsyncIterator()
            while deltas.count < iterations, let _ = try await timerIterator.next() {
            //for try await time in (timerSequence.prefix(iterations).map { _ in CFAbsoluteTimeGetCurrent() }) {
                let time = CFAbsoluteTimeGetCurrent()
                deltas.append(time - previousTime)
                previousTime = time
            }
            
            let gapsRelativeToTarget = deltas.dropFirst().map { $0 / timerInterval }
            // Enable this too look at the jitter between calls
            // gapsRelativeToTarget.forEach { print($0) }
            let averageGap = gapsRelativeToTarget.reduce(0.0, +) / Double(gapsRelativeToTarget.count)
            print("Average relative time: \(averageGap)")
            XCTAssert((0.9...1.9).contains(averageGap))
            e.fulfill()
            _ = timerIterator
        }
        waitForExpectations(timeout: 3, handler: nil)
        _ = timerSequence
    }

    func testTimerPublisher2() async throws {
//        let e = expectation(description: "Asynccomplete")
        let timerInterval = 0.10
        let timerSequence = AsyncTimerActorSequence(interval: timerInterval)
        //async {//(priority: .userInteractive) {
            let iterations = 30
            var deltas: [CFAbsoluteTime] = []
            deltas.reserveCapacity(iterations)
            var previousTime = CFAbsoluteTimeGetCurrent()
        for try await _ in (timerSequence.prefix(iterations)) { //.map { _ in CFAbsoluteTimeGetCurrent() }) {
                let time = CFAbsoluteTimeGetCurrent()
                deltas.append(time - previousTime)
                previousTime = time
            }
            
            let gapsRelativeToTarget = deltas.dropFirst().map { $0 / timerInterval }
            // Enable this too look at the jitter between calls
            // gapsRelativeToTarget.forEach { print($0) }
            let averageGap = gapsRelativeToTarget.reduce(0.0, +) / Double(gapsRelativeToTarget.count)
            print("Average relative time: \(averageGap)")
            XCTAssert((0.9...2.6).contains(averageGap))
//            e.fulfill()
//        }
//        waitForExpectations(timeout: 3, handler: nil)
        _ = timerSequence
    }
    
    
    func testTimerMap() throws {
        let itemsToExpect = 5
        var counter = 0
        let asyncSequence = AsyncTimerActorSequence(interval: 0.1)
            .prefix(itemsToExpect)
            .map { _ -> Int in
                counter += 1
                return counter
            }
        let e = expectation(description: "complete")
        Task {
            for try await i in asyncSequence {
                print(i)
            }
            for try await i in asyncSequence {
                print(i)
            }
            e.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}
