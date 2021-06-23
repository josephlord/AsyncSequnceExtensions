
import Combine
import Foundation

@available(iOS 15.0, macOS 12.0, *)
public struct MinimisedDeadlockExample<AsyncSequenceType> : Publisher where AsyncSequenceType : AsyncSequence {
    public typealias Output = AsyncSequenceType.Element
    public typealias Failure = Error
    
    let sequence: AsyncSequenceType
    
    public init(_ sequence: AsyncSequenceType) {
        self.sequence = sequence
    }
    
    fileprivate actor ASPSubscription<S> : Subscription
    where S : Subscriber, S.Failure == Error, S.Input == AsyncSequenceType.Element {
        
        var taskHandle: Task.Handle<(), Never>?
        
        private func mainLoop(seq: AsyncSequenceType, sub: S) {
            Swift.print("MainLoop")
            taskHandle = detach {
                do {
                    Swift.print("Loop")
                    for try await element in seq {
                        Swift.print("element: \(element)")
                        Swift.print("Ready for more")
                        let addedDemand = sub.receive(element)
                        await self.setDemand(demand: addedDemand)
                        Swift.print("mainLoop - loop end")
                    }
                    Swift.print("mainLoop - loop completion")
                    sub.receive(completion: .finished)
                } catch {
                    Swift.print("MainLoop - catch \(error.localizedDescription)")
                    if error is Task.CancellationError { return }
                    sub.receive(completion: .failure(error))
                }
            }
            Swift.print("taskHandle set")
        }
        
        
        private init() {
            
        }
        
        static func subscription(sequence: AsyncSequenceType, subscriber: S) -> ASPSubscription<S> {
            let subscription = ASPSubscription()
            async {
                await subscription.mainLoop(seq: sequence, sub: subscriber)
//                if 3.isZero { Swift.print("await mainLoop returned") }
            }
            return subscription
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

        }
        
        private func setDemand(demand: Subscribers.Demand) async {
            Swift.print("setDemand")
//            self.demand += demand
//            guard demand > 0 else {
//                Swift.print("demand still zero")
//                return }
//            Swift.print("Has demand")
            
        }
        
        deinit {
            Swift.print("deinit")
        }
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, Error == S.Failure, AsyncSequenceType.Element == S.Input {
        let subscription = ASPSubscription.subscription(sequence: sequence, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension AsyncSequence {
    public var deadlockPublisher: MinimisedDeadlockExample<Self> {
        MinimisedDeadlockExample(self)
    }
}
