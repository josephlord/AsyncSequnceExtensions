
import Combine

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
            
        }
        
        private func mainLoop(seq: AsyncSequenceType, sub: S) {
            Swift.print("MainLoop")
            taskHandle = Task.detached {
                do {
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
                } catch {
//                    if error is Task.CancellationError { return }
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
            self.setCanceled()
            Task {
                Swift.print("Cancel")
                let cont = await self.innerActor.getContinuationToFireOnCancelation()// Unblock so the main loop can hit the task cancellation guard
                cont?.resume()
            }
        }
        
        private func setCanceled() {
            taskHandle?.cancel()
        }
        
        deinit {
            taskHandle?.cancel()
          //  cancel()
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
