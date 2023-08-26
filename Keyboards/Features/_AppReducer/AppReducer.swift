import SwiftUI
import ComposableArchitecture

struct AppReducer: Reducer {
  struct State: Equatable {
    var apple = KeyboardList.State(manufacturer: .apple)
    var ibm = KeyboardList.State(manufacturer: .ibm)
    var dell = KeyboardList.State(manufacturer: .dell)
    @BindingState var navigationSplitViewVisibility = NavigationSplitViewVisibility.all
    @BindingState var destinationTag: DestinationTag? = .apple
    @PresentationState var destination: Destination.State?
  }
  
  enum Action: BindableAction, Equatable {
    case navigateToAppInfo
    case apple(KeyboardList.Action)
    case ibm(KeyboardList.Action)
    case dell(KeyboardList.Action)
    case binding(BindingAction<State>)
    case destination(PresentationAction<Destination.Action>)
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Scope(state: \.apple, action: /Action.apple) {
      KeyboardList()
    }
    Scope(state: \.ibm, action: /Action.ibm) {
      KeyboardList()
    }
    Scope(state: \.dell, action: /Action.dell) {
      KeyboardList()
    }
    Reduce { state, action in
      switch action {
        
      case .navigateToAppInfo:
        state.destination = .appInfo()
        return .none
        
      default:
        return .none
        
      }
    }
    .ifLet(\.$destination, action: /Action.destination) {
      Destination()
    }
  }
  
  struct Destination: Reducer {
    enum State: Equatable {
      case appInfo(AppInfo.State = .init())
    }
    enum Action: Equatable {
      case appInfo(AppInfo.Action)
    }
    var body: some ReducerOf<Self> {
      Scope(state: /State.appInfo, action: /Action.appInfo) {
        AppInfo()
      }
    }
  }
}

extension AppReducer.State {
  enum DestinationTag: String, Identifiable, Equatable, CustomStringConvertible, CaseIterable {
    var id: Self { self }
    var description: String { rawValue }
    
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
        columnVisibility: viewStore.binding(
          get: { $0 },
          send: { .binding(.set(\.$navigationSplitViewVisibility, $0)) }
        ),
        sidebar: { sidebar },
        content: { content },
        detail: { detail }
      )
    }
  }
  
  private var sidebar: some View {
    WithViewStore(store, observe: \.destinationTag) { viewStore in
      List(selection: viewStore.binding(
        get: { $0 },
        send: { .binding(.set(\.$destinationTag, $0)) }
      )) {
        ForEach(AppReducer.State.DestinationTag.allCases) { value in
          NavigationLink(value: value.id) {
            Text(value.description)
          }
        }
      }
      .navigationTitle("Keyboards")
      .sheet(
        store: store.scope(state: \.$destination, action: AppReducer.Action.destination),
        state: /AppReducer.Destination.State.appInfo,
        action: AppReducer.Destination.Action.appInfo,
        content: AppInfoSheet.init(store:)
      )
      .toolbar {
        Button(action: { viewStore.send(.navigateToAppInfo) }) {
          Image(systemName: "info.circle")
        }
      }
    }
  }
  
  private var content: some View {
    WithViewStore(store, observe: \.destinationTag) { viewStore in
      switch viewStore.state {
      case .apple:
        KeyboardsListView(store: store.scope(
          state: \.apple,
          action: AppReducer.Action.apple
        ))
      case .ibm:
        KeyboardsListView(store: store.scope(
          state: \.ibm,
          action: AppReducer.Action.ibm
        ))
      case .dell:
        KeyboardsListView(store: store.scope(
          state: \.dell,
          action: AppReducer.Action.dell
        ))
      case .none:
        EmptyView()
      }
    }
  }
  
  private var detail: some View {
    WithViewStore(store, observe: \.destinationTag) { viewStore in
      switch viewStore.state {
      case .apple:
        KeyboardsListDetailView(store: store.scope(
          state: \.apple,
          action: AppReducer.Action.apple
        ))
      case .ibm:
        KeyboardsListDetailView(store: store.scope(
          state: \.ibm,
          action: AppReducer.Action.ibm
        ))
      case .dell:
        KeyboardsListDetailView(store: store.scope(
          state: \.dell,
          action: AppReducer.Action.dell
        ))
      case .none:
        EmptyView()
      }
    }
  }
}

struct AppView_Previews: PreviewProvider {
  static let store = Store(
    initialState: AppReducer.State(),
    reducer: AppReducer.init
  )
  static var previews: some View {
    AppView(store: Self.store)
      .previewInterfaceOrientation(.landscapeLeft)
  }
}
