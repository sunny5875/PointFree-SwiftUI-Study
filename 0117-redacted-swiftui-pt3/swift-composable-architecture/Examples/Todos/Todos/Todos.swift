import ComposableArchitecture
import SwiftUI

enum Filter: LocalizedStringKey, CaseIterable, Hashable {
  case all = "All"
  case active = "Active"
  case completed = "Completed"
}

struct AppState: Equatable {
  var editMode: EditMode = .inactive
  var filter: Filter = .all
  var todos: IdentifiedArrayOf<Todo> = []

  var filteredTodos: IdentifiedArrayOf<Todo> {
    switch filter {
    case .active: return self.todos.filter { !$0.isComplete }
    case .all: return self.todos
    case .completed: return self.todos.filter { $0.isComplete }
    }
  }
}

enum AppAction: Equatable {
  case addTodoButtonTapped
  case clearCompletedButtonTapped
  case delete(IndexSet)
  case editModeChanged(EditMode)
  case filterPicked(Filter)
  case move(IndexSet, Int)
  case sortCompletedTodos
  case todo(id: UUID, action: TodoAction)
}

struct AppEnvironment {
  var analytics: AnalyticsClient
  var mainQueue: AnySchedulerOf<DispatchQueue>
  var uuid: () -> UUID
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
  Reducer { state, action, environment in
    switch action {
    case .addTodoButtonTapped:
      state.todos.insert(Todo(id: environment.uuid()), at: 0)
      return .none

    case .clearCompletedButtonTapped:
      state.todos.removeAll(where: { $0.isComplete })
      return .none

    case let .delete(indexSet):
      state.todos.remove(atOffsets: indexSet)
      return .none

    case let .editModeChanged(editMode):
      state.editMode = editMode
      return .none

    case let .filterPicked(filter):
      state.filter = filter
      return .none

    case let .move(source, destination):
      state.todos.move(fromOffsets: source, toOffset: destination)
      return Effect(value: .sortCompletedTodos)
        .delay(for: .milliseconds(100), scheduler: environment.mainQueue)
        .eraseToEffect()

    case .sortCompletedTodos:
      state.todos.sortCompleted()
      return .none

    case .todo(id: _, action: .checkBoxToggled):
      struct TodoCompletionId: Hashable {}
      return Effect(value: .sortCompletedTodos)
        .debounce(id: TodoCompletionId(), for: 1, scheduler: environment.mainQueue)

    case .todo:
      return .none
    }
  },
  todoReducer.forEach(
    state: \.todos,
    action: /AppAction.todo(id:action:),
    environment: { _ in TodoEnvironment() }
  )
)

.debugActions(actionFormat: .labelsOnly)

// 4-4. 해당 로직을 구현하는 퍼스널 함수
extension View {
  @ViewBuilder func unredacted(if condition: Bool) -> some View {
    if condition {
      self.unredacted()
    } else {
      self
    }
  }
}

struct AppView: View {
  struct ViewState: Equatable {
    var editMode: EditMode
    var isClearCompletedButtonDisabled: Bool
  }

  let store: Store<AppState, AppAction>
  @Environment(\.onboardingStep) var onboardingStep // 4-3. 넣어준 enviornmnet를 받아서 child view가 영향받도록 변경

  var body: some View {
    WithViewStore(self.store.scope(state: { $0.view })) { viewStore in
      NavigationView {
        VStack(alignment: .leading) {
          WithViewStore(self.store.scope(state: { $0.filter }, action: AppAction.filterPicked)) {
            filterViewStore in
            Picker(
              "Filter", selection: filterViewStore.binding(send: { $0 })
            ) {
              ForEach(Filter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
              }
            }
            .pickerStyle(SegmentedPickerStyle())
            .unredacted(if: self.onboardingStep == .filters) // 4-4. 여기서 온보딩스탭인 것만 unredacted되도록
          }
          .padding([.leading, .trailing])

          List {
            ForEachStore(
              self.store.scope(state: { $0.filteredTodos }, action: AppAction.todo(id:action:)),
              content: TodoView.init(store:)
            )
            .onDelete { viewStore.send(.delete($0)) }
            .onMove { viewStore.send(.move($0, $1)) }
          }
          .unredacted(if: self.onboardingStep == .todos)// 4-4. 여기서 온보딩스탭인 것만 unredacted되도록
        }
        .navigationBarTitle("Todos")
        .navigationBarItems(
          trailing: HStack(spacing: 20) {
            EditButton()
            Button("Clear Completed") { viewStore.send(.clearCompletedButtonTapped) }
              .disabled(viewStore.isClearCompletedButtonDisabled)
            Button("Add Todo") { viewStore.send(.addTodoButtonTapped) }
          }
          .unredacted(if: self.onboardingStep == .actions)// 4-4. 여기서 온보딩스탭인 것만 unredacted되도록
        )
        .environment(
          \.editMode,
          viewStore.binding(get: { $0.editMode }, send: AppAction.editModeChanged)
        )
      }
      .navigationViewStyle(StackNavigationViewStyle())
    }
  }
}

extension AppState {
  var view: AppView.ViewState {
    .init(
      editMode: self.editMode,
      isClearCompletedButtonDisabled: !self.todos.contains(where: { $0.isComplete })
    )
  }
}

