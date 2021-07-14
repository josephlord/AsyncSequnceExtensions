
import Combine

@available(macOS 12.0, iOS 15.0, *)
extension Publisher where Self.Failure == Error {
    public var asyncSequence: PublisherAsyncSequence<Output> {
        PublisherAsyncSequence(publisher: self.eraseToAnyPublisher())
    }
}

@available(macOS 12.0, iOS 15.0, *)
public struct PublisherAsyncSequence<Element> : AsyncSequence {

    let publisher: AnyPublisher<Element, Error>

    public func makeAsyncIterator() -> Iterator {
        let itr = Iterator()
        publisher.receive(subscriber: itr)
        return itr
    }

    public class Iterator {
        
        private let iActor = InnerActor()
        
        /// Due to bug [SR-14875](https://bugs.swift.org/browse/SR-14875) we need to avoid calling continuations
        /// from the actor execution context currently which is why we wrap the state in this InnerActor instead of just making the Interator
        /// and actor
        private actor InnerActor {
            /// These typealiases are just for cleaner call sites
            typealias ElementContinuation = CheckedContinuation<Element?, Error>
            typealias SubsciptionContinuation = CheckedContinuation<Void, Never>
            
            private var subscription: Subscription?
            private var subscriptionContinuation: SubsciptionContinuation?
            private var continuation: ElementContinuation?
            
            func next() async throws -> Element? {
                if subscription == nil {
                    await withCheckedContinuation { continuation in
                        subscriptionContinuation = continuation
                    }
                }
                
                return try await withCheckedThrowingContinuation({ continuation in
                    self.continuation = continuation
                    subscription?.request(.max(1))
                })
            }
            
            func setSubscription(subscription: Subscription) -> SubsciptionContinuation? {
                defer { subscriptionContinuation = nil }
                assert(self.subscription == nil)
                self.subscription = subscription
                return subscriptionContinuation
            }
            
            /// You should resume the completion immediately after calling this
            func getAndClearMainCompletion() -> ElementContinuation? {
                defer { continuation = nil }
                return continuation
            }
            
            /// You should resume the completion immediately after calling this
            func getAndClearSubscriptionCompletion() -> SubsciptionContinuation? {
                defer { subscriptionContinuation = nil }
                return subscriptionContinuation
            }
        }

        private func receive(compl: Subscribers.Completion<Error>) async {
            let continuation = await iActor.getAndClearMainCompletion()
            assert(continuation != nil)
            switch compl {
            case .finished:
                continuation?.resume(returning: nil)
            case .failure(let err):
                continuation?.resume(throwing: err)
            }
        }
        
        private func receive(input: Element) async {
            let continuation = await iActor.getAndClearMainCompletion()
            assert(continuation != nil)
            continuation?.resume(returning: input)
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension PublisherAsyncSequence.Iterator : AsyncIteratorProtocol {
    public func next() async throws -> Element? {
        try await iActor.next()
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension PublisherAsyncSequence.Iterator : Subscriber {
    public func receive(_ input: Element) -> Subscribers.Demand {
        Task {
            await receive(input: input)
        }
        return .none
    }
    
    public func receive(subscription: Subscription) {
        Task {
            let continuation = await self.iActor.setSubscription(subscription: subscription)
            continuation?.resume()
        }
    }
    
    public func receive(completion: Subscribers.Completion<Error>) {
        Task {
            await receive(compl: completion)
        }
    }
}
