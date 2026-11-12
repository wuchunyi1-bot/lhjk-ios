import Combine
import CoreLocation
import Foundation

/// 列表定位。设备定位关闭时，用手选省市区解析出的坐标同样可以算距离。
struct CabinListAnchor: Equatable {
    var province: String
    var city: String
    var district: String
    var longitude: String
    var latitude: String
    /// `gps` 或 `manual`
    var source: String

    var region: RegionSelection {
        RegionSelection(province: province, city: city, district: district)
    }

    var fieldText: String {
        let parts: [String]
        if province == city {
            parts = [province, district]
        } else {
            parts = [province, city, district]
        }
        let text = parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        guard source == "gps", !text.isEmpty else { return text }
        return text + "（GPS）"
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude = Double(latitude), let longitude = Double(longitude) else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

@MainActor
final class WellnessCabinListViewModel: ObservableObject {

    @Published private(set) var items: [CabinStoreVO] = []
    @Published private(set) var anchor: CabinListAnchor?
    @Published private(set) var isLocating = false
    @Published private(set) var isLoadingList = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = true
    @Published private(set) var resultCount = 0
    @Published private(set) var notice: String?
    @Published private(set) var asksForRegionPicker = false
    @Published var keyword = ""

    var locationReady: Bool { anchor != nil }

    var hintText: String {
        if anchor == nil {
            return "请先选择省、市、区，再查看附近驿站"
        }
        let query = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty, resultCount > 0 {
            return "共找到 \(resultCount) 家驿站"
        }
        return "按距离展示附近健康驿站（仅「驿站」网点）"
    }

    private let pageSize = 20
    private var currentPage = 1
    private var requestID = 0
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

    func onAppear() {
        UserDefaults.standard.removeObject(forKey: Self.legacyAnchorKey)
        guard anchor == nil else {
            reloadList()
            return
        }
        guard locationManager.authorizationStatus() == .authorized else {
            items = []
            return
        }
        beginLocate(automatic: true)
    }

    func consumeRegionPickerRequest() {
        asksForRegionPicker = false
    }

    func clearNotice() {
        notice = nil
    }

    func useCurrentGPS() {
        beginLocate(automatic: false)
    }

    func applyManualRegion(_ selection: RegionSelection) {
        commitManualRegion(selection)
    }

    func loadMore() {
        guard locationReady, hasMore, !isLoadingMore, !isLoadingList else { return }
        isLoadingMore = true
        let id = requestID
        let next = currentPage + 1
        Task { [weak self] in
            await self?.performSearch(page: next, append: true, requestID: id)
        }
    }

    private func beginLocate(automatic: Bool) {
        guard !isLocating else { return }
        isLocating = true
        Task { [weak self] in
            await self?.locateWithGPS(automatic: automatic)
        }
    }

    private func locateWithGPS(automatic: Bool) async {
        defer { isLocating = false }
        do {
            let address = try await locationManager.locateAndReverseGeocode()
            let pair = Self.coordinateText(address.coordinate)
            let blob = [address.province, address.city, address.area, address.detail]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined()
            let matched = ChinaRegionService.shared.matchedSelection(
                province: address.province,
                city: address.city,
                district: address.area,
                addressText: blob
            )
            let province = Self.filled(matched?.province, address.province)
            let city = Self.filled(matched?.city, address.city)
            let district = Self.filled(matched?.district, address.area)
            guard !province.isEmpty || !city.isEmpty || !district.isEmpty else {
                notice = "已定位，请手动选择省市区"
                if !automatic { asksForRegionPicker = true }
                return
            }
            let next = CabinListAnchor(
                province: province,
                city: city,
                district: district,
                longitude: pair.longitude,
                latitude: pair.latitude,
                source: "gps"
            )
            anchor = next
            if !automatic { notice = "已使用当前位置" }
            reloadList()
        } catch {
            notice = "未能获取 GPS，请手动选择省市区"
            if !automatic { asksForRegionPicker = true }
        }
    }

    private func commitManualRegion(_ selection: RegionSelection) {
        let province = selection.province.trimmingCharacters(in: .whitespacesAndNewlines)
        let city = selection.city.trimmingCharacters(in: .whitespacesAndNewlines)
        let district = selection.district.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !province.isEmpty, !city.isEmpty, !district.isEmpty else {
            notice = "请选择省、市、区"
            return
        }
        let next = CabinListAnchor(
            province: province,
            city: city,
            district: district,
            longitude: "",
            latitude: "",
            source: "manual"
        )
        anchor = next
        notice = "地区已更新"
        reloadList()
    }

    private func reloadList() {
        guard let anchor else {
            items = []
            resultCount = 0
            hasMore = false
            return
        }
        currentPage = 1
        hasMore = true
        requestID += 1
        let id = requestID
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            await self?.performSearch(page: 1, append: false, requestID: id, anchor: anchor)
        }
    }

    private func performSearch(page: Int, append: Bool, requestID: Int, anchor explicit: CabinListAnchor? = nil) async {
        guard let anchor = explicit ?? self.anchor else { return }
        if append {
            isLoadingMore = true
        } else {
            isLoadingList = true
        }
        defer {
            isLoadingList = false
            isLoadingMore = false
        }

        do {
            let located = anchor.source == "gps"
            let data = try await cabinService.listStores(
                keyword: keyword,
                province: located ? nil : anchor.province,
                city: located ? nil : anchor.city,
                area: located ? nil : anchor.district,
                longitude: located ? anchor.longitude : nil,
                latitude: located ? anchor.latitude : nil,
                pageNum: page,
                pageSize: pageSize
            )
            guard !Task.isCancelled, requestID == self.requestID else { return }
            let records = Self.fillingDistance(
                (data.records ?? []).filter { !$0.id.isEmpty && !$0.name.isEmpty },
                around: anchor
            )
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
            notice = error.localizedDescription
            hasMore = false
        }
    }

    /// 定位权限关闭时接口可能不回距离。用当前查询坐标和门店经纬度补上。
    private static func fillingDistance(_ records: [CabinStoreVO], around anchor: CabinListAnchor) -> [CabinStoreVO] {
        guard let origin = anchor.coordinate else { return records }
        let here = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        return records.map { item in
            var item = item
            if item.distanceMeters == nil,
               let rawLatitude = item.latitude, let latitude = Double(rawLatitude),
               let rawLongitude = item.longitude, let longitude = Double(rawLongitude) {
                let meters = here.distance(from: CLLocation(latitude: latitude, longitude: longitude))
                item.distanceMeters = Int64(meters.rounded())
            }
            return item
        }
    }

    /// 设备坐标是 WGS-84。小屋接口要 GCJ-02，转换后按完整数值上传。
    private static func coordinateText(_ coordinate: CLLocationCoordinate2D) -> (longitude: String, latitude: String) {
        let gcj = MapCoordinateConverter.wgs84ToGcj02(coordinate)
        return (String(gcj.longitude), String(gcj.latitude))
    }

    private static func filled(_ preferred: String?, _ fallback: String) -> String {
        let first = preferred?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !first.isEmpty { return first }
        return fallback.trimmingCharacters(in: .whitespacesAndNewlines)
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

    /// 旧版本地记录。进入页面时清掉，不再回填上次地区。
    private static let legacyAnchorKey = "wellnessCabin.listAnchor"
}
