
import Combine

@available(iOS 15.0, macOS 12.0, *)
public struct AsyncSequencePublisher<AsyncSequenceType> : Publisher where AsyncSequenceType : AsyncSequence {
    public typealias Output = AsyncSequenceType.Element
    public typealias Failure = Error
    
    let sequence: AsyncSequenceType
    
    public init(_ sequence: AsyncSequenceType) {
        self.sequence = sequence
    }
    
    fileprivate actor ASPSubscription<S> : Subscription
    where S : Subscriber, S.Failure == Error, S.Input == AsyncSequenceType.Element {
        
        var demand: Subscribers.Demand = .none
        var taskHandle: Task.Handle<(), Never>?

        var demandUpdatedContinuation: CheckedContinuation<Void, Never>?
        
        private func mainLoop(seq: AsyncSequenceType, sub: S) {
            Swift.print("MainLoop")
            taskHandle = detach {
                do {
                    Swift.print("Loop")
                    for try await element in seq {
                        Swift.print("element: \(element)")
                        await self.waitUntilReadyForMore()
                        guard !Task.isCancelled else { return }
                        await self.setDemand(demand: sub.receive(element))
                    }
                    sub.receive(completion: .finished)
                } catch {
                    if error is Task.CancellationError { return }
                    sub.receive(completion: .failure(error))
                }
            }
            Swift.print("taskHandle set")
        }
        
        private func waitUntilReadyForMore() async {
            
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
        
        nonisolated init(sequence: AsyncSequenceType, subscriber: S) {
            async {
                await mainLoop(seq: sequence, sub: subscriber)
            }
            Swift.print("init returned")
        }
        
        nonisolated func request(_ demand: Subscribers.Demand) {
            Swift.print("request: \(demand)")
            detach {
                Swift.print("Will await setDemand")
                await self.setDemand(demand: demand)
                Swift.print("Back from await setDemand")
            }
        }
        
        nonisolated func cancel() {
            detach {
                Swift.print("Cancel")
                await self.setCanceled()
                await self.demandUpdated()// Unblock so the main loop can hit the task cancellation guard
                
            }
        }
        
        private func demandUpdated() {
            demandUpdatedContinuation?.resume()
            demandUpdatedContinuation = nil
        }
        
        private func setCanceled() async {
            taskHandle?.cancel()
        }
        
        private func setDemand(demand: Subscribers.Demand) async {
            self.demand += demand
            guard demand > 0 else { return }
            demandUpdated()
        }
        
        deinit {
            taskHandle?.cancel()
            demandUpdatedContinuation?.resume()
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
