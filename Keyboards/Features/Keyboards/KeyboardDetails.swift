import SwiftUI
import ComposableArchitecture

struct KeyboardDetails: Reducer {
  struct State: Equatable {
    var keyboard: Database.Keyboard
  }
  
  enum Action: Equatable {
    case toggleIsFavorite
    case updateDatabase(Database.Keyboard)
    case updateDatabaseResponse(TaskResult<Database.Keyboard>)
  }
  
  @Dependency(\.database) var database
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      
      case .toggleIsFavorite:
        var copy = state.keyboard
        copy.isFavorite.toggle()
        return .send(.updateDatabase(copy))
        
      case let .updateDatabase(value):
        return .run { send in
          await send(.updateDatabaseResponse(TaskResult {
            try await database.updateKeyboard(value)
            return value
          }))
        }
        
      case let .updateDatabaseResponse(.success(value)):
        state.keyboard = value
        return .none
        
      case .updateDatabaseResponse(.failure):
        return .none
      }
    }
  }
}

// MARK: - SwiftUI

struct KeyboardDetailsView: View {
  let store: StoreOf<KeyboardDetails>
  
  var body: some View {
    WithViewStore(store, observe: \.keyboard) { viewStore in
      List {
        Section {
          AsyncImage(url: viewStore.state.imageURL) { image in
            image
              .resizable()
              .scaledToFill()
              .background { Color.primary }
          } placeholder: {
            ProgressView()
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .background { Color.primary }
          }
          .frame(width: 200, height: 200)
          .frame(maxWidth: .infinity)
          .background { Color.black }
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .listRowSeparator(.hidden)
        
        Section(header: Text("About")) {
          Text(viewStore.state.description)
        }
        .textCase(nil)
      }
      .navigationTitle(viewStore.state.name)
      .listStyle(.plain)
      .toolbar {
        Button {
          viewStore.send(.toggleIsFavorite)
        } label: {
          Image(systemName: !viewStore.isFavorite ? "heart" : "heart.fill")
            .foregroundColor(.pink)
        }
      }
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
    NavigationSplitView(columnVisibility: .constant(.all)) {
      EmptyView()
    } content: {
      EmptyView()
    } detail: {
      KeyboardDetailsView(store: Self.store)
    }
    .previewInterfaceOrientation(.landscapeLeft)
  }
}
