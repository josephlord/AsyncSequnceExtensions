
import Combine
import _Concurrency

@available(macOS 12.0, iOS 15.0, *)
struct PublisherAsyncSequence<Element> : AsyncSequence {

    let publisher: AnyPublisher<Element, Error>

    func makeAsyncIterator() -> Iterator {
        let itr = Iterator()
        publisher.receive(subscriber: itr)
        return itr
    }

    actor Iterator : AsyncIteratorProtocol, Subscriber {
        typealias Input = Element
        typealias Failure = Error
        
        private var subscription: Subscription?

        private var continuation: CheckedContinuation<Element?, Error>?

        func next() async throws -> Element? {
            try await withCheckedThrowingContinuation({ continuation in
                self.continuation = continuation
                subscription?.request(.max(1))
            })
        }

        nonisolated func receive(subscription: Subscription) {
            Task {
                await self.receive(sub: subscription)
            }
        }
        
        private func receive(sub: Subscription) async {
            self.subscription = sub
        }
        
        nonisolated func receive(completion: Subscribers.Completion<Error>) {
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
        
        nonisolated func receive(_ input: Element) -> Subscribers.Demand {
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
    var asyncSequence: PublisherAsyncSequence<Output> {
        PublisherAsyncSequence(publisher: self.eraseToAnyPublisher())
    }
}

