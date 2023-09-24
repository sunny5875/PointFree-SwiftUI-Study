import Foundation

func taskBasics() throws {
  let task = Task<Int, Error>.init {
    struct SomeError: Error {}
    throw SomeError()
    return 42
  }

  @Sendable func doSomethingAsync() async {}

  Task {
    await doSomethingAsync()
  }

  func doSomethingElseAsync() async {
    await doSomethingAsync()
  }

  func doSomethingThatCanFail() throws {}

  try doSomethingThatCanFail()

  func doSomething() /*throws*/ {
    do {
      try doSomethingThatCanFail()
    } catch let error {
  //    TODO: Handle error
    }
  }

  // (A) throws -> B
  // (A) -> Result<B, Error>

  // (inout A) -> B
  // (A) -> (B, A)

  // (A) async -> B
  // (A) -> Task<B, Never>
  // (A) -> ((B) -> Void) -> Void
  // (A, (B) -> Void) -> Void

  // dataTask: (URL, completionHandler: (Data?, Response?, Error?) -> Void) -> Void
  // start: ((MKLocalSearch.Response?, Error?) -> Void) -> Void



  for n in 0..<workCount {
    Task {
      let current = Thread.current
      try await Task.sleep(nanoseconds: NSEC_PER_SEC)
      if current != Thread.current {
        print(n, "Thread changed from", current, "to", Thread.current)
      }
    }
  }
}

func taskPriority() {
  Task(priority: .low) {
    print("low")
  }
  Task(priority: .high) {
    print("high")
  }
}

func taskCancellation() {
  func doSomething() async throws {
    try await Task.sleep(nanoseconds: NSEC_PER_SEC)
  }

  let task = Task {
    let start = Date()
    defer { print("Task finished in", Date().timeIntervalSince(start)) }

    let (data, _) = try await URLSession.shared.data(from: .init(string: "http://ipv4.download.thinkbroadband.com/1MB.zip")!)
    print(Thread.current, "network request finished", data.count)
  }

  Thread.sleep(forTimeInterval: 0.5)
  task.cancel()
}

func taskRest() {
enum RequestData {
  @TaskLocal static var requestId: UUID!
  @TaskLocal static var startDate: Date!
}


func databaseQuery() async throws {
  let requestId = RequestData.requestId!
  print(requestId, "Making database query")
  try await Task.sleep(nanoseconds: 500_000_000)
  print(requestId, "Finished database query")
}

func networkRequest() async throws {
  let requestId = RequestData.requestId!
  print(requestId, "Making network request")
  try await Task.sleep(nanoseconds: 500_000_000)
  print(requestId, "Finished network request")
}


func response(for request: URLRequest) async throws -> HTTPURLResponse {
  let requestId = RequestData.requestId!
  let start = RequestData.startDate!

  defer { print(requestId, "Request finished in", Date().timeIntervalSince(start)) }

  Task {
    print(RequestData.requestId!, "Track analytics")
  }
  try await databaseQuery()
  try await networkRequest()

  // TODO: return real response
  return .init()
}


//RequestData.$requestId.withValue(UUID()) {
//  RequestData.$startDate.withValue(Date()) {
//    Task {
//      _ = try await response(for: .init(url: .init(string: "https://www.pointfree.co")!))
//    }
//  }
//}


//enum MyLocals {
//  @TaskLocal static var id: Int!
//
//  // @TaskLocal var api: APIClient
//  // @TaskLocal var database: DatabaseClient
//  // @TaskLocal var stripe: StripeClient
//}
//
//func doSomething() async {
//  print("doSomething:", MyLocals.id!)
//}
//
//print("before:", MyLocals.id)
//MyLocals.$id.withValue(42) {
//  print("withValue:", MyLocals.id!)
//  Task {
//    MyLocals.$id.withValue(1729) {
//      Task {
//        try await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
//        print("Task 2:", MyLocals.id!)
//      }
//    }
//    try await Task.sleep(nanoseconds: NSEC_PER_SEC)
//    Task {
//      print("Task:", MyLocals.id!)
//      await doSomething()
//    }
//  }
//}
//print("after:", MyLocals.id)


//for _ in 0..<workCount {
//  Task {
//    while true {
//      await Task.yield()
//    }
//  }
//}
//Task {
//  print("Starting prime thread")
//  nthPrime(50_000)
//}

class Counter: @unchecked Sendable {
  let lock = NSLock()
  var count = 0
  var maximum = 0
  func increment() {
    self.lock.lock()
    self.count += 1
    self.lock.unlock()
    self.maximum = max(self.count, self.maximum)
  }
  func decrement() {
    self.lock.lock()
    defer { self.lock.unlock() }
    self.count -= 1
  }
}

actor CounterActor {
  var count = 0
  var maximum = 0
  func increment() {
    self.count += 1
    self.computeMaximum()
  }
  func decrement() {
    self.count -= 1
  }
  private func computeMaximum() {
    self.maximum = max(self.count, self.maximum)
  }
}

let counter = CounterActor()

for _ in 0..<workCount {
  Task {
    print("increment", Thread.current)
    await counter.increment()
  }
  Task {
    print("decrement", Thread.current)
    await counter.decrement()
  }
}

Thread.sleep(forTimeInterval: 1)
Task {
  await print("counter.count", counter.count)
  await print("counter.maximum", counter.maximum)
}


func doSomething() {
  let counter = Counter()
  Task {
    counter.increment()
  }
}
doSomething()

//func perform(client: DatabaseClient, work: @escaping @Sendable () -> Void) {
//  Task {
//    _ = try await client.fetchUsers()
//    try await Task.sleep(nanoseconds: NSEC_PER_SEC)
//    work()
//  }
//  Task {
//    _ = try await client.fetchUsers()
//    try await Task.sleep(nanoseconds: NSEC_PER_SEC)
//    work()
//  }
//  Task {
//    _ = try await client.fetchUsers()
//    try await Task.sleep(nanoseconds: NSEC_PER_SEC)
//    work()
//  }
//}
//
//struct User {}
//struct DatabaseClient {
//  var fetchUsers: @Sendable () async throws -> [User]
//  var createUser: @Sendable (User) async throws -> Void
//}
//extension DatabaseClient {
//  static let live = Self(
//    fetchUsers: { fatalError() },
//    createUser: { _ in fatalError() }
//  )
//}
//
//Task {
//  var count = 0
//  for _ in 0..<workCount {
//    perform(client: .live) {
//      print("Hello")
//    }
//  }
//  try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
//  print(count)
//}
}
