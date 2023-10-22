import ComposableArchitecture
import SwiftUI

// 나중에 api 테스트르 위해 추가한 코드임
// 주로 protocol을 쓰긴 하지만 struct을 쓰는 것도 방법 중 하나임
struct NumberFactClient {
  var fetch: @Sendable (Int) async throws -> String
}
extension NumberFactClient: DependencyKey { // 아래에 key를 추가하기 위해 구현한 부분
  static let liveValue = Self { number in
    let (data, _) = try await URLSession.shared.data(
      from: URL(string: "http://www.numbersapi.com/\(number)")!
    )
    return String(decoding: data, as: UTF8.self)
  }
}
// keypath에 접근하기 위해 추가한 코드
extension DependencyValues {
  var numberFact: NumberFactClient {
    get { self[NumberFactClient.self] }
    set { self[NumberFactClient.self] = newValue }
  }
}

// 1. MARK: Reducer: state를 캡슐화, feature의 Logic, behavior을 정의
struct CounterFeature: Reducer {
// 2. state: 밑에 로직에 필요한 값들, state는 항상 struct이 아닐 수도 있지만 지금은 struct
  struct State: Equatable {
    var count = 0
    var fact: String?
    var isLoadingFact = false //7-4.loading indicator를 위해 추가
    var isTimerOn = false
  }
    // 3. action은 enum을 주로 사용
    // action: UI에서 User가 할 수 있는 일을 정의
    // 이때 action case의 이름은 사용자가 하는 일로 이름을 지어야 clear함!
  enum Action: Equatable {
    case decrementButtonTapped
    case factResponse(String)
    case getFactButtonTapped
    case incrementButtonTapped
    case timerTicked // 8-2. incrementButton대신할 timerTicked 함수 추가
    case toggleTimerButtonTapped
  }
    // 8-3
  private enum CancelID {
    case timer
  }
  @Dependency(\.continuousClock) var clock
  @Dependency(\.numberFact) var numberFact // numberFactClient dependency 추가
//3. body 생성
  var body: some ReducerOf<Self> { // Reducer<State, Action>과 같은 의미임
      // 안에 computed property가 들어감
      // 여러개의 reducer를 합쳐서 거대한 하나의 reducer를 만드는 곳
    Reduce { state, action in // 현재의 state, 전달받은 action
        // 4. reduce 안에서 해야할 일
        // 첫번쨰 action을 switch해야 하고 두번쨰 각 action마다 로직을 정해줘야 함, 상태가 변할 수도 있음
        // 그리고 effect을 리턴해줘야 함
      switch action {
      case .decrementButtonTapped:
        state.count -= 1
        state.fact = nil
        return .none

      case let .factResponse(fact): // 7-3. 여기서 fact를 변경
        state.fact = fact
        state.isLoadingFact = false
        return .none

      case .getFactButtonTapped:
        state.fact = nil
        state.isLoadingFact = true
        return .run { [count = state.count] send in // 7-1. api에서 주로 사용하는 effect인 run을 이용
           /* 7-2. 이 때, count를 캡쳐해야 되므로 위에 캡쳐
            let (data, _) = try await URLSession.shared.data(
                 from: URL(
                   string: "http://www.numbersapi.com/\(state.count)"
                 )!
               )
            let fact = String(decoding: data, as: UTF8.self)
            print(fact)
            state.fact = fact <- 하지만 여기서도 에러가 남. 캡쳐되지 않아서~~따라서 정확하게 하기 위해 동작을 한개 더 추가
            await send(.faceResponse(fact))
            */
          try await send(.factResponse(self.numberFact.fetch(count)))
        }

      case .incrementButtonTapped:
        state.count += 1
        state.fact = nil
        return .none

      case .timerTicked:
        state.count += 1
        return .none

      case .toggleTimerButtonTapped: // 8. 타이머 구현
        state.isTimerOn.toggle()
        if state.isTimerOn {
          return .run { send in
              // 8-1. 아래처럼 구현했지만 incrementButton을 누르지 않았는데 부르니까 조금 애매모호 다르게 해보자!
//              while true {
//                  try await Task.sleep(for: .seconds(1))
//                  send(.incrementButtonTapped)
//              }
            for await _ in self.clock.timer(interval: .seconds(1)) { // 라이브러리가 제공하는 방법
              await send(.timerTicked)
            }
          }
          .cancellable(id: CancelID.timer) // 8-2. 타이머를 다시 누르면 멈추기 위해 추가한 코드, reducer가 cancel effect해줌
        } else {
          return .cancel(id: CancelID.timer) // 8-4. 실제로 cancel하는 부분
        }
      }
    }
  }
}

struct ContentView: View {
    // 5. store을 가질 것, let으로 할 것
    // runtime of feature을 의미, store은 class임
    // A Store represents the runtime of the feature. It is the thing that is responsible for actually mutating the feature’s state when actions are sent, executing the side effects, and feeding their data back into the system.
  let store: StoreOf<CounterFeature> // Store<CounterFeature.State, CounterFeature.Action>과 동일
// 6. store값으로 변경
  var body: some View {
      // store을 바로 접근못함
      //  바로 접근하면 필요한 것보다 훨씬 더 많은 상태를 관찰할 수 있고 느리고 성능이 떨어지는 뷰를 초래할 수 있기 때문
      // WithViewStore이라는 걸을 제공해서 observe하고 싶은 것만 선택해서 봄
      // Swift 5.9부터는 withViewStore 필요 없댕
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      Form {
        Section {
          Text("\(viewStore.count)") // viewStore.state.count이지만 생략 가능
          Button("Decrement") {
            viewStore.send(.decrementButtonTapped)
          }
          Button("Increment") {
            viewStore.send(.incrementButtonTapped)
          }
        }
        Section {
          Button {
            viewStore.send(.getFactButtonTapped)
          } label: {
            HStack {
              Text("Get fact")
              if viewStore.isLoadingFact {
                Spacer()
                ProgressView()
              }
            }
          }
          if let fact = viewStore.fact {
            Text(fact)
          }
        }
        Section {
          if viewStore.isTimerOn {
            Button("Stop timer") {
              viewStore.send(.toggleTimerButtonTapped)
            }
          } else {
            Button("Start timer") {
              viewStore.send(.toggleTimerButtonTapped)
            }
          }
        }
      }
    }
  }
}

#Preview {
  ContentView(
    // 7. 모든 모델이 value type이고 reducer로 캡슐화됨
    store: Store(initialState: CounterFeature.State()) {
      CounterFeature()
        ._printChanges() // _printChange를 쓰면 system에 action이 들어가면 모두 print가 됨!!!
        // domain을 value type으로 했지만 mutation 전에 copy하고 mutation 후에 비교할 수 있음. 이건, reference type에서 지원하지 않는 기능
    }
  )
}

// 8. 이제 async작업인 api 콜과 timer에 대해서 로직을 구현하자!
