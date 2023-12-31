import Foundation
import Dependencies
import Tagged
import IdentifiedCollections

struct DatabaseClient: DependencyKey {
  var keyboards: @Sendable (_ with: Manufacturer.ID) async -> AsyncStream<[Keyboard]>
  var updateKeyboard: @Sendable (Keyboard) async throws -> Void
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

// MARK: - Models

extension DatabaseClient {
  struct Manufacturer: Identifiable, Equatable, Hashable, Codable {
    let id: ID
    let name: String
    typealias ID = Tagged<Self, UUID>
    
    static let apple = Self(id: .init(), name: "Apple")
    static let ibm = Self(id: .init(), name: "IBM")
    static let dell = Self(id: .init(), name: "Dell")
    static var defaults: [Self] = [.apple, .ibm, .dell]
  }
  
  struct Keyboard: Identifiable, Equatable, Hashable, Codable {
    let id: ID
    let manufacturerID: Manufacturer.ID
    let name: String
    let description: String
    let imageURL: URL
    var isFavorite = false
    typealias ID = Tagged<Self, UUID>
    
    static let defaults: [Self] = [
      // Apple
      Self(
        id: .init(),
        manufacturerID: DatabaseClient.Manufacturer.apple.id,
        name: "Apple Numeric Keypad IIe (A2M2003)",
        description: "The Numeric Keypad IIe was Apple's first external keypad. Released as an option specifically for the popular Apple IIe computer in 1983, it helped correct some of the II series' shortcomings. Later, the Platinum IIe would incorporate the numeric keypad into its built-in keyboard.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Apple_Numeric_Keypad_IIe.jpg/440px-Apple_Numeric_Keypad_IIe.jpg")!
      ),
      Self(
        id: .init(),
        manufacturerID: DatabaseClient.Manufacturer.apple.id,
        name: "Lisa Keyboard (A6MB101)",
        description: "The first keyboard not to be integrated into the case like the Apple II and III series before it. It was designed for and came with the Apple Lisa. Like the Apple III before it, it was intended to be a business computer and included an integrated numeric keypad. Like all Apple computers before it, it came in a beige case to match the Lisa and connected by a unique TRS connector. In addition it carried over the use of the \"open\" Apple key from the Apple III as a command key (though it was represented by the \"closed\" Apple character) and included a pullout reference guide hidden under the keyboard.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/Apple_A6MB101_keyboard_top.jpg/440px-Apple_A6MB101_keyboard_top.jpg")!
      ),
      Self(
        id: .init(),
        manufacturerID: DatabaseClient.Manufacturer.apple.id,
        name: "Macintosh Keyboard (M0110)",
        description: "Introduced and included with the original Macintosh in 1984, it debuted with neither arrow keys to control the cursor nor an integrated numeric keypad. It used a telephone cord-style RJ-11 connector to the case (also used with the Amstrad PCW series of computers). The keyboard pinouts are \"crossed\" so it isn't possible to use a standard telephone cord as a replacement; doing so will result in damage to the keyboard or the computer. The keyboard also introduced a unique command key similar to the \"open\" Apple Key on the Lisa.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/7/76/Apple_Macintosh_Plus_Keyboard.jpg/440px-Apple_Macintosh_Plus_Keyboard.jpg")!
      ),
      // IBM
      Self(
        id: .init(),
        manufacturerID: DatabaseClient.Manufacturer.ibm.id,
        name: "Model M",
        description: "The Model M keyboard was designed to be less expensive to produce than the Model F keyboard it replaced. Principal design work was done at IBM in 1983–1984, drawing on a wide range of user feedback, ergonomic studies, and examination of competing products. Its key layout, significantly different from the Model F's, owed much (including notably the inverted-T arrangement of its arrow keys) to the LK-201 keyboard shipped with the VT220 serial terminal.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/4/48/IBM_Model_M.png")!
      ),
      Self(
        id: .init(),
        manufacturerID: DatabaseClient.Manufacturer.ibm.id,
        name: "Model F",
        description: "The Model F was a series of computer keyboards produced mainly from 1981–1985 and in reduced volume until 1994 by IBM and later Lexmark. Its mechanical-key design consisted of a buckling spring over a capacitive PCB, similar to the later Model M keyboard that used a membrane in place of the PCB.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/5/56/IBM_Model_F_XT.png/280px-IBM_Model_F_XT.png")!
      ),
      // Dell
      Self(
        id: .init(),
        manufacturerID: DatabaseClient.Manufacturer.dell.id,
        name: "Dell AT101",
        description: "The Dell AT101 series was introduced as an Alps Bigfoot keyboard, with Alps SKCM Salmon switches and thick dye-sublimated keycaps with dark blue legends. Around 1992, production transferred to Silitek. With this came thin keycaps and a move to Alps SKCM Black switches. The keycap printing method is not confirmed. Evidence indicates that salmon Alps was still made and sold at this point in time, so the change of switch is not understood. Alps Bigfoot keyboards were also still being made; it remains a mystery how and why production of an extant Alps design was moved to Silitek, and whether this was done with or without Alps's participation and agreement. Silitek also introduced a rubber dome version of the keyboard.The Windows key versions introduced laser-etched legends. These were produced until at least 2001.",
        imageURL: URL(string: "https://deskthority.net/wiki/images/thumb/3/33/Dell_AT102W_UK_2000.jpg/500px-Dell_AT102W_UK_2000.jpg")!
      ),
    ]
  }
}
