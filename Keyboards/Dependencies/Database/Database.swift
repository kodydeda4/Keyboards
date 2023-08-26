import Foundation
import Dependencies
import Tagged
import IdentifiedCollections

struct Database: DependencyKey {
  var keyboards: @Sendable (_ with: Manufacturer.ID) async -> AsyncStream<[Keyboard]>
  var updateKeyboard: @Sendable (Keyboard) async throws -> Void
}

extension DependencyValues {
  var database: Database {
    get { self[Database.self] }
    set { self[Database.self] = newValue }
  }
}

extension Database {
  static var liveValue: Self {
    final actor ActorState {
      @Published var keyboards = IdentifiedArrayOf(uniqueElements: Keyboard.defaults)
      
      func update(keyboard: Keyboard) {
        self.keyboards[id: keyboard.id] = keyboard
      }
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
      },
      updateKeyboard: { await actor.update(keyboard: $0) }
    )
  }
}

