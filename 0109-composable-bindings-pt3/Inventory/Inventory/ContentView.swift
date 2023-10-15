import SwiftUI

struct Item: Hashable, Identifiable {
  let id = UUID()
  var name: String
  var color: Color?
  var status: Status
  
  enum Status: Hashable {
    case inStock(quantity: Int)
    case outOfStock(isOnBackOrder: Bool)
    
    var isInStock: Bool {
      guard case .inStock = self else { return false }
      return true
    }
    
  }

  enum Color: String, CaseIterable {
    case blue
    case green
    case black
    case red
    case yellow
    case white
    
    var toSwiftUIColor: SwiftUI.Color {
      switch self {
      case .blue:
        return .blue
      case .green:
        return .green
      case .black:
        return .black
      case .red:
        return .red
      case .yellow:
        return .yellow
      case .white:
        return .white
      }
    }
  }
}

extension Binding {
  func map<LocalValue>(_ keyPath: WritableKeyPath<Value, LocalValue>) -> Binding<LocalValue> {

    self[dynamicMember: keyPath]
  }
}

extension Binding {
  func unwrap<Wrapped>() -> Binding<Wrapped>? where Value == Wrapped? {
    guard let value = self.wrappedValue else { return nil }
    return Binding<Wrapped>(
      get: { value },
      set: { self.wrappedValue = $0 }
    )
  }

  subscript<Case>(
    casePath: CasePath<Value, Case>
  ) -> Binding<Case>? {
    self.matching(casePath)
  }

  func matching<Case>(
    _ casePath: CasePath<Value, Case>
  ) -> Binding<Case>? {
    guard let `case` = casePath.extract(from: self.wrappedValue) else { return nil }
    return Binding<Case>(
      get: { `case` },
      set: { `case` in self.wrappedValue = casePath.embed(`case`) }
    )
  }
}

import CasePaths

struct ItemView: View {
  @Binding var item: Item

  var body: some View {
    Form {
      TextField("Name", text: self.$item.name)

      Picker(selection: self.$item.color, label: Text("Color")) {
        Text("None")
          .tag(Item.Color?.none)

        ForEach(Item.Color.allCases, id: \.rawValue) { color in
          Text(color.rawValue)
            .tag(Optional(color))
        }
      }

      self.$item.status[/Item.Status.inStock].map { quantity in
        Section(header: Text("In stock")) {
          Stepper("Quantity: \(quantity.wrappedValue)", value: quantity)
          Button("Mark as sold out") {
            self.item.status = .outOfStock(isOnBackOrder: false)
          }
        }
      }

      self.$item.status[/Item.Status.outOfStock].map { isOnBackOrder in
        Section(header: Text("Out of stock")) {
          Toggle("Is on back order?", isOn:
            isOnBackOrder)
          Button("Is back in stock!") {
            self.item.status = .inStock(quantity: 1)
          }
        }
      }
    }
  }
}


//6. duplicated를 관리해보자
enum Draft: Identifiable {
    case adding(Item)
    case duplicating(Item)
    
    var id: UUID {
        switch self {
        case let .adding(item): return item.id
        case let .duplicating(item): return item.id
        }
    }
}

// 1. inventroyViewModel을 만들어서 인벤토리뷰를 만들어보자
class InventoryViewModel: ObservableObject {
//  @Published var draft: Item?
    @Published var draft: Draft?
  @Published var inventory: [Item]
 
    
  init(
    inventory: [Item] = []
  ) {
    self.inventory = inventory
  }
  
  func addButtonTapped() {
//    self.draft = Item(name: "", color: nil, status: .inStock(quantity: 1))
      self.draft = .adding(Item(name: "", color: nil, status: .inStock(quantity: 1)))
  }
  
  func cancelButtonTapped() {
    self.draft = nil
  }
  
  func saveButtonTapped() {
//    if let item = self.draft {
//      self.inventory.append(item)
//    }
//    self.draft = nil
      switch self.draft {
      case .none: break
      case let .some(.adding(item)),
          let .some(.duplicating(item)):
          self.inventory.append(item)
      }
      self.draft = nil
  }
    //4-4
    func saveButtonTapped(item: Item) {
      self.inventory.append(item)
    }
  
  func duplicate(item: Item) {
//    self.draft = Item(name: item.name, color: item.color, status: item.status)
      self.draft = .duplicating(Item(name: item.name, color: item.color, status: item.status))
  }
}

struct InventoryView: View {
    // 4. apple에서 해결한 방법
//    @State var draft: Item = .invalid //Item(name: "", status: .inStock(quantity: 1))
//    @State var isAdding = false
    @ObservedObject var viewModel: InventoryViewModel
    
