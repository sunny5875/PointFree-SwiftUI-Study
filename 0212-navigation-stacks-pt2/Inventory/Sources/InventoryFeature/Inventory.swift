import CasePaths
import IdentifiedCollections
import ItemFeature
import ItemRowFeature
import Models
import SwiftUI
import SwiftUINavigation

public final class InventoryModel: ObservableObject {
  @Published public var destination: Destination?
  @Published public var inventory: IdentifiedArrayOf<ItemRowModel> {
    didSet { self.bind() }
  }
  @Published public var isSaving = false

  public enum Destination: Equatable {
    case add(ItemModel)
    case edit(ItemModel)
    case help
  }

  public init(
    destination: Destination? = nil,
    inventory: IdentifiedArrayOf<ItemRowModel> = []
  ) {
    self.destination = destination
    self.inventory = inventory
    self.bind()
  }

  private func bind() {
    for itemRowModel in self.inventory {
      itemRowModel.commitDeletion = { [weak self, itemID = itemRowModel.item.id] in
        withAnimation {
          _ = self?.inventory.remove(id: itemID)
        }
      }
      itemRowModel.commitDuplication = { [weak self] item in
        self?.confirmAdd(item: item)
      }
      itemRowModel.onTap = { [weak self, weak itemRowModel] in
        guard let self, let itemRowModel else { return }
        self.destination = .edit(ItemModel(item: itemRowModel.item))
      }
    }
  }

  func confirmAdd(item: Item) {
    withAnimation {
      self.inventory.append(ItemRowModel(item: item))
      self.destination = nil
    }
  }

  func addButtonTapped() {
    self.destination = .add(
      ItemModel(
        item: Item(name: "", color: nil, status: .inStock(quantity: 1))
      )
    )
  }

  func cancelAddButtonTapped() {
    self.destination = nil
  }

  func helpButtonTapped() {
    self.destination = .help
  }

  func deactivateEdit() {
    self.destination = nil
  }

  func cancelEditButtonTapped() {
    self.destination = nil
  }

  @MainActor
  func commitEdit() async {
    guard case let .some(.edit(itemModel)) = self.destination
    else { return } // TODO: precondition?

    self.isSaving = true
    defer { self.isSaving = false }

    do {
      // NB: Emulate an API request
      try await Task.sleep(nanoseconds: NSEC_PER_SEC)
    } catch {}

    self.inventory[id: itemModel.id]?.item = itemModel.item
    self.destination = nil
  }
}

public struct InventoryView: View {
  @ObservedObject var model: InventoryModel

  public init(model: InventoryModel) {
    self.model = model
  }

  public var body: some View {
    NavigationStack.i {
      List {
        ForEach(
          self.model.inventory,
          content: ItemRowView.init(model:)
        )
      }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button("Add") { self.model.addButtonTapped() }
        }
        ToolbarItem(placement: .secondaryAction) {
          Button("Help") { self.model.helpButtonTapped() }
        }
      }
      .navigationDestination(
        unwrapping: self.$model.destination,
        case: /InventoryModel.Destination.edit
      ) { $itemModel in
        ItemView(model: itemModel)
          .navigationBarTitle("Edit")
          .navigationBarBackButtonHidden(true)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Cancel") {
                self.model.cancelEditButtonTapped()
              }
            }
            ToolbarItem(placement: .primaryAction) {
              HStack {
                if self.model.isSaving {
                  ProgressView()
                }
                Button("Save") {
                  Task { await self.model.commitEdit() }
                }
              }
              .disabled(self.model.isSaving)
            }
          }
      }
//      .background {
//        NavigationLink(
//          unwrapping: self.$model.destination,
//          case: /InventoryModel.Destination.edit
//        ) { isActive in
//          self.model.deactivateEdit()
//        } destination: { $itemModel in
//          ItemView(model: itemModel)
//            .navigationBarTitle("Edit")
//            .navigationBarBackButtonHidden(true)
//            .toolbar {
//              ToolbarItem(placement: .cancellationAction) {
//                Button("Cancel") {
//                  self.model.cancelEditButtonTapped()
//                }
//              }
//              ToolbarItem(placement: .primaryAction) {
//                HStack {
//                  if self.model.isSaving {
//                    ProgressView()
//                  }
//                  Button("Save") {
//                    Task { await self.model.commitEdit() }
//                  }
//                }
//                .disabled(self.model.isSaving)
//              }
//            }
//        } label: {
//          EmptyView()
//        }
////        .hidden()
////        .accessibility(hidden: true)
//      }
      .navigationTitle("Inventory")
      .sheet(
        unwrapping: self.$model.destination,
        case: /InventoryModel.Destination.help
      ) { _ in
        Text("Help!")
      }
      .sheet(
        unwrapping: self.$model.destination,
        case: CasePath(InventoryModel.Destination.add)
      ) { $itemToAdd in
        NavigationView {
          ItemView(model: itemToAdd)
            .navigationTitle("Add")
            .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { self.model.cancelAddButtonTapped() }
              }
              ToolbarItem(placement: .primaryAction) {
                Button("Save") { self.model.confirmAdd(item: itemToAdd.item) }
              }
            }
        }
      }
    }
  }
}

struct InventoryView_Previews: PreviewProvider {
  static var previews: some View {
    let keyboard = Item(name: "Keyboard", color: .blue, status: .inStock(quantity: 100))

    NavigationView {
      InventoryView(
        model: InventoryModel(
          inventory: [
            ItemRowModel(item: keyboard),
            ItemRowModel(item: Item(name: "Charger", color: .yellow, status: .inStock(quantity: 20))),
            ItemRowModel(
              item: Item(name: "Phone", color: .green, status: .outOfStock(isOnBackOrder: true))),
            ItemRowModel(
              item: Item(
                name: "Headphones", color: .green, status: .outOfStock(isOnBackOrder: false))),
          ]
        )
      )
    }
  }
}

