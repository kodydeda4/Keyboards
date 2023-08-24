import Foundation
import Dependencies
import Tagged
import IdentifiedCollections

struct DatabaseClient: DependencyKey {
  var keyboards: @Sendable (_ with: Manufacturer.ID) async -> AsyncStream<[Keyboard]>
}

extension DependencyValues {
  var database: DatabaseClient {
    get { self[DatabaseClient.self] }
    set { self[DatabaseClient.self] = newValue }
  }
}

extension DatabaseClient {
  static var liveValue: Self {
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

