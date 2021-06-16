import Combine

@available(iOS 15.0, *)
public struct AsyncSequencePublisher<AsyncSequenceType> : Publisher where AsyncSequenceType : AsyncSequence {
    public typealias Output = AsyncSequenceType.Element
    public typealias Failure = Error
    
    let sequence: AsyncSequenceType
    
    init(_ sequence: AsyncSequenceType) {
        self.sequence = sequence
    }
    
    fileprivate actor ASPSubscription<S> : Subscription
    where S : Subscriber, S.Failure == Error, S.Input == AsyncSequenceType.Element {
        var demand: Subscribers.Demand = .none
        let asyncSeq: AsyncSequenceType
        let subscriber: S
        var taskHandle: Task.Handle<(), Never>?
        var demandUpdated: (()->Void)?
        
        func mainLoop() -> Task.Handle<(), Never> {
            return async {
                do {
                    for try await element in asyncSeq {
                        await self.waitUntilReadyForMore()
                        guard !Task.isCancelled else { return }
                        demand = subscriber.receive(element)
                    }
                    
                    subscriber.receive(completion: .finished)
                } catch {
                    subscriber.receive(completion: .failure(error))
                }
            }
        }
        
        private func waitUntilReadyForMore() async {
            if demand == .unlimited { return }
            if demand > 0 {
                demand -= 1
                return
            }
            await withCheckedContinuation { continuation in
                self.demandUpdated = {
                    continuation.resume()
                }
            }
            await waitUntilReadyForMore() // Will recheck that there is positive demand
        }
        
        nonisolated init(sequence: AsyncSequenceType, subscriber: S) {
            asyncSeq = sequence
            self.subscriber = subscriber
            async {
                await mainLoop()
            }
        }
        
        nonisolated func request(_ demand: Subscribers.Demand) {
            async { await setDemand(demand: demand) }
        }
        
        nonisolated func cancel() {
            async {
                await setCanceled()
            }
        }
        
        private func setCanceled() async {
            taskHandle?.cancel()
        }
        
        private func setDemand(demand: Subscribers.Demand) async {
            self.demand = demand
            demandUpdated?()
        }
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, Error == S.Failure, AsyncSequenceType.Element == S.Input {
        let subscription = ASPSubscription(sequence: sequence, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

@available(iOS 15.0, *)
extension AsyncSequence {
    public var publisher: AsyncSequencePublisher<Self> {
        AsyncSequencePublisher(self)
    }
}
