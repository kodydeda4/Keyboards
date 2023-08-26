import SwiftUI
import ComposableArchitecture

struct KeyboardList: Reducer {
  struct State: Equatable {
    let manufacturer: Database.Manufacturer
    var keyboards = IdentifiedArrayOf<Database.Keyboard>()
    @BindingState var selection = Set<Database.Keyboard.ID>()
    @PresentationState var details: KeyboardDetails.State?
  }
  
  enum Action: BindableAction, Equatable {
    case task
    case setKeyboards([Database.Keyboard])
    case setSelection(Set<Database.Keyboard.ID>)
    case binding(BindingAction<State>)
    case details(PresentationAction<KeyboardDetails.Action>)
  }
  
  @Dependency(\.database) var database
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        
      case .task:
        return .run { [manufacturerID = state.manufacturer.id] send in
          for await value in await self.database.keyboards(manufacturerID) {
            await send(.setKeyboards(value))
          }
        }
        
      case let .setSelection(value):
        state.selection = value
        if let selection = value.first.flatMap({ state.keyboards[id: $0] }) {
          state.details = .init(keyboard: selection)
          state.selection = Set([selection.id])
        } else {
          state.details = nil
          state.selection = Set()
        }
        return .none
        
      case let .setKeyboards(value):
        state.keyboards = .init(uniqueElements: value)
        return .none
        
      default:
        return .none
        
      }
    }
    .ifLet(\.$details, action: /Action.details) {
      KeyboardDetails()
    }
    ._printChanges()
  }
}

private extension KeyboardList.State {
  var favorites: IdentifiedArrayOf<Database.Keyboard> {
    keyboards.filter(\.isFavorite)
  }
  var nonFavorites: IdentifiedArrayOf<Database.Keyboard> {
    keyboards.filter { !$0.isFavorite }
  }
}

// MARK: - SwiftUI

struct KeyboardsListView: View {
  let store: StoreOf<KeyboardList>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      List(selection: viewStore.binding(
        get: { $0.selection },
        send: { .setSelection($0) }
      )) {
        if !viewStore.favorites.isEmpty {
          Section("Favorites") {
            ForEach(viewStore.favorites) { keyboard in
              NavigationLink(value: keyboard) {
                keyboardView(keyboard: keyboard)
              }
              .tag(keyboard.id)
            }
          }
        }
        if !viewStore.nonFavorites.isEmpty {
          Section("Keyboards") {
            ForEach(viewStore.keyboards.filter({ !$0.isFavorite })) { keyboard in
              NavigationLink(value: keyboard.id) {
                keyboardView(keyboard: keyboard)
              }
            }
          }
        }
      }
      .navigationTitle(viewStore.manufacturer.name)
      .task { await viewStore.send(.task).finish() }
      .animation(.default, value: viewStore.keyboards)
      .toolbar {
        Button("Edit") {
          
        }
      }
    }
  }
  
  private func keyboardView(keyboard: Database.Keyboard) -> some View {
    Text("\(keyboard.name )")
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
