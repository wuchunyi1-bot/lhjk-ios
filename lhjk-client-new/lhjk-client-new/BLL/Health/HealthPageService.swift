import Foundation

/// 健康首页 / 编辑卡片相关接口
///
/// Apifox:
/// - CMS: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/495657301e0.md
/// - 卡片列表: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/495657300e0.md
/// - 查询配置: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/495657299e0.md
/// - 保存配置: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/495657298e0.md
final class HealthPageService {

    static let shared = HealthPageService()

    /// APP 健康楼层 code
    static let columnHealthCode = "column_health"

    private init() {}

    enum HealthPageServiceError: LocalizedError {
        case missingHospitalId
        case requestFailed(String)

        var errorDescription: String? {
            switch self {
            case .missingHospitalId: return "缺少机构 hospitalId"
            case .requestFailed(let msg): return msg
            }
        }
    }

    // MARK: - hospitalId

    /// 解析合法数字 hospitalId：机构选择 → 登录用户 → 服务目录临时回退
    static func resolveHospitalId(
        userManager: UserManager = AppContainer.shared.userManager,
        catalog: ServiceCatalogService = AppContainer.shared.serviceCatalogService
    ) -> String? {
        if let id = ServiceCatalogService.validApiHospitalId(
            InstitutionSelectionStore.shared.selectedHospitalId
        ) {
            return id
        }
        if let id = ServiceCatalogService.validApiHospitalId(
            userManager.loginUserInfo?.hospitalId
        ) {
            return id
        }
        return catalog.selectedApiHospitalId()
    }

    // MARK: - APIs

