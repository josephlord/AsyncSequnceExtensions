
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
                        Swift.print("Ready for more")
                        guard !Task.isCancelled else { return }
                        Swift.print("Receive and set demand")
                        await self.setDemand(demand: sub.receive(element))
                        Swift.print("mainLoop - loop end")
                    }
                    sub.receive(completion: .finished)
                } catch {
                    Swift.print("MainLoop - catch \(error.localizedDescription)")
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
            Swift.print("Await continuation")
            let _: Void = await withCheckedContinuation { continuation in
                Swift.print("Set continuation")
                demandUpdatedContinuation = continuation
            }
            Swift.print("Continuation completed")
        }
        
        private init() {
            
        }
        
        static func subscription(sequence: AsyncSequenceType, subscriber: S) -> ASPSubscription<S> {
            let subscription = ASPSubscription()
            detach {
                await subscription.mainLoop(seq: sequence, sub: subscriber)
//                if 3.isZero { Swift.print("await mainLoop returned") }
            }
            return subscription
        }
        
//        nonisolated init(sequence: AsyncSequenceType, subscriber: S) {
//            async {
//                await self.mainLoop(seq: sequence, sub: subscriber)
////                if 3.isZero { Swift.print("await mainLoop returned") }
//            }
//            Swift.print("init returned")
//        }
        
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
            Swift.print("demand updated - \(demandUpdatedContinuation == nil ? "No continuation" : "trigger continuation")")
            demandUpdatedContinuation?.resume()
            demandUpdatedContinuation = nil
            Swift.print("continuation has been cleared")
        }
        
        private func setCanceled() async {
            taskHandle?.cancel()
        }
        
        private func setDemand(demand: Subscribers.Demand) async {
            Swift.print("setDemand")
            self.demand += demand
            guard demand > 0 else {
                Swift.print("demand still zero")
                return }
            Swift.print("call demandUpdated")
            demandUpdated()
        }
        
        deinit {
            Swift.print("deinit")
            taskHandle?.cancel()
            // Allow it to continue to cancellation
            demandUpdatedContinuation?.resume()
        }
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, Error == S.Failure, AsyncSequenceType.Element == S.Input {
//        let subscription = ASPSubscription(sequence: sequence, subscriber: subscriber)
        let subscription = ASPSubscription.subscription(sequence: sequence, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension AsyncSequence {
    public var publisher: AsyncSequencePublisher<Self> {
        AsyncSequencePublisher(self)
    }
}
