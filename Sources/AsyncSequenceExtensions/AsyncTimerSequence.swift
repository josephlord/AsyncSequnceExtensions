

import Foundation

/// The sequence with return a Void every TimeInterval from when the iterator is created
/// There will never be two values ready to be taken immediately, If two timeperiods pass between calls to
/// next then one of the events will be skipped. The timer events are all relative to timer creation not the last
/// time the value is provided.
/// Example if the interval is 10 seconds if you create the iterator and call next on it the item will provided
/// in 10 seconds. If you then wait 5 seconds before calling init you will receive the event 5 seconds after that.
/// If it is then 35s before the call to next it will immediately return one value, if you call next again it will five
/// seconds before it receives a value.
@available(iOS 15.0, macOS 12.0, *)
public struct AsyncTimerSequence : AsyncSequence {
    
    public typealias AsyncIterator = AsyncTimerIterator
    
    public typealias Element = ()
    
    public let interval: TimeInterval
    
    public init(interval: TimeInterval) {
        self.interval = interval
    }
    
    public func makeAsyncIterator() -> AsyncTimerIterator {
        return AsyncTimerIterator(interval: interval)
    }

    public actor AsyncTimerIterator : AsyncIteratorProtocol {
        private(set) var timer: Timer?
        private var continuation: (() -> Void)?
        
        convenience init(interval: TimeInterval) {
            self.init()
            let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
                guard let s = self else { return }
                Task.detached { await s.tick() }
            }
            Task {
                await self.setTimer(t)
            }
            RunLoop.main.add(t, forMode: .default)
        }
        
        private func setTimer(_ t: Timer) {
            self.timer = t
        }
        
//        private init() {}
        
//        convenience init(interval: TimeInterval) {
//            self.init()
//            async {
//                //await startTimer(interval: interval)
//                let t = Timer(timeInterval: interval, repeats: true) { _ in
//                    guard let s = s else { return }
//                    detach { await s.tick() }
//                }
//                timer = t
//                RunLoop.main.add(t, forMode: .default)
//            }
//        }
//
//        private func startTimer(interval: TimeInterval) {
//            weak var s = self
//            let t = Timer(timeInterval: interval, repeats: true) { _ in
//                guard let s = s else { return }
//                detach { await s.tick() }
//            }
//            timer = t
//            RunLoop.main.add(t, forMode: .default)
//        }
        
        private func tick() async {
            continuation?()
            continuation = nil
        }
        
        public func next() async throws -> ()? {
            await withCheckedContinuation { continuation in
                self.continuation = {
                    continuation.resume(with: .success(()))
                }
            }
        }
        
        deinit {
            print("Iterator deinit")
        }
    }
}
