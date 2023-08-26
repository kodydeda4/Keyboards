import SwiftUI
import ComposableArchitecture

struct AppReducer: Reducer {
  struct State: Equatable {
    var apple = KeyboardList.State(manufacturer: .apple)
    var ibm = KeyboardList.State(manufacturer: .ibm)
    var dell = KeyboardList.State(manufacturer: .dell)
    @BindingState var navigationSplitViewVisibility = NavigationSplitViewVisibility.all
    @BindingState var destinationTag: DestinationTag? = .apple
  }
  
  enum Action: BindableAction, Equatable {
    case apple(KeyboardList.Action)
    case ibm(KeyboardList.Action)
    case dell(KeyboardList.Action)
    case binding(BindingAction<State>)
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Scope(state: \.apple, action: /Action.apple, child: KeyboardList.init)
    Scope(state: \.ibm, action: /Action.ibm, child: KeyboardList.init)
    Scope(state: \.dell, action: /Action.dell, child: KeyboardList.init)
  }
}

extension AppReducer.State {
  enum DestinationTag: String, Equatable, CaseIterable {
    case apple = "Apple"
    case ibm = "IBM"
    case dell = "Dell"
  }
}

// MARK: - SwiftUI

struct AppView: View {
  let store: StoreOf<AppReducer>
  
  var body: some View {
    WithViewStore(store, observe: \.navigationSplitViewVisibility) { viewStore in
      NavigationSplitView(
        columnVisibility: viewStore.binding(get: { $0 }, send: { .binding(.set(\.$navigationSplitViewVisibility, $0)) }),
        sidebar: { sidebar },
        content: { content },
        detail: { detail }
      )
    }
  }
  
  private var sidebar: some View {
    WithViewStore(store, observe: \.destinationTag) { viewStore in
      List(selection: viewStore.binding(get: { $0 }, send: { .binding(.set(\.$destinationTag, $0)) })) {
        ForEach(AppReducer.State.DestinationTag.allCases, id: \.self) { value in
          NavigationLink(value: value) {
            Text(value.rawValue)
          }
        }
      }
      .navigationTitle("Keyboards")
    }
  }
  
  private var content: some View {
    WithViewStore(store, observe: \.destinationTag) { viewStore in
      switch viewStore.state {
      case .apple: KeyboardsListView(store: store.scope(state: \.apple, action: AppReducer.Action.apple))
      case .ibm: KeyboardsListView(store: store.scope(state: \.ibm, action: AppReducer.Action.ibm))
      case .dell: KeyboardsListView(store: store.scope(state: \.dell, action: AppReducer.Action.dell))
      case .none: EmptyView()
      }
    }
  }
  
  private var detail: some View {
    WithViewStore(store, observe: \.destinationTag) { viewStore in
      switch viewStore.state {
      case .apple: KeyboardsListDetailView(store: store.scope(state: \.apple, action: AppReducer.Action.apple))
      case .ibm: KeyboardsListDetailView(store: store.scope(state: \.ibm, action: AppReducer.Action.ibm))
      case .dell: KeyboardsListDetailView(store: store.scope(state: \.dell, action: AppReducer.Action.dell))
      case .none: EmptyView()
      }
    }
  }
}

struct AppView_Previews: PreviewProvider {
  static var previews: some View {
    AppView(store: Store(initialState: AppReducer.State(), reducer: AppReducer.init))
      .previewInterfaceOrientation(.landscapeLeft)
  }
}
