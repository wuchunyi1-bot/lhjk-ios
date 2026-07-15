import Combine
import Foundation

struct ExerciseFoodSelectedItem: Identifiable, Equatable {
    let id: String
    let definition: ExerciseFoodDefinitionItem
    var quantity: Int
    var calorie: String
}

@MainActor
final class ExerciseFoodAddDietViewModel: ObservableObject {

    @Published private(set) var categories: [ExerciseFoodCategory] = []
    @Published private(set) var definitions: [ExerciseFoodDefinitionItem] = []
    @Published var selectedCategoryIndex = 0
    @Published private(set) var selectedItems: [ExerciseFoodSelectedItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false

    let toastMessage = PassthroughSubject<String, Never>()
    let saveSucceeded = PassthroughSubject<Void, Never>()

    let timeType: Int?
    let dateString: String

    private let service: ExerciseFoodService
    private var pageNum = 1
    private var hasMore = true

    init(timeType: Int?, dateString: String, service: ExerciseFoodService = AppContainer.shared.exerciseFoodService) {
        self.timeType = timeType
        self.dateString = dateString
        self.service = service
    }

    var totalCalorie: Double {
        selectedItems.reduce(0) { $0 + (Double($1.calorie) ?? 0) }
    }

    func load() {
        Task {
            isLoading = true
            do {
                categories = try await service.fetchFoodCategories()
                pageNum = 1
                hasMore = true
                await loadDefinitions(reset: true)
            } catch {
                toastMessage.send(error.localizedDescription)
            }
            isLoading = false
        }
    }

    func selectCategory(at index: Int) {
        selectedCategoryIndex = index
        pageNum = 1
        hasMore = true
        Task { await loadDefinitions(reset: true) }
    }

    func loadMoreIfNeeded(currentIndex: Int) {
        guard currentIndex >= definitions.count - 3 else { return }
        guard hasMore, !isLoading else { return }
        pageNum += 1
        Task { await loadDefinitions(reset: false) }
    }

    func isSelected(_ item: ExerciseFoodDefinitionItem) -> Bool {
        selectedItems.contains { $0.definition.itemId?.value == item.itemId?.value }
    }

    func add(item: ExerciseFoodDefinitionItem, quantity: Int, calorie: String) {
        let id = item.itemId?.value ?? UUID().uuidString
        if let index = selectedItems.firstIndex(where: { $0.id == id }) {
            selectedItems[index].quantity = quantity
            selectedItems[index].calorie = calorie
            selectedItems = selectedItems
        } else {
            selectedItems.append(ExerciseFoodSelectedItem(id: id, definition: item, quantity: quantity, calorie: calorie))
        }
    }

    func addFromSearch(_ item: ExerciseFoodDefinitionItem) {
        let baseQty = item.quantity?.value ?? 1
        let baseCal = item.showCalorie ?? item.calorie?.value ?? "0"
        add(item: item, quantity: baseQty, calorie: baseCal)
    }

    func save() {
        guard !selectedItems.isEmpty else {
            toastMessage.send("请添加食物")
            return
        }
        isSaving = true
        let payloads = selectedItems.map {
            $0.definition.toSavePayload(timeType: timeType, quantity: $0.quantity, calorie: $0.calorie)
        }
        Task {
            do {
                try await service.saveDietItems(items: payloads, date: dateString, timeType: timeType)
                saveSucceeded.send()
            } catch {
                toastMessage.send(error.localizedDescription)
            }
            isSaving = false
        }
    }

    private func loadDefinitions(reset: Bool) async {
        let category = categories.indices.contains(selectedCategoryIndex)
            ? categories[selectedCategoryIndex].value : 0
        do {
            let list = try await service.fetchDefinitions(
                type: ExerciseFoodConstants.definitionTypeFood,
                pageNum: pageNum,
                category: category
            )
            if reset { definitions = list } else { definitions.append(contentsOf: list) }
            hasMore = list.count >= ExerciseFoodConstants.defaultPageSize
        } catch {
            if reset { definitions = [] }
            toastMessage.send(error.localizedDescription)
        }
    }
}
