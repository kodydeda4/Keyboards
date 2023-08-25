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
  static var liveValue = Self.live
  //static var previewValue = Self.preview
  //static var testValue = Self.test
}
