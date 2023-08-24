import Foundation
import IdentifiedCollections

extension Database {
  static var live: Self {
    final actor ActorState {
      @Published var keyboards = IdentifiedArrayOf(uniqueElements: Keyboard.defaults)
    }
    
    let actor = ActorState()
    
    return Self(
      keyboards: { manufacturerID in
        AsyncStream { continuation in
          let task = Task {
            while !Task.isCancelled {
              for await value in await actor.$keyboards.values {
                continuation.yield(value.elements.filter({ $0.manufacturerID == manufacturerID }))
              }
            }
          }
          continuation.onTermination = { _ in task.cancel() }
        }
      }
    )
  }
}

