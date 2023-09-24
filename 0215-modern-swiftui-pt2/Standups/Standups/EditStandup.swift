import SwiftUI
import SwiftUINavigation

class EditStandupModel: ObservableObject {
  @Published var focus: EditStandupView.Field?
  @Published var standup: Standup

  init(
    focus: EditStandupView.Field? = .title,
    standup: Standup
  ) {
    self.focus = .title
    self.standup = standup
    if self.standup.attendees.isEmpty {
      self.standup.attendees.append(Attendee(id: Attendee.ID(UUID()), name: ""))
    }
  }

  func deleteAttendees(atOffsets indices: IndexSet) {
    self.standup.attendees.remove(atOffsets: indices)
    if self.standup.attendees.isEmpty {
      self.standup.attendees.append(Attendee(id: Attendee.ID(UUID()), name: ""))
    }
    let index = min(indices.first!, self.standup.attendees.count - 1)
    self.focus = .attendee(self.standup.attendees[index].id)
  }

  func addAttendeeButtonTapped() {
    let attendee = Attendee(id: Attendee.ID(UUID()), name: "")
    self.standup.attendees.append(attendee)
    self.focus = .attendee(attendee.id)
  }
}

struct EditStandupView: View {
  enum Field: Hashable {
    case attendee(Attendee.ID)
    case title
  }

  @FocusState var focus: Field?
//  @Binding var standup: Standup
  @ObservedObject var model: EditStandupModel

//  init(focus: Field? = .title, standup: Binding<Standup>) {
//    self._standup = standup
//    self.focus = focus
//  }

  var body: some View {
    Form {
      Section {
        TextField("Title", text: self.$model.standup.title)
          .focused(self.$focus, equals: .title)
        HStack {
          Slider(value: self.$model.standup.duration.seconds, in: 5...30, step: 1) {
            Text("Length")
          }
          Spacer()
          Text(self.model.standup.duration.formatted(.units()))
        }
        ThemePicker(selection: self.$model.standup.theme)
      } header: {
        Text("Standup Info")
      }
      Section {
        ForEach(self.$model.standup.attendees) { $attendee in
          TextField("Name", text: $attendee.name)
            .focused(self.$focus, equals: .attendee(attendee.id))
        }
        .onDelete { indices in
          self.model.deleteAttendees(atOffsets: indices)
        }

        Button("New attendee") {
          self.model.addAttendeeButtonTapped()
        }
      } header: {
        Text("Attendees")
      }
    }
    .bind(self.$model.focus, to: self.$focus)
  }
}

struct ThemePicker: View {
  @Binding var selection: Theme

  var body: some View {
    Picker("Theme", selection: $selection) {
      ForEach(Theme.allCases) { theme in
        ZStack {
          RoundedRectangle(cornerRadius: 4)
            .fill(theme.mainColor)
          Label(theme.name, systemImage: "paintpalette")
            .padding(4)
        }
        .foregroundColor(theme.accentColor)
        .fixedSize(horizontal: false, vertical: true)
        .tag(theme)
      }
    }
  }
}

extension Duration {
  fileprivate var seconds: Double {
    get { Double(self.components.seconds / 60) }
    set { self = .seconds(newValue * 60) }
  }
}
struct EditStandup_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      EditStandupView(model: EditStandupModel(standup: .mock))
    }
  }
}
