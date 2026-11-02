import Combine
import CoreLocation
import Foundation

@MainActor
final class WellnessCabinListViewModel: ObservableObject {

    @Published private(set) var items: [CabinStoreVO] = []
    @Published private(set) var cityText = "定位中..."
    @Published private(set) var districtText = ""
    @Published private(set) var isLocating = false
    @Published private(set) var isLoadingList = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = true
    @Published private(set) var resultCount = 0
    @Published private(set) var errorMessage: String?
    @Published var keyword = ""

    private let pageSize = 20
    private var currentPage = 1
    private var requestID = 0
    private var longitude: String?
    private var latitude: String?
    private var searchTask: Task<Void, Never>?
    private var keywordCancellable: AnyCancellable?

    private let cabinService: CabinService
    private let locationManager: LocationManager

    init(
        cabinService: CabinService = AppContainer.shared.cabinService,
        locationManager: LocationManager = AppContainer.shared.locationManager
    ) {
        self.cabinService = cabinService
        self.locationManager = locationManager
        keywordCancellable = $keyword
            .dropFirst()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.reloadList()
            }
    }

    deinit {
        searchTask?.cancel()
    }

    var hintText: String {
        let query = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty, resultCount > 0 {
            return "共找到 \(resultCount) 家驿站"
        }
        return "按距离展示附近健康驿站"
    }

    func onAppear() {
        Task { await refreshLocationAndList() }
    }

    func refreshLocation() {
        Task { await refreshLocationAndList() }
    }

    func loadMore() {
        guard hasMore, !isLoadingMore, !isLoadingList else { return }
        isLoadingMore = true
        let id = requestID
        let next = currentPage + 1
        Task { [weak self] in
            await self?.performSearch(page: next, append: true, requestID: id)
        }
    }

    private func refreshLocationAndList() async {
        isLocating = true
        cityText = "定位中..."
        districtText = ""
        defer { isLocating = false }

        do {
            let address = try await locationManager.locateAndReverseGeocode()
            let city = address.city.trimmingCharacters(in: .whitespacesAndNewlines)
            let area = address.area.trimmingCharacters(in: .whitespacesAndNewlines)
            cityText = city.isEmpty ? (address.province.isEmpty ? "已定位" : address.province) : city
            districtText = area
            let pair = MapCoordinateConverter.queryString(from: address.coordinate)
            longitude = pair.longitude
            latitude = pair.latitude
        } catch {
            cityText = "定位失败"
            districtText = "可搜索驿站名称或地址"
            longitude = nil
            latitude = nil
        }
        reloadList()
    }

    private func reloadList() {
        currentPage = 1
        hasMore = true
        requestID += 1
        let id = requestID
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            await self?.performSearch(page: 1, append: false, requestID: id)
        }
    }

    private func performSearch(page: Int, append: Bool, requestID: Int) async {
        if append {
            isLoadingMore = true
        } else {
            isLoadingList = true
        }
        errorMessage = nil
        defer {
            isLoadingList = false
            isLoadingMore = false
        }

        do {
            let data = try await cabinService.listStores(
                keyword: keyword,
                longitude: longitude,
                latitude: latitude,
                pageNum: page,
                pageSize: pageSize
            )
            guard !Task.isCancelled, requestID == self.requestID else { return }
            let records = (data.records ?? []).filter { !$0.id.isEmpty && !$0.name.isEmpty }
            if append {
                let existing = Set(items.map(\.id))
                items.append(contentsOf: records.filter { !existing.contains($0.id) })
            } else {
                items = records
            }
            currentPage = page
            resultCount = data.totalRecords ?? items.count
            hasMore = Self.stillHasMore(page: page, pageSize: pageSize, data: data, records: records)
        } catch {
            guard !Task.isCancelled, requestID == self.requestID else { return }
            if !append { items = [] }
            resultCount = items.count
            errorMessage = error.localizedDescription
            hasMore = false
        }
    }

    private static func stillHasMore(
        page: Int,
        pageSize: Int,
        data: PaginatedCabinListData,
        records: [CabinStoreVO]
    ) -> Bool {
        if let total = data.totalPages, total > 0 { return page < total }
        if let totalRecords = data.totalRecords, totalRecords > 0 {
            return page * pageSize < totalRecords
        }
        return records.count >= pageSize
    }
}
