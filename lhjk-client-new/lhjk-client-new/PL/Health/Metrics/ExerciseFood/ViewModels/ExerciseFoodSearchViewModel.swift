import Combine
import Foundation

@MainActor
final class ExerciseFoodSearchViewModel: ObservableObject {

    @Published var keyword = ""
    @Published private(set) var items: [ExerciseFoodDefinitionItem] = []
    @Published private(set) var isLoading = false

    let toastMessage = PassthroughSubject<String, Never>()
    let itemSelected = PassthroughSubject<ExerciseFoodDefinitionItem, Never>()

    let type: Int

    private let service: ExerciseFoodService
    private var pageNum = 1
    private var hasMore = true

    init(type: Int, service: ExerciseFoodService = AppContainer.shared.exerciseFoodService) {
        self.type = type
        self.service = service
    }

    func search(reset: Bool = true) {
        if reset {
            pageNum = 1
            hasMore = true
        }
        isLoading = true
        Task {
            do {
                let list = try await service.fetchDefinitions(
                    type: type,
                    pageNum: pageNum,
                    name: keyword
                )
                if reset { items = list } else { items.append(contentsOf: list) }
                hasMore = list.count >= ExerciseFoodConstants.defaultPageSize
            } catch {
                if reset { items = [] }
                toastMessage.send(error.localizedDescription)
            }
            isLoading = false
        }
    }

    func loadMoreIfNeeded(currentIndex: Int) {
        guard currentIndex >= items.count - 3 else { return }
        guard hasMore, !isLoading else { return }
        pageNum += 1
        search(reset: false)
    }
}
