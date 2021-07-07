//
//  File.swift
//  
//
//  Created by Joseph Lord on 03/07/2021.
//

import Foundation
import DequeModule

@available(macOS 12.0, iOS 15.0, *)
/// Wraps a Timer in an Async Sequence of Void. If you call next() on the interator it will return
public struct AsyncTimerSequence : AsyncSequence {
    
    public typealias AsyncIterator = Iterator
    public typealias Element = Void
    
    let interval: TimeInterval
    
    public init(interval: TimeInterval) {
        self.interval = interval
    }
    
    public func makeAsyncIterator() -> Iterator { Iterator(interval: interval) }
    
    /// The reason this iterator needs to be a class is so that the timer can be invalidated on deinit (although being an actor would be prefered but
    /// for continuation resume bug (SR-14875, SR-14841)
    public final class Iterator : AsyncIteratorProtocol, UnsafeSendable {
        
        /// The InnerActor is only necessary because of the bug calling
        private actor InnerActor {
            private var continuations: Deque<CheckedContinuation<(), Never>> = []
            
            fileprivate func getContinuation() -> CheckedContinuation<(), Never>? {
                return continuations.popFirst()
            }
            
            fileprivate func addContinuation(_ continuation: CheckedContinuation<(), Never>) {
                continuations.append(continuation)
            }
        }
        private let safeContinuations = InnerActor()
        private let timer: Timer?
        
        fileprivate init(interval: TimeInterval) {
            let safeConts = safeContinuations
            let timer = Timer(fire: .now, interval: interval, repeats: true) { _ in
                Task {
                    let continuation = await safeConts.getContinuation()
                    continuation?.resume()
                }
            }
            self.timer = timer
            RunLoop.main.add(timer, forMode: .default)
        }
        
        public func next() async throws -> ()? {
            await withCheckedContinuation { continuation in
                Task {
                    await safeContinuations.addContinuation(continuation)
                }
            }
            return ()
        }
        
        deinit {
            timer?.invalidate()
        }
    }
}
