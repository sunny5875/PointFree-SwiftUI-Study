import ComposableArchitecture
import XCTest
@testable import Counter

@MainActor
final class CounterTests: XCTestCase {
    func testCounter() async {
        let store = TestStore(initialState: CounterFeature.State()) { // TestStore이라는 것을 제공해줌
            CounterFeature()
        }
        
        await store.send(.incrementButtonTapped) {
            $0.count = 1 // $0은 동작하기 전의 상태를 의미, 전송된 후의 정확한 상태가 되도록 변형하는 것이 이 {}에서 해야할 일!! 일치하지 않으면 실패함
            // XCAssert를 쓰면 만약 하나의 state가 바뀌면 테스트 코드를 계속 바꿔줘야 함.이렇게 하면 그럴 필요 x
        }
    }
    
    // timer의 경우, 계속 돌게 되니까 test에서 이런 안보이는 버그들도 잡아줌!!
    func testTimer() async throws {
        let clock = TestClock()
        
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        } withDependencies: { //dependency를 넣는데 이 때, 만든 testClock을 넣어줌!!
            $0.continuousClock = clock
        }
        
        //먼저 키고
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerOn = true
        }
        // 가짜로 타이머 돌리기, 실제로 시간이 지나면 불리는 게 맞는지 체크하는 코드
        await clock.advance(by: .seconds(1)) // testClock으로 하면 실제 1초를 기다리지 않아 훨씬 좋음!!
        await store.receive(.timerTicked) {
            $0.count = 1
        }
        await clock.advance(by: .seconds(1))
        await store.receive(.timerTicked) {
            $0.count = 2
        }
        // 마지막에 꺼줘야 테스트 싪패되지 않음
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerOn = false
        }
    }
    
    func testGetFact() async {
        // 빌드 실패: 외부 의존성이기 때문에 API가 우리에게 보낼 숫자를 예측할 방법이 없기데 테스트 불가
        // 따라서, 의존성에 대한 통제를 가져오기 위해 NumberFactCLient를 추가!
        //      let store = TestStore(
        //        initialState: CounterFeature.State()
        //      ) {
        //        CounterFeature()
        //      } withDependencies: {
        //        $0.continuousClock = ImmediateClock()
        //      }
        //
        //      await store.send(.getFactButtonTapped) {
        //        $0.isLoadingFact = true
        //      }
        //
        //      await store.receive(
        //        .factResponse(
        //          """
        //          0 is the atomic number of the \
        //          theoretical element tetraneutron.
        //          """
        //        )
        //      ) {
        //        $0.isLoadingFact = false
        //        $0.fact = """
        //          0 is the atomic number of the \
        //          theoretical element tetraneutron.
        //          """
        //      }
        
        
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        } withDependencies: {
            $0.numberFact.fetch = { "\($0) is a great number!" }
        }
        await store.send(.getFactButtonTapped) {
            $0.isLoadingFact = true
        }
        await store.receive(.factResponse("0 is a great number!")) {
            $0.fact = "0 is a great number!"
            $0.isLoadingFact = false
        }
    }
    
    func testGetFact_Failure() async {
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        } withDependencies: {
            $0.numberFact.fetch = { _ in
                struct SomeError: Error {}
                throw SomeError()
            }
        }
        XCTExpectFailure() // 실패하니까 실패를 체크
        await store.send(.getFactButtonTapped) {
            $0.isLoadingFact = true
        }
    }
}
















