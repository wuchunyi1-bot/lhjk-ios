import Foundation
import Combine
import CoreLocation

/// 选择服务机构 ViewModel — 对齐 funde `InstitutionSelectView`
@MainActor
final class InstitutionSelectViewModel: ObservableObject {

    @Published private(set) var items: [HospitalSearchVO] = []
    @Published private(set) var cityText = "定位中..."
    @Published private(set) var districtText = ""
    @Published private(set) var isLocating = false
    @Published private(set) var isLoadingList = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = true
    @Published private(set) var errorMessage: String?
    @Published var keyword = ""
    @Published private(set) var selectedId: String?

    private let pageSize = 20
    private var currentPage = 1
    private var requestID = 0

    private let hospitalService: HospitalService
    private let locationManager: LocationManager
    private let selectionStore: InstitutionSelectionStore

    private var tencentLongitude: String?
    private var tencentLatitude: String?
    private var searchTask: Task<Void, Never>?
    private var keywordCancellable: AnyCancellable?

    init(
        selectedId: String? = nil,
        hospitalService: HospitalService = AppContainer.shared.hospitalService,
        locationManager: LocationManager = AppContainer.shared.locationManager,
        selectionStore: InstitutionSelectionStore = AppContainer.shared.institutionSelectionStore
    ) {
        self.selectedId = selectedId ?? selectionStore.selected?.id
        self.hospitalService = hospitalService
        self.locationManager = locationManager
        self.selectionStore = selectionStore

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

    func onAppear() {
        Task { await refreshLocationAndList() }
    }

    func refreshLocation() {
        Task { await refreshLocationAndList() }
    }

    func select(_ item: HospitalSearchVO) {
        let selected = SelectedServiceInstitution(vo: item)
        selectionStore.select(selected)
        selectedId = selected.id
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

    // MARK: - Private

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
            let tencent = MapCoordinateConverter.gaodeToTencent(address.coordinate)
            let pair = MapCoordinateConverter.queryString(from: tencent)
            tencentLongitude = pair.longitude
            tencentLatitude = pair.latitude
        } catch {
            cityText = "定位失败"
            districtText = "可手动搜索机构"
            tencentLongitude = nil
            tencentLatitude = nil
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
            let data = try await hospitalService.searchPage(
                keyword: keyword,
                longitude: tencentLongitude,
                latitude: tencentLatitude,
                pageNum: page,
                pageSize: pageSize
            )
            guard !Task.isCancelled, requestID == self.requestID else { return }
            let records = data.records ?? []
            if append {
                let existing = Set(items.map(\.id))
                items.append(contentsOf: records.filter { !existing.contains($0.id) })
            } else {
                items = records
            }
            currentPage = page
            hasMore = Self.stillHasMore(page: page, pageSize: pageSize, data: data, records: records)
        } catch {
            guard !Task.isCancelled, requestID == self.requestID else { return }
            if !append {
                items = []
            }
            errorMessage = error.localizedDescription
            hasMore = false
        }
    }

    private static func stillHasMore(
        page: Int,
        pageSize: Int,
        data: PaginatedHospitalSearchData,
        records: [HospitalSearchVO]
    ) -> Bool {
        if let total = data.totalPages, total > 0 {
            return page < total
        }
        if let totalRecords = data.totalRecords, totalRecords > 0 {
            return page * pageSize < totalRecords
        }
        return records.count >= pageSize
    }
}
