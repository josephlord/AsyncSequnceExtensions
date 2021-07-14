
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

    public actor Iterator : AsyncIteratorProtocol, Subscriber {
        public typealias Input = Element
        public typealias Failure = Error
        
        private var subscription: Subscription?

        private var continuation: CheckedContinuation<Element?, Error>?

        public func next() async throws -> Element? {
            try await withCheckedThrowingContinuation({ continuation in
                self.continuation = continuation
                subscription?.request(.max(1))
            })
        }

        nonisolated public func receive(subscription: Subscription) {
            Task {
                await self.receive(sub: subscription)
            }
        }
        
        private func receive(sub: Subscription) async {
            self.subscription = sub
        }
        
        nonisolated public func receive(completion: Subscribers.Completion<Error>) {
            Task {
                await receive(compl: completion)
            }
        }
        private func receive(compl: Subscribers.Completion<Error>) async {
            assert(continuation != nil)
            switch compl {
            case .finished:
                continuation?.resume(returning: nil)
            case .failure(let err):
                continuation?.resume(throwing: err)
            }
            continuation = nil
        }
        
        nonisolated public func receive(_ input: Element) -> Subscribers.Demand {
            Task {
                await receive(input: input)
            }
            return .none
        }
        private func receive(input: Element) {
            assert(continuation != nil)
            continuation?.resume(returning: input)
            continuation = nil
            
        }
    }

}


@available(macOS 12.0, iOS 15.0, *)
extension Publisher where Self.Failure == Error {
    public var asyncSequence: PublisherAsyncSequence<Output> {
        PublisherAsyncSequence(publisher: self.eraseToAnyPublisher())
    }
}