  var body: some View {
    NavigationView {
      List {
        ForEach(self.viewModel.inventory, id: \.self) { item in
          HStack {
            VStack(alignment: .leading) {
              Text(item.name)

              Group { () -> Text in
                switch item.status {
                case let .inStock(quantity):
                  return Text("In stock: \(quantity)")
                case let .outOfStock(isOnBackOrder):
                  return Text("Out of stock" + (isOnBackOrder ? ": on back order" : ""))
                }
              }
            }

            Spacer()

            item.color.map { color in
              Rectangle()
                .frame(width: 30, height: 30)
                .foregroundColor(color.toSwiftUIColor)
                .border(Color.black, width: 1)
            }
            // 3. 복붙 버튼을 만들자!
            Button(action: {
                self.viewModel.duplicate(item: item)
                // 4-3
//                self.isAdding = true
//                   self.draft = Item(name: item.name, color: item.color, status: item.status)
            
            }) {
              Image(systemName: "doc.on.doc.fill")
            }
            .padding(.leading)
          }
          .buttonStyle(PlainButtonStyle())
          .foregroundColor(item.status.isInStock ? nil : Color.gray)
        }
      }
      .navigationBarTitle("Inventory")
      .navigationBarItems( // 오른쪽 버튼을 추가하는 코드
        trailing: Button("Add") {
          self.viewModel.addButtonTapped()
            // 4-2.
//            self.isAdding = true
        }
      )
        // 2. 기존 애플에 있는 코드로 구현한 방법
//        .sheet(item: self.$viewModel.draft) { _ in
//          self.$viewModel.draft.unwrap().map { item in
        // 2-1. 근데 viewModel,draft를 두번이나 넣어주넹 이걸 한번에 넣을 방법이 없을까??
//        .sheet(unwrap: self.$viewModel.draft) { item in
//          NavigationView {
//            ItemView(item: item)
//              .navigationBarItems(
//                leading: Button("Cancel") { self.viewModel.cancelButtonTapped() },
//                trailing: Button("Save") { self.viewModel.saveButtonTapped() }
//            )
//          }
//      }
        // 4-1.
//      .sheet(isPresented: self.$isAdding) {
//          NavigationView {
//              ItemView(item: self.$draft)
//                  .navigationBarItems(
//                    leading: Button("Cancel") {
//                        self.isAdding = false
//                        self.draft = Item(name: "", color: nil, status: .inStock(quantity: 1))
//                    },
//                    trailing: Button("Save") {
//                        self.isAdding = false
//                        self.viewModel.saveButtonTapped(item: self.draft)
//                        self.draft = Item(name: "", color: nil, status: .inStock(quantity: 1))
//                    }
//                  )
//              // 4-5. cancel버튼을 누르지 않고 그냥 유저가 내리는 경우에도 draft값이 비어야 하니까 추가
//                  .onDisappear {
//                      self.draft = Item(name: "", color: nil, status: .inStock(quantity: 1))
//                  }
//          }
//      }
        // 여기 건든 이후로 빌드가 안됨...일단 모르곘어서 둠...
      .sheet(unwrap: self.$viewModel.draft) { draft in
          NavigationView {
              draft[/Draft.adding]?.map {item in
                  ItemView(item: item)
                      .navigationBarItems(
                        leading: Button("Cancel") { self.viewModel.cancelButtonTapped() },
                        trailing: Button("Save") { self.viewModel.saveButtonTapped() }
                      )
                      .navigationTitle("Add Item")
              }

              draft[/Draft.duplicating]?.map {item in
                  ItemView(item: item)
                      .navigationBarItems(
                        leading: Button("Cancel") { self.viewModel.cancelButtonTapped() },
                        trailing: Button("Save") { self.viewModel.saveButtonTapped() }
                      )

                      .navigationTitle("Duplicating Item")
              }
          }
      }
    }
  }
}

// 5. 그냥 Invalid용 변수를 만들자
extension Item {
    static let invalid = Item(name: "invalid", status: .inStock(quantity: 1))
}

// 2-2. 좀 더 쉬워지도록 helper function 구현
extension View {
  func sheet<Item, Content>(
    unwrap item: Binding<Item?>,
    content: @escaping (Binding<Item>) -> Content
  ) -> some View where Item: Identifiable, Content: View {
    self.sheet(item: item) { _ in
      item.unwrap().map(content)
    }
  }
}


struct InventoryView_Previews: PreviewProvider {
  static var previews: some View {
    InventoryView(
      viewModel: InventoryViewModel(
        inventory: [
          Item(name: "Keyboard", color: .blue, status: .inStock(quantity: 100)),
          Item(name: "Charger", color: .yellow, status: .inStock(quantity: 20)),
          Item(name: "Phone", color: .green, status: .outOfStock(isOnBackOrder: true)),
          Item(name: "Headphones", color: .green, status: .outOfStock(isOnBackOrder: false)),
        ]
      )
    )
  }
}


struct ContentView: View {
    var body: some View {
        Text("Hello World")
    }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {

    struct Wrapper: View {
      @State var item = Item(name: "Keyboard", color: .green, status: .inStock(quantity: 1))

      var body: some View {
        ItemView(item: self.$item)
      }
    }

    return NavigationView {
      Wrapper()
    }
  }
}
