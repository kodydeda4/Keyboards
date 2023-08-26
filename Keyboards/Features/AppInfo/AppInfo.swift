import SwiftUI
import ComposableArchitecture

struct AppInfo: Reducer {
  struct State: Equatable {
    //...
  }
  
  enum Action: Equatable {
    case cancelButtonTapped
  }
  
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      case .cancelButtonTapped:
        return .run { _ in await self.dismiss() }
        
      }
    }
  }
}

// MARK: - SwiftUI

struct AppInfoSheet: View {
  let store: StoreOf<AppInfo>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        List {
          Section {
            EmptyView()
          } header: {
            Text("This demo shows how TCA can be used with NavigationSplitView layouts.")
          }
          .textCase(nil)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              viewStore.send(.cancelButtonTapped)
            }
          }
        }
      }
    }
  }
}

// MARK: - SwiftUI Previews

struct AppInfoSheet_Previews: PreviewProvider {
  static let store = Store(
    initialState: AppInfo.State(),
    reducer: AppInfo.init
  )
  static var previews: some View {
    Text("Hello World").sheet(isPresented: .constant(true)) {
      AppInfoSheet(store: Self.store)
    }
  }
}

