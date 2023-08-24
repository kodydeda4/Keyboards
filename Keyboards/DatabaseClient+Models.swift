import Foundation
import Tagged

extension DatabaseClient {
  struct Manufacturer: Identifiable, Equatable, Hashable, Codable {
    let id: ID
    let name: String
    typealias ID = Tagged<Self, UUID>
  }
  
  struct Keyboard: Identifiable, Equatable, Hashable, Codable {
    let id: ID
    let manufacturerID: Manufacturer.ID
    let name: String
    typealias ID = Tagged<Self, UUID>
  }
}

extension DatabaseClient.Manufacturer {
  static let apple = Self(id: .init(), name: "Apple")
  static let ibm = Self(id: .init(), name: "IBM")
  static let dell = Self(id: .init(), name: "Dell")
  static var defaults: [Self] = [.apple, .ibm, .dell]
}

extension DatabaseClient.Keyboard {
  static let appleII = Self(id: .init(), manufacturerID: DatabaseClient.Manufacturer.apple.id, name: "Apple II")
  static let ibmModelM = Self(id: .init(), manufacturerID: DatabaseClient.Manufacturer.ibm.id, name: "Model M")
  static let dellFoo = Self(id: .init(), manufacturerID: DatabaseClient.Manufacturer.dell.id, name: "Dell Foo")
  
  static var defaults: [Self] = [.appleII, .ibmModelM, .dellFoo]
}
