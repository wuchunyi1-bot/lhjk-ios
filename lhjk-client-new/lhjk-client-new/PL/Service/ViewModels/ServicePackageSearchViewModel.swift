import Foundation
import Combine

/// 当前账号的套餐搜索关键字。最多 10 条，新的在前。不同账号的 key 分开。
enum PackageSearchHistoryStore {

    static let limit = 10
    private static let keyPrefix = "fd_package_search_history."

    static func keywords(for userId: String) -> [String] {
        guard !userId.isEmpty else { return [] }
        return UserDefaults.standard.stringArray(forKey: storageKey(userId)) ?? []
    }

    static func record(_ keyword: String, userId: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !userId.isEmpty else { return }
        var items = keywords(for: userId).filter { $0 != trimmed }
        items.insert(trimmed, at: 0)
        if items.count > limit {
            items = Array(items.prefix(limit))
        }
        UserDefaults.standard.set(items, forKey: storageKey(userId))
    }

    static func clear(userId: String) {
        guard !userId.isEmpty else { return }
        UserDefaults.standard.removeObject(forKey: storageKey(userId))
    }

    static func remove(_ keyword: String, userId: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !userId.isEmpty else { return }
        let items = keywords(for: userId).filter { $0 != trimmed }
        UserDefaults.standard.set(items, forKey: storageKey(userId))
    }

    private static func storageKey(_ userId: String) -> String {
        keyPrefix + userId
    }
}

/// 首页搜索结果分组。健康知识暂不接入。
enum PackageSearchTab: Int, CaseIterable {
    case service = 1
    case mall = 2

    var title: String {
        switch self {
        case .service: return "健康服务"
        case .mall: return "富德优选"
        }
    }

    var apiType: Int { rawValue }
}

struct PackageSearchPage: Equatable {
    var items: [HealthPackageItem] = []
    var total: Int = 0
    var currentPage: Int = 0
    var totalPages: Int = 0
    var errorMessage: String?

    var hasMore: Bool { currentPage > 0 && currentPage < totalPages }
}

/// 搜索套餐 ViewModel。只有调用 `search()` 才会请求接口。
final class ServicePackageSearchViewModel: ObservableObject {

    static let pageSize = 10

    @Published var keyword = ""
    @Published private(set) var activeTab: PackageSearchTab = .service
    @Published private(set) var servicePage = PackageSearchPage()
    @Published private(set) var mallPage = PackageSearchPage()
    @Published private(set) var history: [String] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasSearched = false

    private let hospitalPackageService: HospitalPackageService
    private let hospitalId: String?
    private var searchTask: Task<Void, Never>?
    private var loadMoreTask: Task<Void, Never>?
    private var userPickedTab = false
    private var searchGeneration = 0

    init(
        hospitalId: String? = nil,
        hospitalPackageService: HospitalPackageService = AppContainer.shared.hospitalPackageService
    ) {
        self.hospitalId = hospitalId
        self.hospitalPackageService = hospitalPackageService
        reloadHistory()
    }

    deinit {
        searchTask?.cancel()
        loadMoreTask?.cancel()
    }

    var visiblePage: PackageSearchPage {
        page(for: activeTab)
    }

    func selectTab(_ tab: PackageSearchTab) {
        guard tab != activeTab else { return }
        userPickedTab = true
        activeTab = tab
    }

    func reloadHistory() {
        guard let userId = UserManager.shared.resolvedUserId else {
            history = []
            return
        }
        history = PackageSearchHistoryStore.keywords(for: userId)
    }

    func clearHistory() {
        guard let userId = UserManager.shared.resolvedUserId else {
            history = []
            return
        }
        PackageSearchHistoryStore.clear(userId: userId)
        history = []
    }

    func removeHistory(_ keyword: String) {
        guard let userId = UserManager.shared.resolvedUserId else { return }
        PackageSearchHistoryStore.remove(keyword, userId: userId)
        history = PackageSearchHistoryStore.keywords(for: userId)
    }

    /// 输入被清空时回到历史，不发请求。
    func noteKeywordEdited() {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty else { return }
        searchGeneration += 1
        searchTask?.cancel()
        loadMoreTask?.cancel()
        servicePage = PackageSearchPage()
        mallPage = PackageSearchPage()
        activeTab = .service
        hasSearched = false
        isLoading = false
        isLoadingMore = false
    }

