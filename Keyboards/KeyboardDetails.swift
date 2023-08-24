import SwiftUI
import ComposableArchitecture

struct KeyboardDetails: Reducer {
  struct State: Equatable {
    let keyboard: DatabaseClient.Keyboard
  }
  
  enum Action: Equatable {
    //...
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      }
    }
  }
}

// MARK: - SwiftUI

struct KeyboardDetailsView: View {
  let store: StoreOf<KeyboardDetails>
  
  var body: some View {
    WithViewStore(store, observe: \.keyboard) { viewStore in
      Text(viewStore.state.name)
    }
  }
}

// MARK: - SwiftUI Previews

struct KeyboardDetailsView_Previews: PreviewProvider {
  static let store = Store(
    initialState: KeyboardDetails.State(keyboard: .defaults.first!),
    reducer: KeyboardDetails.init
  )
  static var previews: some View {
    NavigationSplitView {
      EmptyView()
    } content: {
      EmptyView()
    } detail: {
      KeyboardDetailsView(store: Self.store)
    }
    .previewInterfaceOrientation(.landscapeLeft)
  }
}
