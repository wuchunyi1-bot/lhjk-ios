import Foundation
import Combine

/// 富德优选商城 Tab 项
struct MallCategoryTab: Equatable {
    let id: String?
    let title: String

    static let all = MallCategoryTab(id: nil, title: "全部")

    var categoryServiceId: String { id ?? "" }
}

/// 富德优选商城 ViewModel — 对齐 funde-client `HealthMallView.vue`
@MainActor
final class HealthMallViewModel: ObservableObject {

    @Published private(set) var tabs: [MallCategoryTab] = [.all]
    @Published private(set) var selectedTabIndex = 0
    @Published private(set) var products: [HealthPackageItem] = []
    @Published private(set) var isLoadingTabs = false
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = true
    @Published private(set) var showEmptyState = false

    private let hospitalPackageService: HospitalPackageService
    private var loadTask: Task<Void, Never>?
    private var productsTask: Task<Void, Never>?
    private var loadGeneration = 0

    private let productPageSize = 10
    private var currentPage = 1
    private var totalPages = 1

    init(hospitalPackageService: HospitalPackageService = .shared) {
        self.hospitalPackageService = hospitalPackageService
    }

    deinit {
        loadTask?.cancel()
        productsTask?.cancel()
    }

    var tabTitles: [String] {
        tabs.map(\.title)
    }

    var selectedTab: MallCategoryTab {
        guard tabs.indices.contains(selectedTabIndex) else { return .all }
        return tabs[selectedTabIndex]
    }

    func load() {
        loadTask?.cancel()
        productsTask?.cancel()
        loadGeneration += 1
        let generation = loadGeneration

        loadTask = Task { [weak self] in
            guard let self else { return }
            await self.loadTabs(generation: generation)
            guard self.isCurrent(generation) else { return }
            await self.loadProducts(for: self.selectedTab, generation: generation)
        }
    }

    func selectTab(at index: Int) {
        guard tabs.indices.contains(index), index != selectedTabIndex else { return }
        selectedTabIndex = index
        productsTask?.cancel()
        loadGeneration += 1
        let generation = loadGeneration
        productsTask = Task { [weak self] in
            guard let self else { return }
            await self.loadProducts(for: self.selectedTab, generation: generation)
        }
    }

    func loadMore() {
        guard !isLoadingMore, !isLoadingProducts, hasMore else { return }
        isLoadingMore = true

        let generation = loadGeneration
        let tab = selectedTab
        let nextPage = currentPage + 1

        Task { [weak self] in
            guard let self else { return }
            do {
                let pageData = try await self.hospitalPackageService.fetchRetailPackages(
                    categoryServiceId: tab.categoryServiceId,
                    pageNum: nextPage,
                    pageSize: self.productPageSize
                )
                guard self.isCurrent(generation) else { return }

                let newItems = Self.mapItems(pageData.records, pageNum: nextPage, pageSize: self.productPageSize)
                self.applyPage(pageData, items: newItems, append: true)
                self.isLoadingMore = false
            } catch {
                print("[HealthMallVM] loadMore failed: \(error.localizedDescription)")
                guard self.isCurrent(generation) else { return }
                self.isLoadingMore = false
            }
        }
    }

    // MARK: - Private

    private func isCurrent(_ generation: Int) -> Bool {
        generation == loadGeneration
    }

    private func resetPaging() {
        currentPage = 1
        totalPages = 1
        hasMore = true
        isLoadingMore = false
    }

    private func loadTabs(generation: Int) async {
        isLoadingTabs = true
        defer {
            if isCurrent(generation) { isLoadingTabs = false }
        }

        do {
            let categories = try await hospitalPackageService.fetchRetailCategoryList()
            guard isCurrent(generation) else { return }

            let categoryTabs = categories.compactMap { vo -> MallCategoryTab? in
                let title = vo.serviceName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let id = vo.id.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !title.isEmpty, !id.isEmpty else { return nil }
                return MallCategoryTab(id: id, title: title)
            }
            tabs = [.all] + categoryTabs
            if selectedTabIndex >= tabs.count {
                selectedTabIndex = 0
            }
        } catch {
            print("[HealthMallVM] load tabs failed: \(error.localizedDescription)")
            guard isCurrent(generation) else { return }
            tabs = [.all]
            selectedTabIndex = 0
        }
    }

    private func loadProducts(for tab: MallCategoryTab, generation: Int) async {
        resetPaging()
        isLoadingProducts = true
        showEmptyState = false
        products = []
        defer {
            if isCurrent(generation) { isLoadingProducts = false }
        }

        do {
            let pageData = try await hospitalPackageService.fetchRetailPackages(
                categoryServiceId: tab.categoryServiceId,
                pageNum: 1,
                pageSize: productPageSize
            )
            guard isCurrent(generation) else { return }
            let items = Self.mapItems(pageData.records, pageNum: 1, pageSize: productPageSize)
            applyPage(pageData, items: items, append: false)
        } catch {
            print("[HealthMallVM] load products failed: \(error.localizedDescription)")
            guard isCurrent(generation) else { return }
            products = []
            hasMore = false
            showEmptyState = true
        }
    }

    private func applyPage(
        _ pageData: PaginatedHospitalPackageData,
        items: [HealthPackageItem],
        append: Bool
    ) {
        if append {
            products += items
        } else {
            products = items
        }

        let resolvedCurrent = pageData.currentPage ?? (append ? currentPage + 1 : 1)
        currentPage = resolvedCurrent
        if let total = pageData.totalPages, total > 0 {
            totalPages = total
            hasMore = !items.isEmpty && resolvedCurrent < total
        } else {
            hasMore = items.count >= productPageSize
        }
        showEmptyState = products.isEmpty
    }

    private static func mapItems(
        _ records: [HospitalPackagePageVO]?,
        pageNum: Int,
        pageSize: Int
    ) -> [HealthPackageItem] {
        (records ?? []).enumerated().map { index, vo in
            HospitalPackageMapper.toPackageItem(vo, index: (pageNum - 1) * pageSize + index)
        }
    }
}
