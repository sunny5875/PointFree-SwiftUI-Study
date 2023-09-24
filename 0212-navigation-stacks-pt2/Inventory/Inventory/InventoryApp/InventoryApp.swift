import AppFeature
import InventoryFeature
import ItemFeature
import ItemRowFeature
import Models
import SwiftUI


class NestedModel: ObservableObject {
  @Published var child: NestedModel?
  init(child: NestedModel? = nil) {
    self.child = child
  }
}


struct NestedView: View {
  @ObservedObject var model: NestedModel

  var body: some View {
    Button {
      self.model.child = NestedModel()
    } label: {
      Text("Go to child feature")
    }
    .navigationDestination(unwrapping: self.$model.child) { $child in
      NestedView(model: child)
    }
//    NavigationLink(
//      unwrapping: self.$model.child
//    ) { isActive in
//      self.model.child = isActive ? NestedModel() : nil
//    } destination: { $child in
//      NestedView(model: child)
//    } label: {
//      Text("Go to child feature")
//    }
  }
}


let lastItem = Item(
  name: "Headphones",
  color: .red,
  status: .outOfStock(isOnBackOrder: false)
)


@main
struct InventoryApp: App {
  let model = AppModel(
    inventoryModel: InventoryModel(
      path: [
        .colorPicker,
        .edit,
      ],
//      destination: .edit(
//        ItemModel(
//          destination: .colorPicker,
//          item: <#T##Item#>
//        )
//      ),
      inventory: [
        ItemRowModel(
          item: Item(name: "Phone", color: .green, status: .outOfStock(isOnBackOrder: true))
        ),
        ItemRowModel(
          item: Item(name: "Headphones", color: .red, status: .outOfStock(isOnBackOrder: false))
        ),
        ItemRowModel(
          item: lastItem
        )
      ]
    ),
    selectedTab: .inventory
  )

  var body: some Scene {
    let _ = print("Default item ids:")
    let _ = print(model.inventoryModel.inventory.map(\.id.uuidString).joined(separator: "\n"))
    WindowGroup {
//      AppView(model: self.model)
//        .onOpenURL { url in
//          self.model.open(url: url)
//        }

      NavigationStack {
        NestedView(
          model: NestedModel(
            child: NestedModel(
              child: NestedModel(
                child: NestedModel(
                  child: NestedModel(
                    child: NestedModel(
                      child: .init()
                    )
                  )
                )
              )
            )
          )
        )
      }
    }
  }
}



/*
                                 |-------|
                                 |   U   |
                 |-------|       |   s   |
                 |   I   |       |   e   |-------|
         |-------|   n   |       |   r   |   S   |
         |   I   |   v   |-------|   P   |   e   |
         |   t   |   e   |   S   |   r   |   t   |
 |-------|   e   |   n   |   e   |   o   |   t   |
 |   I   |   m   |   t   |   a   |   f   |   i   |    ...
 |   t   |   R   |   o   |   r   |   i   |   n   |
 |   e   |   o   |   r   |   c   |   l   |   g   |
 |   m   |   w   |   y   |   h   |   e   |   s   |
 |-------|-------|-------|-------|-------|------*/
/*--------------------------------------------------------|
|                                                         |
|            MODEL/HELPER/DEPENDENCY MODULES              |
|                                                         |
|      |---------------|-----------|---------------|      |
|      |    Models     | ApiClient | ApiClientLive |      |
|      |---------------|-----------|---------------|      |
|                                                         |
|---------------------------------------------------------|
*/
