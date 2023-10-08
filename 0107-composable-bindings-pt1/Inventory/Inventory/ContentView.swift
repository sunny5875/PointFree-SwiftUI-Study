import SwiftUI

struct Item {
  var name: String
  var color: Color?
    // status와 관련된 변수들은 묶어서 관리하는 것이 좋음!
//  var quantity = 1
//  var isInStock = true
//  var isOnBackOrder = false
  var status: Status
  
  enum Status {
    case inStock(quantity: Int)
    case outOfStock(isOnBackOrder: Bool)
    
    var isInStock: Bool {
      guard case .inStock = self else { return false }
      return true
    }
    
    var quantity: Int {
      get {
        switch self {
        case .inStock(quantity: let quantity):
          return quantity
        case .outOfStock:
          return 0
        }
      }
      set {
//        switch self {
//        case .inStock:
          self = .inStock(quantity: newValue)
//        case .outOfStock:
//          break
//        }
      }
    }
    
    var isOnBackOrder: Bool {
      get {
        guard case let .outOfStock(isOnBackOrder) = self else {
          return false
//          return true
//          return nil
        }
        return isOnBackOrder
      }
      set {
//        switch self {
//        case .inStock:
//          break
//        case .outOfStock:
          self = .outOfStock(isOnBackOrder: newValue)
//        }
      }
    }
  }

  enum Color: String, CaseIterable { // allCases를 쓰기 위해 CaseIterable을 구현, hashable을 지원하기 위해 rawValue타입인 String을 상속
    case blue
    case green
    case black
    case red
    case yellow
    case white
  }

//  static func inStock(
//    name: String,
//    color: Color?,
//    quantity: Int
//  ) -> Self {
//    Item(name: name, color: color, quantity: quantity, isInStock: true, isOnBackOrder: false)
//  }
//
//  static func outOfStock(
//    name: String,
//    color: Color?,
//    isOnBackOrder: Bool
//  ) -> Self {
//    Item(name: name, color: color, quantity: 0, isInStock: false, isOnBackOrder: isOnBackOrder)
//  }
}

struct ItemView: View {
  @Binding var item: Item

  var body: some View {
    Form {
      TextField("Name", text: self.$item.name)

      Picker(selection: self.$item.color, label: Text("Color")) {
        Text("None")
          .tag(Item.Color?.none) // 피커에 색이 선택되지 않은 경우의 뷰

        ForEach(Item.Color.allCases, id: \.rawValue) { color in
          Text(color.rawValue)
            .tag(Optional(color))
        }
      }

      if self.item.status.isInStock {
        Section(header: Text("In stock")) {
          Stepper("Quantity: \(self.item.status.quantity)", value: self.$item.status.quantity) // -+해주는 뷰를 의미
          Button("Mark as sold out") {
//            self.item.quantity = 0
//            self.item.isInStock = false
            self.item.status = .outOfStock(isOnBackOrder: false)
          }
        }
      } else {
        Section(header: Text("Out of stock")) {
          Toggle("Is on back order?", isOn: self.$item.status.isOnBackOrder)
          Button("Is back in stock!") {
//            self.item.quantity = 1
//            self.item.isInStock = true
            self.item.status = .inStock(quantity: 1)
          }
        }
      }
    }
  }
}

struct ContentView: View {
  var body: some View {
    Text("Hello, World!")
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {

    struct Wrapper: View {
      @State var item = Item(name: "Keyboard", color: .none, status: .inStock(quantity: 1))

      var body: some View {
        ItemView(item: self.$item)
      }
    }

    return NavigationView {
      Wrapper()
    }
  }
}
