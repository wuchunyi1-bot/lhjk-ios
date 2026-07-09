import Foundation
import Combine

/// 搜索套餐 ViewModel
final class ServicePackageSearchViewModel: ObservableObject {

    @Published var keyword = ""
    @Published private(set) var packages: [HealthPackageItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasSearched = false
    @Published private(set) var errorMessage: String?

    private let hospitalPackageService: HospitalPackageService
    private let hospitalId: String?
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(
        hospitalId: String? = nil,
        hospitalPackageService: HospitalPackageService = AppContainer.shared.hospitalPackageService
    ) {
        self.hospitalId = hospitalId
        self.hospitalPackageService = hospitalPackageService

        $keyword
            .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.performSearch(text)
            }
            .store(in: &cancellables)
    }

    deinit { searchTask?.cancel() }

    var isEmpty: Bool {
        hasSearched && packages.isEmpty && !isLoading
    }

    func search() {
        performSearch(keyword)
    }

    // MARK: - Private

    private func performSearch(_ text: String) {
        searchTask?.cancel()

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            packages = []
            hasSearched = false
            errorMessage = nil
            isLoading = false
            return
        }

        searchTask = Task { [weak self] in
            await self?.loadSearch(keyword: trimmed)
        }
    }

    @MainActor
    private func loadSearch(keyword: String) async {
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            hasSearched = true
        }

        do {
            let items = try await hospitalPackageService.searchPackageItems(
                keyword: keyword,
                hospitalId: hospitalId
            )
            guard !Task.isCancelled else { return }
            packages = items
        } catch {
            guard !Task.isCancelled else { return }
            packages = []
            errorMessage = error.localizedDescription
            print("[ServicePackageSearchViewModel] search failed: \(error.localizedDescription)")
        }
    }
}
