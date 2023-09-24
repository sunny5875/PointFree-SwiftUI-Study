import Dependencies
import SwiftUI

@main
struct StandupsApp: App {
  var body: some Scene {
    WindowGroup {
      // NB: This conditional is here only to facilitate UI testing so that we can mock out certain
      //     dependencies for the duration of the test (e.g. the data manager). We do not really
      //     recommend performing UI tests in general, but we do want to demonstrate how it can be
      //     done.
      if ProcessInfo.processInfo.environment["UITesting"] == "true" {
        UITestingView()
      } else {
        AppView(
          model: AppModel(
            path: [
              .detail(StandupDetailModel(standup: .mock)),
              .meeting(Standup.mock.meetings[0], standup: .mock),
              .record(RecordMeetingModel(standup: .mock))
            ],
            standupsList: StandupsListModel(
            )
          )
        )
//        StandupsList(
//          model: StandupsListModel()
//        )
      }
    }
  }
}

struct UITestingView: View {
  var body: some View {
    withDependencies {
      $0.dataManager = .mock()
    } operation: {
      StandupsList(model: StandupsListModel())
    }
  }
}
