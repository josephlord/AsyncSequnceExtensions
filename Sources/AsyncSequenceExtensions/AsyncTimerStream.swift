//
//  File.swift
//  
//
//  Created by Joseph Lord on 03/07/2021.
//

import Foundation
import _Concurrency

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
public struct AsyncTimerSequence2 : AsyncSequence {
    
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
        private var continuation: CheckedContinuation<()?, Never>?
        
        init(interval: TimeInterval) {
            let t = Timer(fire: .now, interval: interval, repeats: true) { [weak self] _ in
                if let continuation = self?.continuation {
                    self?.continuation = nil
                    continuation.resume(with: .success(()))
                }
            }
            timer = t
            RunLoop.main.add(t, forMode: .default)
        }
        
        public func next() async throws -> ()? {
            await withCheckedContinuation { continuation in
                self.continuation = continuation
            }
        }
        
        deinit {
            timer?.invalidate()
        }
    }
    
}
