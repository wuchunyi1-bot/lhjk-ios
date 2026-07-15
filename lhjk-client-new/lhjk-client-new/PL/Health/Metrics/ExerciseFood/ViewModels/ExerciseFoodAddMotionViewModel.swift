import Combine
import Foundation

@MainActor
final class ExerciseFoodAddMotionViewModel: ObservableObject {

    @Published private(set) var definitions: [ExerciseFoodDefinitionItem] = []
    @Published private(set) var selectedItems: [ExerciseFoodSelectedItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false

    let toastMessage = PassthroughSubject<String, Never>()
    let saveSucceeded = PassthroughSubject<Void, Never>()

    let dateString: String

    private let service: ExerciseFoodService
    private var pageNum = 1
    private var hasMore = true

    init(dateString: String, service: ExerciseFoodService = AppContainer.shared.exerciseFoodService) {
        self.dateString = dateString
        self.service = service
    }

    var totalCalorie: Double {
        selectedItems.reduce(0) { $0 + (Double($1.calorie) ?? 0) }
    }

    func load() {
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
            toastMessage.send("请添加运动")
            return
        }
        isSaving = true
        let payloads = selectedItems.map {
            $0.definition.toSavePayload(timeType: nil, quantity: $0.quantity, calorie: $0.calorie)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let time = formatter.string(from: Date())
        let beginTime = service.sportTimestamp(date: dateString, time: time)
        Task {
            do {
                try await service.saveSportItems(items: payloads, beginTime: beginTime)
                saveSucceeded.send()
            } catch {
                toastMessage.send(error.localizedDescription)
            }
            isSaving = false
        }
    }

    private func loadDefinitions(reset: Bool) async {
        isLoading = true
        do {
            let list = try await service.fetchDefinitions(
                type: ExerciseFoodConstants.definitionTypeSport,
                pageNum: pageNum
            )
            if reset { definitions = list } else { definitions.append(contentsOf: list) }
            hasMore = list.count >= ExerciseFoodConstants.defaultPageSize
        } catch {
            if reset { definitions = [] }
            toastMessage.send(error.localizedDescription)
        }
        isLoading = false
    }
}