    /// `GET /v1/healthPage/getCmsConfig`
    func getCmsConfig(hospitalId: String, code: String = columnHealthCode) async throws -> HealthCmsConfigVO {
        let hid = try requireHospitalId(hospitalId)
        print("[HealthPageService] getCmsConfig → hospitalId=\(hid) code=\(code)")

        let response: APIResponse<HealthCmsConfigVO> = try await APIManager.shared.getAsync(
            path: "/v1/healthPage/getCmsConfig",
            parameters: ["hospitalId": hid, "code": code],
            responseType: APIResponse<HealthCmsConfigVO>.self
        )
        guard response.isSuccess else {
            print("[HealthPageService] getCmsConfig ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw HealthPageServiceError.requestFailed(response.msg ?? "获取健康页 CMS 失败")
        }
        let data = response.data ?? HealthCmsConfigVO(monitorCardMeta: [], quickEntryList: [])
        print("[HealthPageService] getCmsConfig ✓ cards=\(data.monitorCardMeta?.count ?? 0) quick=\(data.quickEntryList?.count ?? 0)")
        return data
    }

    /// `GET /v1/monitorHealth/getMonitorCardList`
    func getMonitorCardList(hospitalId: String, code: String = columnHealthCode) async throws -> [MonitorHealthCardVO] {
        let hid = try requireHospitalId(hospitalId)
        print("[HealthPageService] getMonitorCardList → hospitalId=\(hid) code=\(code)")

        let response: APIResponse<[MonitorHealthCardVO]> = try await APIManager.shared.getAsync(
            path: "/v1/monitorHealth/getMonitorCardList",
            parameters: ["hospitalId": hid, "code": code],
            responseType: APIResponse<[MonitorHealthCardVO]>.self
        )
        guard response.isSuccess else {
            print("[HealthPageService] getMonitorCardList ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw HealthPageServiceError.requestFailed(response.msg ?? "获取体征监测卡片失败")
        }
        let list = response.data ?? []
        print("[HealthPageService] getMonitorCardList ✓ count=\(list.count)")
        return list
    }

    /// `GET /v1/userMonitorCardConfig/getUserMonitorCardConfig`
    func getUserMonitorCardConfig(hospitalId: String, code: String = columnHealthCode) async throws -> UserMonitorCardConfigVO {
        let hid = try requireHospitalId(hospitalId)
        print("[HealthPageService] getUserMonitorCardConfig → hospitalId=\(hid) code=\(code)")

        let response: APIResponse<UserMonitorCardConfigVO> = try await APIManager.shared.getAsync(
            path: "/v1/userMonitorCardConfig/getUserMonitorCardConfig",
            parameters: ["hospitalId": hid, "code": code],
            responseType: APIResponse<UserMonitorCardConfigVO>.self
        )
        guard response.isSuccess else {
            print("[HealthPageService] getUserMonitorCardConfig ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw HealthPageServiceError.requestFailed(response.msg ?? "获取卡片配置失败")
        }
        let data = response.data ?? UserMonitorCardConfigVO(displayedCard: [], hiddenCard: [])
        print("[HealthPageService] getUserMonitorCardConfig ✓ displayed=\(data.displayedCard?.count ?? 0) hidden=\(data.hiddenCard?.count ?? 0)")
        return data
    }

    /// `POST /v1/userMonitorCardConfig/saveUserMonitorCardConfig`
    /// - Note: 不传 `hiddenCardVOList`（服务端按 CMS 卡池计算）
    func saveUserMonitorCardConfig(
        hospitalId: String,
        code: String = columnHealthCode,
        addCardVOList: [MonitorCardConfigItemDTO]
    ) async throws {
        let hid = try requireHospitalId(hospitalId)
        print("[HealthPageService] saveUserMonitorCardConfig → hospitalId=\(hid) count=\(addCardVOList.count)")

        var body: [String: Any] = [
            "code": code,
            "addCardVOList": addCardVOList.map { $0.asDictionary() },
        ]
        if let n = Int64(hid) {
            body["hospitalId"] = n
        } else {
            body["hospitalId"] = hid
        }

        let response: APIResponse<EmptyResponse> = try await APIManager.shared.postAsync(
            path: "/v1/userMonitorCardConfig/saveUserMonitorCardConfig",
            parameters: body,
            responseType: APIResponse<EmptyResponse>.self
        )
        guard response.isSuccess else {
            print("[HealthPageService] saveUserMonitorCardConfig ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw HealthPageServiceError.requestFailed(response.msg ?? "保存卡片配置失败")
        }
        print("[HealthPageService] saveUserMonitorCardConfig ✓")
    }

    private func requireHospitalId(_ hospitalId: String) throws -> String {
        guard let id = ServiceCatalogService.validApiHospitalId(hospitalId) else {
            throw HealthPageServiceError.missingHospitalId
        }
        return id
    }
}

// MARK: - 健康 Hub 缓存

/// 健康首页 Hub 数据（CMS + 监测卡片列表）— 会话内内存缓存
struct HealthPageHubCache {
    let hospitalId: String
    let cms: HealthCmsConfigVO
    let monitorCards: [MonitorHealthCardVO]
}

/// 健康 Tab Hub 预加载与会话内缓存 — 对标 `ServiceHubCacheService`。
final class HealthPageCacheService {

    static let shared = HealthPageCacheService()

    private(set) var hasLoaded = false

    private var cached: HealthPageHubCache?
    private var preloadTask: Task<HealthPageHubCache?, Never>?
    private var refreshTask: Task<HealthPageHubCache?, Never>?
    private var generation = 0

    private let healthPageService: HealthPageService

    init(healthPageService: HealthPageService = .shared) {
        self.healthPageService = healthPageService
    }

    func getCached() -> HealthPageHubCache? {
        guard let cached, isCacheHospitalCurrent(cached) else { return nil }
        return cached
    }

    @discardableResult
    func preload() async -> HealthPageHubCache? {
        if let cached, hasLoaded, isCacheHospitalCurrent(cached) {
            return cached
        }
        if hospitalIdChanged() {
            invalidate()
        }
        if let preloadTask {
            return await preloadTask.value
        }

        let gen = generation
        let task = Task { [weak self] () -> HealthPageHubCache? in
            guard let self else { return nil }
            let result = await self.fetchFromNetwork()
            guard gen == self.generation else { return result }
            if let result {
                self.cached = result
                self.hasLoaded = true
            }
            return result
        }
        preloadTask = task
        let result = await task.value
        preloadTask = nil
        return result
    }

    @discardableResult
    func refresh() async -> HealthPageHubCache? {
        if hospitalIdChanged() {
            invalidate()
        }
        if let refreshTask {
            return await refreshTask.value
        }

        let gen = generation
        let task = Task { [weak self] () -> HealthPageHubCache? in
            guard let self else { return nil }
            let result = await self.fetchFromNetwork()
            guard gen == self.generation else { return result }
            if let result {
                self.cached = result
                self.hasLoaded = true
            }
            return result
        }
        refreshTask = task
        let result = await task.value
        refreshTask = nil
        return result
    }

    func invalidate() {
        hasLoaded = false
        print("[HealthPageCache] invalidated")
    }

    func clear() {
        generation += 1
        cached = nil
        hasLoaded = false
        preloadTask?.cancel()
        preloadTask = nil
        refreshTask?.cancel()
        refreshTask = nil
        print("[HealthPageCache] cleared")
    }

    private func hospitalIdChanged() -> Bool {
        guard let cached else { return false }
        guard let current = HealthPageService.resolveHospitalId() else { return true }
        return cached.hospitalId != current
    }

    private func isCacheHospitalCurrent(_ hub: HealthPageHubCache) -> Bool {
        guard let current = HealthPageService.resolveHospitalId() else { return false }
        return hub.hospitalId == current
    }

    private func fetchFromNetwork() async -> HealthPageHubCache? {
        guard let hospitalId = HealthPageService.resolveHospitalId() else {
            print("[HealthPageCache] skip fetch — missing hospitalId")
            return nil
        }

        async let cmsOutcome = loadCms(hospitalId: hospitalId)
        async let listOutcome = loadCardList(hospitalId: hospitalId)
        let (cmsResult, listResult) = await (cmsOutcome, listOutcome)

        switch cmsResult {
        case .success:
            break
        case .failure(let error):
            print("[HealthPageCache] getCmsConfig ✗ \(error.localizedDescription)")
            if cached == nil { return nil }
            return cached
        }

        switch listResult {
        case .success:
            break
        case .failure(let error):
            print("[HealthPageCache] getMonitorCardList ✗ \(error.localizedDescription)")
        }

        guard case .success(let cms) = cmsResult else { return cached }

        let cards: [MonitorHealthCardVO]
        if case .success(let list) = listResult {
            cards = list
        } else {
            cards = cached?.monitorCards ?? []
        }

        return HealthPageHubCache(
            hospitalId: hospitalId,
            cms: cms,
            monitorCards: cards
        )
    }

    private func loadCms(hospitalId: String) async -> Result<HealthCmsConfigVO, Error> {
        do {
            return .success(try await healthPageService.getCmsConfig(hospitalId: hospitalId))
        } catch {
            return .failure(error)
        }
    }

    private func loadCardList(hospitalId: String) async -> Result<[MonitorHealthCardVO], Error> {
        do {
            return .success(try await healthPageService.getMonitorCardList(hospitalId: hospitalId))
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - VO / DTO

struct HealthCmsConfigVO: Decodable, Equatable {
    let monitorCardMeta: [MonitorCardMetaVO]?
    let quickEntryList: [HealthQuickEntryVO]?
}

struct MonitorCardMetaVO: Decodable, Equatable {
    let cardType: Int?
    let cardName: String?
    let iconUrl: String?
    let sortId: Int?
    let pageUrl: String?
    let cmsCreateTime: Int64?

    private enum CodingKeys: String, CodingKey {
        case cardType, cardName, iconUrl, sortId, pageUrl, cmsCreateTime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cardType = HealthFlexible.decodeInt(c, key: .cardType)
        cardName = try c.decodeIfPresent(String.self, forKey: .cardName)
        iconUrl = try c.decodeIfPresent(String.self, forKey: .iconUrl)
        sortId = HealthFlexible.decodeInt(c, key: .sortId)
        pageUrl = try c.decodeIfPresent(String.self, forKey: .pageUrl)
        cmsCreateTime = HealthFlexible.decodeInt64(c, key: .cmsCreateTime)
    }
}

struct HealthQuickEntryVO: Decodable, Equatable {
    let name: String?
    let iconUrl: String?
    let pageUrl: String?
    let sortId: Int?

    private enum CodingKeys: String, CodingKey {
        case name, iconUrl, pageUrl, sortId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        iconUrl = try c.decodeIfPresent(String.self, forKey: .iconUrl)
        pageUrl = try c.decodeIfPresent(String.self, forKey: .pageUrl)
        sortId = HealthFlexible.decodeInt(c, key: .sortId)
    }
}

struct MonitorHealthCardVO: Decodable, Equatable {
    let cardName: String?
    let cardType: Int?
    let monitorTime: Int64?
    let monitorTimeType: String?
    let resultType: Int?
    let result: String?
    let allResultList: [Int]?
    let monitorData: [String: HealthJSONValue]?
    let dietSportData: [String: HealthJSONValue]?
    let iconUrl: String?
    /// 卡片背景图 URL（优先于本地 metric_*）
    let backgroundUrl: String?
    let pageUrl: String?

    private enum CodingKeys: String, CodingKey {
        case cardName, cardType, monitorTime, monitorTimeType, resultType, result
        case allResultList, monitorData, dietSportData, iconUrl, backgroundUrl, pageUrl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cardName = try c.decodeIfPresent(String.self, forKey: .cardName)
        cardType = HealthFlexible.decodeInt(c, key: .cardType)
        monitorTime = HealthFlexible.decodeInt64(c, key: .monitorTime)
        monitorTimeType = try c.decodeIfPresent(String.self, forKey: .monitorTimeType)
        resultType = HealthFlexible.decodeInt(c, key: .resultType)
        result = try c.decodeIfPresent(String.self, forKey: .result)
        allResultList = HealthFlexible.decodeIntArray(c, key: .allResultList)
        monitorData = try c.decodeIfPresent([String: HealthJSONValue].self, forKey: .monitorData)
        dietSportData = try c.decodeIfPresent([String: HealthJSONValue].self, forKey: .dietSportData)
        iconUrl = try c.decodeIfPresent(String.self, forKey: .iconUrl)
        backgroundUrl = try c.decodeIfPresent(String.self, forKey: .backgroundUrl)
        pageUrl = try c.decodeIfPresent(String.self, forKey: .pageUrl)
    }
}

struct UserMonitorCardConfigVO: Decodable, Equatable {
    let displayedCard: [MonitorCardItemVO]?
    let hiddenCard: [MonitorCardItemVO]?
}

struct MonitorCardItemVO: Decodable, Equatable {
    let cardName: String?
    let iconUrl: String?
    let cardType: Int?
    let sortId: Int?
    let hospitalId: Int64?

    private enum CodingKeys: String, CodingKey {
        case cardName, iconUrl, cardType, sortId, hospitalId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cardName = try c.decodeIfPresent(String.self, forKey: .cardName)
        iconUrl = try c.decodeIfPresent(String.self, forKey: .iconUrl)
        cardType = HealthFlexible.decodeInt(c, key: .cardType)
        sortId = HealthFlexible.decodeInt(c, key: .sortId)
        hospitalId = HealthFlexible.decodeInt64(c, key: .hospitalId)
    }
}

struct MonitorCardConfigItemDTO: Equatable {
    let cardName: String?
    let cardType: Int
    let sortId: Int

    func asDictionary() -> [String: Any] {
        var d: [String: Any] = [
            "cardType": cardType,
            "sortId": sortId,
        ]
        if let cardName, !cardName.isEmpty {
            d["cardName"] = cardName
        }
        return d
    }
}

/// Int / Int64 / String 柔性解码（后端常把时间戳、id 以字符串下发）
enum HealthFlexible {
    static func decodeInt<K: CodingKey>(_ c: KeyedDecodingContainer<K>, key: K) -> Int? {
        if let i = try? c.decodeIfPresent(Int.self, forKey: key) { return i }
        if let i = try? c.decodeIfPresent(Int64.self, forKey: key) { return Int(i) }
        if let d = try? c.decodeIfPresent(Double.self, forKey: key) { return Int(d) }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if let i = Int(t) { return i }
            if let d = Double(t) { return Int(d) }
        }
        return nil
    }

    static func decodeInt64<K: CodingKey>(_ c: KeyedDecodingContainer<K>, key: K) -> Int64? {
        if let i = try? c.decodeIfPresent(Int64.self, forKey: key) { return i }
        if let i = try? c.decodeIfPresent(Int.self, forKey: key) { return Int64(i) }
        if let d = try? c.decodeIfPresent(Double.self, forKey: key) { return Int64(d) }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if let i = Int64(t) { return i }
            if let d = Double(t) { return Int64(d) }
        }
        return nil
    }

    static func decodeIntArray<K: CodingKey>(_ c: KeyedDecodingContainer<K>, key: K) -> [Int]? {
        if let arr = try? c.decodeIfPresent([Int].self, forKey: key) { return arr }
        guard var unkeyed = try? c.nestedUnkeyedContainer(forKey: key) else { return nil }
        var result: [Int] = []
        while !unkeyed.isAtEnd {
            if let i = try? unkeyed.decode(Int.self) {
                result.append(i)
            } else if let s = try? unkeyed.decode(String.self), let i = Int(s) {
                result.append(i)
            } else {
                _ = try? unkeyed.decode(HealthJSONValue.self)
            }
        }
        return result
    }
}

/// 柔性 JSON 值，用于 `monitorData` / `dietSportData`
enum HealthJSONValue: Decodable, Equatable {
    case string(String)
    case int(Int64)
    case double(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let b = try? c.decode(Bool.self) { self = .bool(b); return }
        if let i = try? c.decode(Int64.self) { self = .int(i); return }
        if let d = try? c.decode(Double.self) { self = .double(d); return }
        if let s = try? c.decode(String.self) { self = .string(s); return }
        self = .null
    }

    var stringValue: String? {
        switch self {
        case .string(let s): return s
        case .int(let i): return String(i)
        case .double(let d):
            if d.rounded() == d { return String(Int64(d)) }
            // 保留一位小数常见展示（bmi / 血糖）
            let formatted = String(format: "%g", d)
            return formatted
        case .bool(let b): return b ? "1" : "0"
        case .null: return nil
        }
    }
}

// MARK: - Display mapping

/// 首页体征卡展示模型
struct HealthMetricDisplayItem: Equatable {
    let cardType: Int
    let metricKey: String
    let label: String
    let value: String
    let unit: String
    let status: String
    let statusType: String
    let iconSF: String
    let iconUrl: String?
    /// 卡片背景图 URL；nil 时 Cell 使用本地 metric_*
    let backgroundUrl: String?
    let time: String
    let pageUrl: String?
    let routeKey: String
}

/// 首页快捷入口展示模型
struct HealthQuickEntryDisplayItem: Equatable {
    let name: String
    let iconUrl: String?
    let pageUrl: String
    let sortId: Int
}

enum MonitorCardDisplayMapper {

    static let maxVisibleCards = 6

    /// cardType：2血压 / 3血糖 / 4体温 / 5体重 / 10饮食运动
    static func metricKey(for cardType: Int?) -> String {
        switch cardType {
        case 2: return "blood-pressure"
        case 3: return "blood-sugar"
        case 4: return "temperature"
        case 5: return "weight"
        case 10: return "exercise"
        default: return "blood-pressure"
        }
    }

    /// 优先从 `FundeH5:/xxx` 解析 key，否则回退 cardType
    static func metricKey(cardType: Int?, pageUrl: String?) -> String {
        if let fromPage = metricKey(fromPageUrl: pageUrl) {
            return fromPage
        }
        return metricKey(for: cardType)
    }

    static func metricKey(fromPageUrl pageUrl: String?) -> String? {
        guard let pageUrl else { return nil }
        let trimmed = pageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        let path: String
        if trimmed.hasPrefix("FundeH5:/") {
            path = String(trimmed.dropFirst("FundeH5:/".count))
        } else if trimmed.hasPrefix("/health/metrics/") {
            path = String(trimmed.dropFirst("/health/metrics/".count))
        } else {
            return nil
        }
        let key = path.split(separator: "/").first.map(String.init) ?? path
        switch key {
        case "exercise-food": return "exercise"
        case "temperature", "blood-pressure", "blood-sugar", "weight",
             "heart-rate", "sleep", "ecg", "fundus", "exercise", "spo2", "digestive":
            return key
        default:
            return key.isEmpty ? nil : key
        }
    }

    /// `FundeH5:/blood-pressure` → `/health/metrics/blood-pressure`
    static func appRoute(from pageUrl: String?, cardType: Int?) -> String {
        if let key = metricKey(fromPageUrl: pageUrl) {
            return "/health/metrics/\(key)"
        }
        if let pageUrl {
            let t = pageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.hasPrefix("/") { return t }
        }
        return fallbackRoute(for: cardType)
    }

    static func iconSF(for metricKey: String) -> String {
        switch metricKey {
        case "blood-pressure": return "heart.fill"
        case "blood-sugar": return "drop.fill"
        case "weight": return "scalemass.fill"
        case "temperature": return "thermometer.medium"
        case "heart-rate": return "waveform.path.ecg"
        case "sleep": return "moon.fill"
        case "ecg": return "waveform.path.ecg"
        case "fundus": return "eye.fill"
        case "exercise": return "figure.walk"
        case "spo2": return "lungs.fill"
        case "digestive": return "cross.case.fill"
        default: return "heart.text.square.fill"
        }
    }

    static func fallbackRoute(for cardType: Int?) -> String {
        let key = metricKey(for: cardType)
        return "/health/metrics/\(key)"
    }

    static func fromMonitorCards(_ cards: [MonitorHealthCardVO]) -> [HealthMetricDisplayItem] {
        cards.compactMap { card in
            guard let type = card.cardType else { return nil }
            let key = metricKey(cardType: type, pageUrl: card.pageUrl)
            let mapped = extractValueUnit(from: card)
            let time = formatTime(card.monitorTime, scene: card.monitorTimeType)
            let status = (card.result ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let name = (card.cardName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return HealthMetricDisplayItem(
                cardType: type,
                metricKey: key,
                label: name.isEmpty ? defaultLabel(for: key) : name,
                value: mapped.value,
                unit: mapped.unit,
                status: status.isEmpty ? (mapped.value == "--" ? "" : "正常") : status,
                statusType: statusType(for: card.resultType, hasValue: mapped.value != "--"),
                iconSF: iconSF(for: key),
                iconUrl: nonempty(card.iconUrl),
                backgroundUrl: nonempty(card.backgroundUrl),
                time: time,
                pageUrl: nonempty(card.pageUrl),
                routeKey: key
            )
        }
    }

    static func fromCmsMeta(_ meta: [MonitorCardMetaVO]) -> [HealthMetricDisplayItem] {
        meta
            .sorted { ($0.sortId ?? Int.max) < ($1.sortId ?? Int.max) }
            .compactMap { item in
                guard let type = item.cardType else { return nil }
                let key = metricKey(cardType: type, pageUrl: item.pageUrl)
                let name = (item.cardName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                return HealthMetricDisplayItem(
                    cardType: type,
                    metricKey: key,
                    label: name.isEmpty ? defaultLabel(for: key) : name,
                    value: "--",
                    unit: "",
                    status: "",
                    statusType: "success",
                    iconSF: iconSF(for: key),
                    iconUrl: nonempty(item.iconUrl),
                    backgroundUrl: nil,
                    time: "",
                    pageUrl: nonempty(item.pageUrl),
                    routeKey: key
                )
            }
    }

    static func quickEntries(from list: [HealthQuickEntryVO]?) -> [HealthQuickEntryDisplayItem] {
        (list ?? [])
            .compactMap { e -> HealthQuickEntryDisplayItem? in
                let name = (e.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let url = (e.pageUrl ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty, !url.isEmpty else { return nil }
                return HealthQuickEntryDisplayItem(
                    name: name,
                    iconUrl: nonempty(e.iconUrl),
                    pageUrl: url,
                    sortId: e.sortId ?? 0
                )
            }
            .sorted { $0.sortId < $1.sortId }
    }

    // MARK: Private helpers

    private static func defaultLabel(for key: String) -> String {
        H5Config.metricTitle(for: key)
    }

    private static func nonempty(_ s: String?) -> String? {
        let t = (s ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private static func statusType(for resultType: Int?, hasValue: Bool) -> String {
        guard hasValue else { return "success" }
        switch resultType {
        case 2, 3: return "warning"
        case 4: return "info"
        default: return "success"
        }
    }

    private static func formatTime(_ ms: Int64?, scene: String?) -> String {
        let sceneText = (scene ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let ms, ms > 0 else { return sceneText }
        let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
        let cal = Calendar.current
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        if cal.isDateInToday(date) {
            f.dateFormat = "HH:mm"
            let t = "今天 \(f.string(from: date))"
            return sceneText.isEmpty ? t : "\(t) · \(sceneText)"
        }
        if cal.isDateInYesterday(date) {
            f.dateFormat = "HH:mm"
            let t = "昨天 \(f.string(from: date))"
            return sceneText.isEmpty ? t : "\(t) · \(sceneText)"
        }
        f.dateFormat = "MM/dd HH:mm"
        let t = f.string(from: date)
        return sceneText.isEmpty ? t : "\(t) · \(sceneText)"
    }

    private static func extractValueUnit(from card: MonitorHealthCardVO) -> (value: String, unit: String) {
        let data = card.monitorData ?? [:]
        let diet = card.dietSportData ?? [:]

        // 血压：highBloodPressure / lowBloodPressure
        if let sys = string(in: data, keys: ["highBloodPressure", "systolic", "sbp", "high"]),
           let dia = string(in: data, keys: ["lowBloodPressure", "diastolic", "dbp", "low"]) {
            let unit = string(in: data, keys: ["unit"]) ?? "mmHg"
            return ("\(sys)/\(dia)", unit)
        }

        // 体重
        if let w = string(in: data, keys: ["weight"]) {
            let unit = string(in: data, keys: ["unit"]) ?? "kg"
            return (w, unit)
        }

        // 体温
        if let t = string(in: data, keys: ["temperature", "temp"]) {
            let unit = string(in: data, keys: ["unit"]) ?? "℃"
            return (t, unit)
        }

        // 通用 value（血糖等）
        if let v = string(in: data, keys: ["value", "monitorValue", "resultValue", "dataValue"]) {
            let unit = string(in: data, keys: ["unit", "monitorUnit"]) ?? ""
            return (v, unit)
        }

        // 饮食运动
        if let steps = string(in: diet, keys: ["steps", "step", "sportSteps"]) {
            return (steps, "步")
        }
        if let v = string(in: diet, keys: ["value", "calorie", "calories"]) {
            let unit = string(in: diet, keys: ["unit"]) ?? ""
            return (v, unit)
        }

        return ("--", "")
    }

    private static func string(in dict: [String: HealthJSONValue], keys: [String]) -> String? {
        for k in keys {
            if let s = dict[k]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                return s
            }
        }
        return nil
    }
}
