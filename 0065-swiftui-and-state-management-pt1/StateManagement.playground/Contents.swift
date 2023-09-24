
import SwiftUI

func foo() -> Int {
    fatalError() //이렇게 하면 컴파일은 되지만 실제 실행하면 앱이 죽을 꺼임
}


struct ContentView: View {
  @ObservedObject var state: AppState

  var body: some View {
    NavigationView {
      List {
        NavigationLink(destination: CounterView(state: self.state)) {
          Text("Counter demo")
                .bold()
        }
        NavigationLink(destination:  EmptyView()) {
          Text("Favorite primes")
                .bold()
        }
      }
      .navigationBarTitle("State management")
    }
  }
}

private func ordinal(_ n: Int) -> String {
  let formatter = NumberFormatter()
  formatter.numberStyle = .ordinal
  return formatter.string(for: n) ?? ""
}

//BindableObject

import Combine

class AppState: ObservableObject {
    // 1번 방법 == NotificationCenter같은 느낌
//        var count = 0 {
//            didSet {
//                self.objectWillChange.send() // 이거 하니까 되네 왜?
//                print(self.count)
//            }
//        }
    // 2번 방법
     @Published var count = 0
}

struct CounterView: View {
//    @State var count: Int = 0
    // self.count -> Int
    // self.$count -> Binding<Int>
  @ObservedObject var state: AppState

  var body: some View {
    VStack {
      HStack {
          Button(action: { self.state.count -= 1 }) {
          Text("-")
        }
          Text("\(self.state.count)")
          Button(action: { self.state.count += 1 }) {
          Text("+")
        }
      }
      Button(action: {}) {
        Text("Is this prime?")
              .foregroundColor(.black)
      }
      Button(action: {}) {
          Text("What is the \(ordinal(self.state.count)) prime?")
              .foregroundColor(.black)
      }
    }
    .font(.title)
    .navigationBarTitle("Counter demo")
  }
}


import PlaygroundSupport

PlaygroundPage.current.liveView = UIHostingController(
    rootView: ContentView(state: AppState()) .frame(width: 500.0, height: 700.0)
//  rootView: CounterView()
)

PlaygroundPage.current.needsIndefiniteExecution = true
