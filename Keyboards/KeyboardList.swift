import SwiftUI
import ComposableArchitecture

struct KeyboardList: Reducer {
  struct State: Equatable {
    let manufacturer: DatabaseClient.Manufacturer
    var keyboards = IdentifiedArrayOf<DatabaseClient.Keyboard>()
    @BindingState var selection = Set<DatabaseClient.Keyboard.ID>()
    @PresentationState var details: KeyboardDetails.State?
  }
  
  enum Action: BindableAction, Equatable {
    case task
    case setKeyboards([DatabaseClient.Keyboard])
    case setSelection(Set<DatabaseClient.Keyboard.ID>)
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
        if let selection = value.first.flatMap({ state.keyboards[id: $0] }) {
          state.details = .init(keyboard: selection)
          state.selection = Set([selection.id])
        } else {
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
        ForEach(viewStore.keyboards) { keyboard in
          NavigationLink(value: keyboard) {
            keyboardView(keyboard: keyboard)
          }
          .tag(keyboard.id)
        }
      }
      .navigationTitle(viewStore.manufacturer.name)
      .task { await viewStore.send(.task).finish() }
    }
  }
  
  private func keyboardView(keyboard: DatabaseClient.Keyboard) -> some View {
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
