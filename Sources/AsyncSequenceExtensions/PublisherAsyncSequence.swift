
import Combine
import _Concurrency

@available(macOS 12.0, iOS 15.0, *)
public struct PublisherAsyncSequence<Element> : AsyncSequence {

    let publisher: AnyPublisher<Element, Error>

    public func makeAsyncIterator() -> Iterator {
        let itr = Iterator()
        publisher.receive(subscriber: itr)
        return itr
    }

    public class Iterator : AsyncIteratorProtocol, Subscriber {
        public typealias Input = Element
        public typealias Failure = Error
        
        private let iActor = InnerActor()
        
        private actor InnerActor {
            private var subscription: Subscription?
            private var subscriptionContinuation: SubsciptionContinuation?
            private var continuation: EContinuation?
            
            typealias EContinuation = CheckedContinuation<Element?, Error>
            typealias SubsciptionContinuation = CheckedContinuation<Void, Never>
            
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
            func getAndClearMainCompletion() -> EContinuation? {
                defer { continuation = nil }
                return continuation
            }
            
            /// You should resume the completion immediately after calling this
            func getAndClearSubscriptionCompletion() -> SubsciptionContinuation? {
                defer { subscriptionContinuation = nil }
                return subscriptionContinuation
            }
        }

        public func next() async throws -> Element? {
            try await iActor.next()
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
        
        public func receive(_ input: Element) -> Subscribers.Demand {
            Task {
                await receive(input: input)
            }
            return .none
        }
        
        private func receive(input: Element) async {
            let continuation = await iActor.getAndClearMainCompletion()
            assert(continuation != nil)
            continuation?.resume(returning: input)
        }
    }

}


@available(macOS 12.0, iOS 15.0, *)
extension Publisher where Self.Failure == Error {
    public var asyncSequence: PublisherAsyncSequence<Output> {
        PublisherAsyncSequence(publisher: self.eraseToAnyPublisher())
    }
}

