import SwiftUI
import ComposableArchitecture

struct KeyboardList: Reducer {
  struct State: Equatable {
    let manufacturer: DatabaseClient.Manufacturer
    var keyboards = IdentifiedArrayOf<DatabaseClient.Keyboard>()
    @PresentationState var details: KeyboardDetails.State?
  }
  
  enum Action: Equatable {
    case task
    case setKeyboards([DatabaseClient.Keyboard])
    case setSelection(DatabaseClient.Keyboard.ID?)
    case details(PresentationAction<KeyboardDetails.Action>)
  }
  
  @Dependency(\.database) var database
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      case .task:
        return .run { [manufacturerID = state.manufacturer.id] send in
          for await value in await self.database.keyboards(manufacturerID) {
            await send(.setKeyboards(value))
          }
        }
        
      case let .setKeyboards(value):
        state.keyboards = .init(uniqueElements: value)
        return .none
        
      case let .setSelection(value):
        state.details = value.flatMap({ state.keyboards[id: $0] }).flatMap(KeyboardDetails.State.init(keyboard:))
        return .none
        
      case .details:
        return .none
        
      }
    }
    .ifLet(\.$details, action: /Action.details, destination: KeyboardDetails.init)
  }
}

private extension KeyboardList.State {
  var selection: DatabaseClient.Keyboard.ID? {
    details?.keyboard.id
  }
  var favorites: IdentifiedArrayOf<DatabaseClient.Keyboard> {
    keyboards.filter(\.isFavorite)
  }
  var nonFavorites: IdentifiedArrayOf<DatabaseClient.Keyboard> {
    keyboards.filter { !$0.isFavorite }
  }
}

// MARK: - SwiftUI

struct KeyboardsListView: View {
  let store: StoreOf<KeyboardList>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      List(selection: viewStore.binding(get: \.selection, send: { .setSelection($0) } )) {
        if !viewStore.favorites.isEmpty {
          Section("Favorites") {
            ForEach(viewStore.favorites) { keyboard in
              NavigationLink(value: keyboard) {
                Text(keyboard.name)
              }
              .tag(keyboard.id)
            }
          }
        }
        if !viewStore.nonFavorites.isEmpty {
          Section("Keyboards") {
            ForEach(viewStore.nonFavorites) { keyboard in
              NavigationLink(value: keyboard.id) {
                Text(keyboard.name)
              }
            }
          }
        }
      }
      .navigationTitle(viewStore.manufacturer.name)
      .task { await viewStore.send(.task).finish() }
      .animation(.default, value: viewStore.keyboards)
    }
  }
}

struct KeyboardsListDetailView: View {
  let store: StoreOf<KeyboardList>
  
  var body: some View {
    IfLetStore(
      store.scope(state: \.$details, action: KeyboardList.Action.details),
      then: KeyboardDetailsView.init(store:)
    )
  }
}

// MARK: - SwiftUI Previews

struct AppleKeyboardsListView_Previews: PreviewProvider {
  static let store = Store(
    initialState: KeyboardList.State(manufacturer: .apple),
    reducer: KeyboardList.init
  )
  static var previews: some View {
    NavigationSplitView {
      EmptyView()
    } content: {
      KeyboardsListView(store: Self.store)
    } detail: {
      KeyboardsListDetailView(store: Self.store)
    }
    .previewInterfaceOrientation(.landscapeLeft)
  }
}