    func search() {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        keyword = trimmed
        guard !trimmed.isEmpty else { return }
        if let userId = UserManager.shared.resolvedUserId {
            PackageSearchHistoryStore.record(trimmed, userId: userId)
            history = PackageSearchHistoryStore.keywords(for: userId)
        }
        performSearch(trimmed)
    }

    func loadMoreIfNeeded() {
        let tab = activeTab
        let current = page(for: tab)
        guard hasSearched, !isLoading, !isLoadingMore, current.errorMessage == nil, current.hasMore else { return }
        let nextPage = current.currentPage + 1
        let text = keyword
        let generation = searchGeneration
        isLoadingMore = true
        loadMoreTask?.cancel()
        loadMoreTask = Task { [weak self] in
            await self?.appendPage(tab: tab, keyword: text, pageNum: nextPage, generation: generation)
        }
    }

    // MARK: - Private

    private func page(for tab: PackageSearchTab) -> PackageSearchPage {
        tab == .service ? servicePage : mallPage
    }

    private func performSearch(_ text: String) {
        searchTask?.cancel()
        loadMoreTask?.cancel()
        userPickedTab = false
        searchGeneration += 1
        let generation = searchGeneration
        searchTask = Task { [weak self] in
            await self?.loadSearch(keyword: text, generation: generation)
        }
    }

    @MainActor
    private func loadSearch(keyword: String, generation: Int) async {
        isLoading = true
        isLoadingMore = false
        servicePage = PackageSearchPage()
        mallPage = PackageSearchPage()
        activeTab = .service

        async let service = fetchPage(tab: .service, keyword: keyword, pageNum: 1)
        async let mall = fetchPage(tab: .mall, keyword: keyword, pageNum: 1)
        let serviceResult = await service
        let mallResult = await mall
        guard !Task.isCancelled, generation == searchGeneration else { return }

        servicePage = serviceResult
        mallPage = mallResult
        if !userPickedTab {
            activeTab = serviceResult.items.isEmpty && !mallResult.items.isEmpty ? .mall : .service
        }
        isLoading = false
        hasSearched = true
    }

    @MainActor
    private func appendPage(tab: PackageSearchTab, keyword: String, pageNum: Int, generation: Int) async {
        let result = await fetchPage(tab: tab, keyword: keyword, pageNum: pageNum)
        guard !Task.isCancelled, generation == searchGeneration, self.keyword == keyword else {
            if generation == searchGeneration { isLoadingMore = false }
            return
        }
        var current = page(for: tab)
        if result.errorMessage == nil {
            current.items.append(contentsOf: result.items)
            current.currentPage = result.currentPage
            current.totalPages = result.totalPages
            current.total = result.total
        }
        assign(current, to: tab)
        isLoadingMore = false
    }

    private func fetchPage(tab: PackageSearchTab, keyword: String, pageNum: Int) async -> PackageSearchPage {
        do {
            let page = try await hospitalPackageService.searchEnabledPackagePage(
                keyword: keyword,
                type: tab.apiType,
                hospitalId: tab == .service ? hospitalId : nil,
                pageNum: pageNum,
                pageSize: Self.pageSize
            )
            guard !Task.isCancelled else { return PackageSearchPage() }
            let items = (page.records ?? []).enumerated().map { index, vo in
                HospitalPackageMapper.toPackageItem(vo, index: index)
            }
            let total = page.totalRecords ?? items.count
            let totalPages = page.totalPages ?? Self.pageCount(total: total, pageSize: Self.pageSize)
            return PackageSearchPage(
                items: items,
                total: total,
                currentPage: page.currentPage ?? pageNum,
                totalPages: total == 0 ? 0 : totalPages
            )
        } catch {
            guard !Task.isCancelled else { return PackageSearchPage() }
            return PackageSearchPage(errorMessage: error.localizedDescription)
        }
    }

    private func assign(_ page: PackageSearchPage, to tab: PackageSearchTab) {
        switch tab {
        case .service: servicePage = page
        case .mall: mallPage = page
        }
    }

    private static func pageCount(total: Int, pageSize: Int) -> Int {
        guard total > 0, pageSize > 0 else { return 0 }
        return Int(ceil(Double(total) / Double(pageSize)))
    }
}
