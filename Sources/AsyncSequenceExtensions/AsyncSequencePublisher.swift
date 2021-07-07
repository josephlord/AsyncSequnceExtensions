
import Combine
import Foundation

@available(iOS 15.0, macOS 12.0, *)
public struct AsyncSequencePublisher<AsyncSequenceType> : Publisher where AsyncSequenceType : AsyncSequence {
    public typealias Output = AsyncSequenceType.Element
    public typealias Failure = Error
    
    let sequence: AsyncSequenceType
    
    public init(_ sequence: AsyncSequenceType) {
        self.sequence = sequence
    }
    
    fileprivate class ASPSubscription<S> : Subscription
    where S : Subscriber, S.Failure == Error, S.Input == AsyncSequenceType.Element {
        private var taskHandle: Task<(), Never>?
        private let innerActor = Inner()
        
        private actor Inner {
            var demand: Subscribers.Demand = .none
            
            var demandUpdatedContinuation: CheckedContinuation<Void, Never>?
            
            fileprivate func waitUntilReadyForMore() async {
                
                Swift.print("Wait on Demand")
                
                if demand > 0 {
                    demand -= 1
                    Swift.print("Demand OK - continue")
                    return
                }
                
                let _: Void = await withCheckedContinuation { continuation in
                    Swift.print("Set continuation")
                    demandUpdatedContinuation = continuation
                }
            }
            
            func updateDemandAndReturnContinuation(demand: Subscribers.Demand) -> CheckedContinuation<Void, Never>? {
                defer { demandUpdatedContinuation = nil }
                self.demand += demand
                guard demand > 0 else { return nil }
                return demandUpdatedContinuation
            }
            
            func getContinuationToFireOnCancelation()  -> CheckedContinuation<Void, Never>? {
                defer { demandUpdatedContinuation = nil }
                return demandUpdatedContinuation
            }
            
            deinit {
//                if let cont = demandUpdatedContinuation {
//                    DispatchQueue.main.async { cont.resume() } // Fire continuation safely to ensure task can be can be cancelled
//                }
            }
        }
        
        private func mainLoop(seq: AsyncSequenceType, sub: S) {
            Swift.print("MainLoop")
            taskHandle = Task {
                let sentinel = Sentinel()
                do {
                    try await withTaskCancellationHandler {
                        Task.detached {
                            let  cont = await self.innerActor.getContinuationToFireOnCancelation()
                            cont?.resume()
                        }
                    } operation: {
                        Swift.print("Loop")
                        for try await element in seq {
                            Swift.print("element: \(element)")
                            await self.innerActor.waitUntilReadyForMore()
                            guard !Task.isCancelled else { return }
                            let newDemand = sub.receive(element)
                            let cont = await self.innerActor.updateDemandAndReturnContinuation(demand: newDemand)
                            assert(cont == nil, "If we arent' waiting on the demand the continuation will always be nil")
                        }
                        sub.receive(completion: .finished)
                        return
                    }
                } catch {
                    Swift.print("Sentinel count: \(Sentinel.count), sentinel value: \(sentinel.val)")
                    if error is CancellationError { return }
                    sub.receive(completion: .failure(error))
                }
            }
            Swift.print("taskHandle set")
        }
        
        init(sequence: AsyncSequenceType, subscriber: S) {
            self.mainLoop(seq: sequence, sub: subscriber)
            Swift.print("init returned")
        }
                
        func request(_ demand: Subscribers.Demand) {
            Swift.print("request: \(demand)")
            Task {
                Swift.print("Will await setDemand")
                let cont = await innerActor.updateDemandAndReturnContinuation(demand: demand)
                cont?.resume()
                Swift.print("Back from await setDemand")
            }
        }
        
        func cancel() {
            taskHandle?.cancel()
        }
        
        deinit {
            cancel()
        }
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, Error == S.Failure, AsyncSequenceType.Element == S.Input {
        let subscription = ASPSubscription(sequence: sequence, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension AsyncSequence {
    public var publisher: AsyncSequencePublisher<Self> {
        AsyncSequencePublisher(self)
    }
}

class Sentinel {
    static var count = 0
    let val = Int.random(in: Int.min...Int.max)
    init() {
        Self.count += 1
    }
    
    deinit {
        Self.count -= 1
    }
}
