
import Combine

extension Publisher where Self.Failure == Error {
    public var asyncSequence: PublisherAsyncSequence<Self> {
        PublisherAsyncSequence(publisher: self)
    }
}

public struct PublisherAsyncSequence<P> where P : Publisher, P.Failure == Error {

    init(publisher: P) {
        self.pub = publisher
    }
    let pub: P
    public typealias Element = P.Output
    public typealias Failure = P.Failure
}

extension PublisherAsyncSequence {
    public final actor Iterator {
        
        /// These typealiases are just for cleaner call sites
        typealias ElementContinuation = CheckedContinuation<Element?, P.Failure>
        typealias SubsciptionContinuation = CheckedContinuation<Void, Never>
        
        private var subscription: Subscription?
        private var subscriptionContinuation: SubsciptionContinuation?
        private var continuation: ElementContinuation?
        
        public func next() async throws -> Element? {
            if subscription == nil {
                await withCheckedContinuation { (continuation: SubsciptionContinuation) -> Void in
                    guard subscription == nil else {
                        Task.detached { continuation.resume() }
                        return
                    }
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

        private func receive(compl: Subscribers.Completion<Error>) async {
            let continuation = getAndClearMainCompletion()
            assert(continuation != nil)
            switch compl {
            case .finished:
                continuation?.resume(returning: nil)
            case .failure(let err):
                continuation?.resume(throwing: err)
            }
        }
        
        private func receive(input: Element) async {
            let continuation = getAndClearMainCompletion()
            assert(continuation != nil)
            continuation?.resume(returning: input)
        }
    }
}

extension PublisherAsyncSequence : AsyncSequence {
    public func makeAsyncIterator() -> Iterator {
        let itr = Iterator()
        pub.receive(subscriber: itr)
        return itr
    }
}

extension PublisherAsyncSequence.Iterator : AsyncIteratorProtocol {
    public typealias Element = P.Output
}

extension PublisherAsyncSequence.Iterator : Subscriber {
    
    public typealias Input = P.Output
    public typealias Failure = P.Failure
    
    public nonisolated func receive(_ input: Element) -> Subscribers.Demand {
        Task {
            await receive(input: input)
        }
        return .none
    }
    
    public nonisolated func receive(subscription: Subscription) {
        Task {
            let continuation = await self.setSubscription(subscription: subscription)
            continuation?.resume()
        }
    }
    
    public nonisolated func receive(completion: Subscribers.Completion<Failure>) {
        Task {
            await receive(compl: completion)
        }
    }
}
