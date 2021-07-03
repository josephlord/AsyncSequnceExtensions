//
//  File.swift
//  
//
//  Created by Joseph Lord on 03/07/2021.
//

import Foundation
import Collections
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
        private var continuations: [CheckedContinuation<(), Never>] = []
        
        init(interval: TimeInterval) {
            let t = Timer(fire: .now, interval: interval, repeats: true) { [weak self] _ in
                guard let continuation = self?.continuations.first else { return }
                continuation.resume()
                self?.continuations.removeFirst()
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
        let itr = Iterator()
        Task {
            await itr.start(interval: interval)
        }
        return itr
    }
    
    public actor Iterator : AsyncIteratorProtocol {
        
        private var timer: Timer?
        private var continuations: [CheckedContinuation<(), Never>] = []
        
        fileprivate init() {}
        
        fileprivate func start(interval: TimeInterval) {
            let t = Timer(fire: .now, interval: interval, repeats: true) { [weak self] _ in
                guard let s = self else { return }
                Task.detached {
                    await s.fireContinuation()
                }
            }
            timer = t
            RunLoop.main.add(t, forMode: .default)
        }
        
        private func fireContinuation()  {
            guard !continuations.isEmpty else { return }
            continuations.removeFirst().resume()
        }
        
        public func next() async throws -> ()? {
            await withCheckedContinuation { continuation in
                self.continuations.append(continuation)
            }
            return ()
        }
        
        deinit {
            timer?.invalidate()
        }
    }
}