extension IdentifiedArray where ID == UUID, Element == Todo {
  fileprivate mutating func sortCompleted() {
    // Simulate stable sort
    self = IdentifiedArray(
      self.enumerated()
        .sorted(by: { lhs, rhs in
          (rhs.element.isComplete && !lhs.element.isComplete) || lhs.offset < rhs.offset
        })
        .map { $0.element }
    )
  }
}

extension IdentifiedArray where ID == UUID, Element == Todo {
  static let mock: Self = [
    Todo(
      description: "Check Mail",
      id: UUID(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-BEEDDEADBEEF")!,
      isComplete: false
    ),
    Todo(
      description: "Buy Milk",
      id: UUID(uuidString: "CAFEBEEF-CAFE-BEEF-CAFE-BEEFCAFEBEEF")!,
      isComplete: false
    ),
    Todo(
      description: "Call Mom",
      id: UUID(uuidString: "D00DCAFE-D00D-CAFE-D00D-CAFED00DCAFE")!,
      isComplete: true
    ),
  ]
}

// 3. 온보딩 생성
enum OnboardingStep {
  case actions
  case filters
  case todos

  var next: Self? {
    switch self {
    case .actions:
      return .filters
    case .filters:
      return .todos
    case .todos:
        return nil
    }
  }

  var previous: Self? {
    switch self {
    case .actions:
        return self
    case .filters:
      return .actions
    case .todos:
      return .filters
    }
  }
}
// 4. 온보딩 페이지시 설명하는 부분만 redacted가 풀리기 위해 추가한 environment
struct OnboardingStepEnvironmentKey: EnvironmentKey {
  static var defaultValue: OnboardingStep? = nil
}
extension EnvironmentValues {
  var onboardingStep: OnboardingStep? {
    get { self[OnboardingStepEnvironmentKey.self] }
    set { self[OnboardingStepEnvironmentKey.self] = newValue }
  }
}

struct OnboardingView: View {
  @State var step: OnboardingStep? // nil이라면 온보딩이 없다는 의미
  let store: Store<AppState, AppAction>

  var body: some View {
    if let step = self.step {
      ZStack {
          // 3-1. 온보딩이 현재 뷰 위에 올라가도록 추가
        AppView(
          store: Store(
            initialState: AppState(todos: .mock),
            reducer: .empty,
            environment: ()
          )
        )
        .environment(\.onboardingStep, self.step) // 4-1.해당 environment를 추가
        .redacted(reason: .placeholder)

        VStack {
          Spacer()

          HStack(alignment: .top) {
            Button(action: { self.step = self.step?.previous }) {
              Image(systemName: "chevron.left")
            }
            .frame(width: 44, height: 44)
            .foregroundColor(.white)
            .background(Color.gray)
            .clipShape(Circle())
            .padding([.leading, .trailing])

            Spacer()

            VStack {
              switch step {
              case .actions:
                Text("Use the navbar actions to mass delete todos, clear all your completed todos, or add a new one.")
              case .filters:
                Text("Use the filters bar to change what todos are currently displayed to you. Try changing a filter.")
              case .todos:
                Text("Here's your list of todos. You can check one off to complete it, or edit its title by tapping on the current title.")
              }
              Button("Skip") { self.step = nil }
                .padding()
            }

            Spacer()

            Button(action: { self.step = self.step?.next }) {
              Image(systemName: "chevron.right")
            }
            .frame(width: 44, height: 44)
            .background(Color.gray)
            .foregroundColor(.white)
            .clipShape(Circle())
            .padding([.leading, .trailing])
          }
        }
        .padding(.top, 400)
        .padding(.bottom, 100)
        .background(
          LinearGradient(
            gradient: .init(
              colors: [.init(white: 1, opacity: 0), .init(white: 0.8, opacity: 1)]
            ),
            startPoint: .top,
            endPoint: .bottom
          )
        )
      }
    } else { //실제 메모앱
      AppView(store: self.store)
    }
  }
}

struct OnboardingView_Previews: PreviewProvider {
  static var previews: some View {
    OnboardingView(
      step: .actions,
      store: Store(
        initialState: .init(),
        reducer: appReducer,
        environment: AppEnvironment(
          analytics: .live,
          mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
          uuid: UUID.init
        )
      )
    )
  }
}

// 1. 여기를 이리저리 바꾸면서 쉽게 상황 변경 가능
struct AppView_Previews: PreviewProvider {
  static var previews: some View {
    AppView(
      store: Store(
        initialState: AppState(todos: .mock),
//        reducer: .empty, // appReducer,
        reducer: Reducer { state, action, environment in
          switch action {
          case let .filterPicked(filter):
//            state.filter = filter
//            return .none
            return appReducer.run(&state, action, environment)

          default:
            return .none
          }
        },
//        environment: ()
        environment: AppEnvironment(
          analytics: .placeholder,
          mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
          uuid: UUID.init
        )
      )
    )
    .redacted(reason: .placeholder)
  }
}
// 2. anaylsis를 추가한다고 가정
struct AnalyticsClient {
  var track: (String, [String: String]) -> Effect<Never, Never>
}

// 2-1. 실제 버전일 떄의 anaylsis
extension AnalyticsClient {
  static let live = Self(
    track: { name, properties in
      .fireAndForget {
        // track event
      }
    }
  )
}
// 2-2. placeholder일 때의 anaylsis, 아무런 반응 없도록 구현
extension AnalyticsClient {
  static let placeholder = Self(
    track: { _, _ in .none }
  )
}
