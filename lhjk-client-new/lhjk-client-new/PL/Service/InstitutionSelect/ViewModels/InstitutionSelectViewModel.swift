import Foundation
import Combine
import CoreLocation

/// 选择服务机构 ViewModel — 对齐 funde `InstitutionSelectView`
@MainActor
final class InstitutionSelectViewModel: ObservableObject {

    @Published private(set) var items: [HospitalSearchVO] = []
    @Published private(set) var locationLabel = "定位中..."
    @Published private(set) var isLocating = false
    @Published private(set) var isLoadingList = false
    @Published private(set) var errorMessage: String?
    @Published var keyword = ""
    @Published private(set) var selectedId: String?

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

    // MARK: - Private

    private func refreshLocationAndList() async {
        isLocating = true
        locationLabel = "定位中..."
        defer { isLocating = false }

        do {
            let address = try await locationManager.locateAndReverseGeocode()
            locationLabel = makeLocationLabel(address)
            let tencent = MapCoordinateConverter.gaodeToTencent(address.coordinate)
            let pair = MapCoordinateConverter.queryString(from: tencent)
            tencentLongitude = pair.longitude
            tencentLatitude = pair.latitude
        } catch {
            locationLabel = "定位失败，可手动搜索机构"
            tencentLongitude = nil
            tencentLatitude = nil
        }

        reloadList()
    }

    private func reloadList() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            await self?.performSearch()
        }
    }

    private func performSearch() async {
        isLoadingList = true
        errorMessage = nil
        defer { isLoadingList = false }

        do {
            let page = try await hospitalService.searchPage(
                keyword: keyword,
                longitude: tencentLongitude,
                latitude: tencentLatitude,
                pageNum: 1,
                pageSize: 50
            )
            guard !Task.isCancelled else { return }
            items = page.records ?? []
        } catch {
            guard !Task.isCancelled else { return }
            items = []
            errorMessage = error.localizedDescription
        }
    }

    private func makeLocationLabel(_ address: ReverseGeocodedAddress) -> String {
        let parts = [address.city, address.area, address.detail]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if parts.isEmpty {
            return "已定位"
        }
        return parts.joined(separator: " ")
    }
}
