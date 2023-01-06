import ComposableArchitecture
@preconcurrency import SwiftUI

enum Filter: LocalizedStringKey, CaseIterable, Hashable {
  case all = "All"
  case active = "Active"
  case completed = "Completed"
}

struct Todos: ReducerProtocol {
  struct State: Equatable {
    @BindingState var editMode: EditMode = .inactive
    @BindingState var filter: Filter = .all
    var todos: IdentifiedArrayOf<Todo.State> = []

    var filteredTodos: IdentifiedArrayOf<Todo.State> {
      switch filter {
      case .active: return self.todos.filter { !$0.isComplete }
      case .all: return self.todos
      case .completed: return self.todos.filter(\.isComplete)
      }
    }
  }

  enum Action: Equatable, Sendable {
    case sortCompletedTodos
    case todo(id: Todo.State.ID, action: Todo.Action)
    case view(ViewAction)
  }

  enum ViewAction: BindableAction, Equatable, Sendable {
    case addTodoButtonTapped
    case binding(BindingAction<State>)
    case clearCompletedButtonTapped
    case delete(IndexSet)
    case move(IndexSet, Int)
  }

  @Dependency(\.continuousClock) var clock
  @Dependency(\.uuid) var uuid
  private enum TodoCompletionID {}

  var body: some ReducerProtocol<State, Action> {
    BindingReducer(action: /Action.view)
    Reduce { state, action in
      switch action {
      case .view(.addTodoButtonTapped):
        state.todos.insert(Todo.State(id: self.uuid()), at: 0)
        return .none

      case .view(.binding):
        return .none

      case .view(.clearCompletedButtonTapped):
        state.todos.removeAll(where: \.isComplete)
        return .none

      case let .view(.delete(indexSet)):
        let filteredTodos = state.filteredTodos
        for index in indexSet {
          state.todos.remove(id: filteredTodos[index].id)
        }
        return .none

      case var .view(.move(source, destination)):
        if state.filter == .completed {
          source = IndexSet(
            source
              .map { state.filteredTodos[$0] }
              .compactMap { state.todos.index(id: $0.id) }
          )
          destination =
            (destination < state.filteredTodos.endIndex
              ? state.todos.index(id: state.filteredTodos[destination].id)
              : state.todos.endIndex)
            ?? destination
        }

        state.todos.move(fromOffsets: source, toOffset: destination)

        return .task {
          try await self.clock.sleep(for: .milliseconds(100))
          return .sortCompletedTodos
        }

      case .sortCompletedTodos:
        state.todos.sort { $1.isComplete && !$0.isComplete }
        return .none

      case .todo(id: _, action: .binding(\.$isComplete)):
        return .run { send in
          try await self.clock.sleep(for: .seconds(1))
          await send(.sortCompletedTodos, animation: .default)
        }
        .cancellable(id: TodoCompletionID.self, cancelInFlight: true)

      case .todo:
        return .none
      }
    }
    .forEach(\.todos, action: /Action.todo(id:action:)) {
      Todo()
    }
  }
}

struct AppView: View {
  let store: StoreOf<Todos>

  // TODO: Add `ViewStore.init(_,observe:send:removeDuplicates:)`
//  @ObservedObject var viewStore: ViewStore<ViewState, Todos.Action>
//
//  init(store: StoreOf<Todos>) {
//    self.store = store
//    self.viewStore = ViewStore(self.store.scope(state: ViewState.init(state:)))
//  }

  struct ViewState: Equatable {
    @BindingViewState var editMode: EditMode
    @BindingViewState var filter: Filter
    let isClearCompletedButtonDisabled: Bool

    init(store: BindingViewStore<Todos.State>) {
      self._editMode = store.$editMode
      self._filter = store.$filter
      self.isClearCompletedButtonDisabled = !store.todos.contains(where: \.isComplete)
    }
  }

  var body: some View {
    WithViewStore(self.store, observe: ViewState.init, send: Todos.Action.view) { viewStore in
      NavigationView {
        VStack(alignment: .leading) {
          Picker("Filter", selection: viewStore.$filter.animation()) {
            ForEach(Filter.allCases, id: \.self) { filter in
              Text(filter.rawValue).tag(filter)
            }
          }
          .pickerStyle(.segmented)
          .padding(.horizontal)

          List {
            ForEachStore(
              self.store.scope(state: \.filteredTodos, action: Todos.Action.todo(id:action:))
            ) {
              TodoView(store: $0)
            }
            .onDelete { viewStore.send(.delete($0)) }
            .onMove { viewStore.send(.move($0, $1)) }
          }
        }
        .navigationTitle("Todos")
        .navigationBarItems(
          trailing: HStack(spacing: 20) {
            EditButton()
            Button("Clear Completed") {
              viewStore.send(.clearCompletedButtonTapped, animation: .default)
            }
            .disabled(viewStore.isClearCompletedButtonDisabled)
            Button("Add Todo") { viewStore.send(.addTodoButtonTapped, animation: .default) }
          }
        )
        .environment(\.editMode, viewStore.$editMode)
      }
      .navigationViewStyle(.stack)
    }
  }
}

extension IdentifiedArray where ID == Todo.State.ID, Element == Todo.State {
  static let mock: Self = [
    Todo.State(
      description: "Check Mail",
      id: UUID(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-BEEDDEADBEEF")!,
      isComplete: false
    ),
    Todo.State(
      description: "Buy Milk",
      id: UUID(uuidString: "CAFEBEEF-CAFE-BEEF-CAFE-BEEFCAFEBEEF")!,
      isComplete: false
    ),
    Todo.State(
      description: "Call Mom",
      id: UUID(uuidString: "D00DCAFE-D00D-CAFE-D00D-CAFED00DCAFE")!,
      isComplete: true
    ),
  ]
}

struct AppView_Previews: PreviewProvider {
  static var previews: some View {
    AppView(
      store: Store(
        initialState: Todos.State(todos: .mock),
        reducer: Todos()
      )
    )
  }
}
