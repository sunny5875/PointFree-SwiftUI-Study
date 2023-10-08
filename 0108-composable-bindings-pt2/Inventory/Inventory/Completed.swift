//
//  Completed.swift
//  Inventory
//
//  Created by 현수빈 on 2023/10/08.
//  Copyright © 2023 Point-Free. All rights reserved.
//
import SwiftUI

struct Item: Hashable, Identifiable {
  let id = UUID()
  var name: String
  var color: Color?
  var status: Status
  
  enum Status: Hashable {
    case inStock(quantity: Int)
    case outOfStock(isOnBackOrder: Bool)

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

    // string[0]이렇게 접근하도록 하는 코드
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


struct ContentView: View {
  var body: some View {
    Text("Hello, World!")
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
