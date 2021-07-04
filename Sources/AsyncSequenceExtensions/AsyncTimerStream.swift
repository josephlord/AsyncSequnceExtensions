//
//  File.swift
//  
//
//  Created by Joseph Lord on 03/07/2021.
//

import Foundation
import DequeModule
//import _Concurrency

//extension Timer {
//    static func stream(interval: TimeInterval) -> AsyncStream<Void> {
//        AsyncStream(Void.self) { continuation in
//            var timer: Timer?
//            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) {
//                continuation.yield(())
//            }
//        }
//    }
//}


@available(macOS 12.0, iOS 15.0, *)
public struct AsyncTimerSequence : AsyncSequence {
    
    public typealias AsyncIterator = Iterator
    public typealias Element = Void
    
    let interval: TimeInterval
    
    public init(interval: TimeInterval) {
        self.interval = interval
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(interval: interval)
    }
    
    public final class Iterator : AsyncIteratorProtocol {
        
        private var timer: Timer?
        private var continuations:  Deque<CheckedContinuation<(), Never>> = []
        
        init(interval: TimeInterval) {
            let t = Timer(fire: .now, interval: interval, repeats: true) { [weak self] _ in
                self?.continuations.popFirst()?.resume()
            }
            timer = t
            RunLoop.main.add(t, forMode: .default)
        }
        
        public func next() async throws -> ()? {
            await withCheckedContinuation { continuation in
                self.continuations.append(continuation)
            }
        }
        
        deinit {
            timer?.invalidate()
        }
    }
}


@available(macOS 12.0, iOS 15.0, *)
public struct AsyncTimerActorSequence : AsyncSequence {
    
    public typealias AsyncIterator = Iterator
    public typealias Element = Void
    
    let interval: TimeInterval
    
    public init(interval: TimeInterval) {
        self.interval = interval
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(interval: interval)
    }
    
    public struct Iterator : AsyncIteratorProtocol {
        
        private actor InnerActor {
            private var continuations: Deque<CheckedContinuation<(), Never>> = []
            
            fileprivate func fireContinuation()  {
                continuations.popFirst()?.resume()
            }
            
            fileprivate func addContinuation(_ continuation: CheckedContinuation<(), Never>) {
                continuations.append(continuation)
            }
        }
        private let safeContinuations = InnerActor()
        private var timer: Timer?
        
        fileprivate init(interval: TimeInterval) {
            let safeConts = safeContinuations
            let t = Timer(fire: .now, interval: interval, repeats: true) { _ in
                Task {
                    await safeConts.fireContinuation()
                }
            }
            self.timer = t
            RunLoop.main.add(t, forMode: .default)
        }
        
        public func next() async throws -> ()? {
            await withCheckedContinuation { continuation in
                Task {
                    await safeContinuations.addContinuation(continuation)
                }
            }
            return ()
        }
        
        
    }
}
