
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
                if demand > 0 {
                    demand -= 1
                    return
                }
                
                let _: Void = await withCheckedContinuation { continuation in
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
        }
        
        private func mainLoop(seq: AsyncSequenceType, sub: S) {
            taskHandle = Task {
                do {
                    try await withTaskCancellationHandler {
                        Task.detached {
                            let  cont = await self.innerActor.getContinuationToFireOnCancelation()
                            cont?.resume()
                        }
                    } operation: {
                        for try await element in seq {
                            await self.innerActor.waitUntilReadyForMore()
                            guard !Task.isCancelled else { return }
                            let newDemand = sub.receive(element)
                            let cont = await self.innerActor.updateDemandAndReturnContinuation(demand: newDemand)
                            assert(cont == nil, "If we are't waiting on the demand the continuation will always be nil")
                        }
                        sub.receive(completion: .finished)
                        return
                    }
                } catch {
                    if error is CancellationError { return }
                    sub.receive(completion: .failure(error))
                }
            }
        }
        
        init(sequence: AsyncSequenceType, subscriber: S) {
            self.mainLoop(seq: sequence, sub: subscriber)
        }
                
        func request(_ demand: Subscribers.Demand) {
            Task {
                let cont = await innerActor.updateDemandAndReturnContinuation(demand: demand)
                cont?.resume()
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
