import Foundation
import Tagged

extension Database {
  struct Manufacturer: Identifiable, Equatable, Hashable, Codable {
    let id: ID
    let name: String
    typealias ID = Tagged<Self, UUID>
  }
  
  struct Keyboard: Identifiable, Equatable, Hashable, Codable {
    let id: ID
    let manufacturerID: Manufacturer.ID
    let name: String
    let description: String
    let imageURL: URL
    typealias ID = Tagged<Self, UUID>
  }
}

extension Database.Manufacturer {
  static let apple = Self(id: .init(), name: "Apple")
  static let ibm = Self(id: .init(), name: "IBM")
  static let dell = Self(id: .init(), name: "Dell")
  static var defaults: [Self] = [.apple, .ibm, .dell]
}

extension Database.Keyboard {
  
//  static let ibmModelM = Self(id: .init(), manufacturerID: DatabaseClient.Manufacturer.ibm.id, name: "Model M")
//  static let dellFoo = Self(id: .init(), manufacturerID: DatabaseClient.Manufacturer.dell.id, name: "Dell Foo")
  
  static let apple: [Self] = [
    Self(
      id: .init(),
      manufacturerID: Database.Manufacturer.apple.id,
      name: "Apple Numeric Keypad IIe (A2M2003)",
      description: "The Numeric Keypad IIe was Apple's first external keypad. Released as an option specifically for the popular Apple IIe computer in 1983, it helped correct some of the II series' shortcomings. Later, the Platinum IIe would incorporate the numeric keypad into its built-in keyboard.",
      imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Apple_Numeric_Keypad_IIe.jpg/440px-Apple_Numeric_Keypad_IIe.jpg")!
    ),
    Self(
      id: .init(),
      manufacturerID: Database.Manufacturer.apple.id,
      name: "Lisa Keyboard (A6MB101)",
      description: "The first keyboard not to be integrated into the case like the Apple II and III series before it. It was designed for and came with the Apple Lisa. Like the Apple III before it, it was intended to be a business computer and included an integrated numeric keypad. Like all Apple computers before it, it came in a beige case to match the Lisa and connected by a unique TRS connector. In addition it carried over the use of the \"open\" Apple key from the Apple III as a command key (though it was represented by the \"closed\" Apple character) and included a pullout reference guide hidden under the keyboard.",
      imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/Apple_A6MB101_keyboard_top.jpg/440px-Apple_A6MB101_keyboard_top.jpg")!
    ),
    Self(
      id: .init(),
      manufacturerID: Database.Manufacturer.apple.id,
      name: "Macintosh Keyboard (M0110)",
      description: "Introduced and included with the original Macintosh in 1984, it debuted with neither arrow keys to control the cursor nor an integrated numeric keypad. It used a telephone cord-style RJ-11 connector to the case (also used with the Amstrad PCW series of computers). The keyboard pinouts are \"crossed\" so it isn't possible to use a standard telephone cord as a replacement; doing so will result in damage to the keyboard or the computer.[12] The keyboard also introduced a unique command key similar to the \"open\" Apple Key on the Lisa.",
      imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/7/76/Apple_Macintosh_Plus_Keyboard.jpg/440px-Apple_Macintosh_Plus_Keyboard.jpg")!
    )
  ]
  
  static let defaults: [Self] = [apple].flatMap({ $0 })
}
