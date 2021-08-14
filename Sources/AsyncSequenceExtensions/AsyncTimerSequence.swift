//
//  File.swift
//  
//
//  Created by Joseph Lord on 03/07/2021.
//

import Foundation

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
    public final actor Iterator : AsyncIteratorProtocol {
        
        private var continuation: CheckedContinuation<(), Never>?
            
//            fileprivate func getContinuation() -> CheckedContinuation<(), Never>? {
//                defer { continuation = nil }
//                return continuation
//            }

        private var timer: Timer?
        
        fileprivate init(interval: TimeInterval) {
            self.timer = nil
            configureTimer(interval: interval)
        }
        
        nonisolated private func configureTimer(interval: TimeInterval) {
            let timer = Timer(fire: .now, interval: interval, repeats: true) { [weak self] _ in
                self?.fireAndClearContinuationNI()
            }
            RunLoop.main.add(timer, forMode: .default)
            Task {
                await self.setTimer(timer: timer)
            }
        }
        
        func setTimer(timer: Timer) {
            self.timer = timer
        }
        
        nonisolated private func fireAndClearContinuationNI() {
            Task {
                await self.fireAndClearContinuation()
            }
        }
        
        private func fireAndClearContinuation() {
            continuation?.resume()
            continuation = nil
        }
        
        public func next() async throws -> ()? {
            await withCheckedContinuation { continuation in
                assert(self.continuation == nil)
                self.continuation = continuation
            } as Void
            return ()
        }
        
        deinit {
            timer?.invalidate()
        }
    }
}
