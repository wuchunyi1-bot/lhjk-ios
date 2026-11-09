import Foundation

/// C 端活动列表角标。与详情 `status` 同一套：1 待开始、2 进行中、3 已结束、4 已提交并评价。
enum MemberActivityBadge: Int {
    case pending = 1
    case ongoing = 2
    case ended = 3
    case submitted = 4

    var isListVisible: Bool {
        switch self {
        case .ongoing, .ended, .submitted: return true
        case .pending: return false
        }
    }

    var title: String {
        self == .ongoing ? "进行中" : "已结束"
    }

    /// 进行中在前，已结束与已提交并评价同组在后。
    var sortRank: Int {
        self == .ongoing ? 0 : 1
    }

    var isOngoing: Bool { self == .ongoing }
}

/// `GET /v1/memberActivity/client/listMyActivitiesForClient` 列表行。
struct MemberActivityClientListVO: Decodable {
    let activityId: String
    let theme: String
    let startTime: String
    let endTime: String
    let ourLeaderName: String
    let clientBadgeCode: Int?
    /// 是否可进入详情。结束满 2 小时后为 false，与详情接口时间窗一致。
    let detailAccessible: Bool

    enum CodingKeys: String, CodingKey {
        case activityId
        case theme
        case startTime
        case endTime
        case ourLeaderName
        case clientBadgeCode
        case detailAccessible
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        activityId = Self.decodeFlexibleString(c, key: .activityId) ?? ""
        theme = (try c.decodeIfPresent(String.self, forKey: .theme) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        startTime = try c.decodeIfPresent(String.self, forKey: .startTime) ?? ""
        endTime = try c.decodeIfPresent(String.self, forKey: .endTime) ?? ""
        ourLeaderName = (try c.decodeIfPresent(String.self, forKey: .ourLeaderName) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        clientBadgeCode = Self.decodeFlexibleInt(c, key: .clientBadgeCode)
        detailAccessible = try c.decodeIfPresent(Bool.self, forKey: .detailAccessible) ?? false
    }

    var badge: MemberActivityBadge? {
        guard let clientBadgeCode else { return nil }
        return MemberActivityBadge(rawValue: clientBadgeCode)
    }
}

/// `clientDetectionItems` 单项。`pageUrl` 与健康首页同类型卡片一致。
struct MemberActivityClientDetectionItemVO: Decodable {
    /// 15 鹰瞳、16 炎症仪、17 炎菌仪。
    let clientDetectionTypeCode: Int?
    let pageUrl: String
    let description: String

    enum CodingKeys: String, CodingKey {
        case clientDetectionTypeCode
        case pageUrl
        case description
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        clientDetectionTypeCode = MemberActivityClientListVO.decodeFlexibleInt(c, key: .clientDetectionTypeCode)
        pageUrl = (try c.decodeIfPresent(String.self, forKey: .pageUrl) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        description = (try c.decodeIfPresent(String.self, forKey: .description) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// `GET /v1/memberActivity/client/getDetailForClient` 活动详情。
struct MemberActivityDetailVO: Decodable {
    let activityId: String
    let theme: String
    let startTime: String
    let endTime: String
    let ourLeaderName: String
    /// C 端设备检测入口。无绑定时为空。
    let clientDetectionItems: [MemberActivityClientDetectionItemVO]

    enum CodingKeys: String, CodingKey {
        case activityId
        case theme
        case startTime
        case endTime
        case ourLeaderName
        case clientDetectionItems
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        activityId = Self.decodeFlexibleString(c, key: .activityId) ?? ""
        theme = (try c.decodeIfPresent(String.self, forKey: .theme) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        startTime = try c.decodeIfPresent(String.self, forKey: .startTime) ?? ""
        endTime = try c.decodeIfPresent(String.self, forKey: .endTime) ?? ""
        ourLeaderName = (try c.decodeIfPresent(String.self, forKey: .ourLeaderName) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        clientDetectionItems = try c.decodeIfPresent(
            [MemberActivityClientDetectionItemVO].self,
            forKey: .clientDetectionItems
        ) ?? []
    }
}

enum MemberActivityDisplay {

    /// `2026-10-27 9:30-11:30`。日期取开始日，时刻去掉秒，小时不补前导零。
    static func timeText(startTime: String, endTime: String) -> String {
        guard let start = parse(startTime) else {
            let raw = startTime.trimmingCharacters(in: .whitespacesAndNewlines)
            return raw.isEmpty ? "—" : raw
        }
        let day = dayFormatter.string(from: start)
        let startClock = clockFormatter.string(from: start)
        guard let end = parse(endTime) else {
            return "\(day) \(startClock)"
        }
        return "\(day) \(startClock)-\(clockFormatter.string(from: end))"
    }

    /// 按接口返回顺序去重。同一 `clientDetectionTypeCode` 只保留第一项。
    static func deviceEntries(from items: [MemberActivityClientDetectionItemVO]) -> [MyActivityDeviceEntry] {
        var seen = Set<Int>()
        var entries: [MyActivityDeviceEntry] = []
        for item in items {
            if let code = item.clientDetectionTypeCode, !seen.insert(code).inserted { continue }
            guard let entry = MyActivityDeviceEntry(item: item) else { continue }
            entries.append(entry)
        }
        return entries
    }

    /// 打开检测页时带上当前活动，检测页据此同时提供扫一扫和选择设备 SN。
    static func pageURL(_ pageUrl: String, activityId: String) -> String {
        let trimmed = pageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = activityId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !id.isEmpty, !trimmed.contains("activityId=") else { return trimmed }
        let separator = trimmed.contains("?") ? "&" : "?"
        return "\(trimmed)\(separator)activityId=\(id)"
    }

    private static func parse(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return timestampFormatter.date(from: trimmed)
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "H:mm"
        return formatter
    }()
}

/// 活动详情里的一个设备检测入口。
struct MyActivityDeviceEntry: Hashable {
    let id: String
    let name: String
    /// CMS `pageUrl`，与健康首页同类型卡片一致。
    let pageUrl: String
    /// `pageUrl` 打不开时的本地路由。
    let fallbackRoute: String?
    let symbolName: String

    init?(item: MemberActivityClientDetectionItemVO) {
        let known = Self.knownType(item.clientDetectionTypeCode)
        let name = item.description.isEmpty ? (known?.name ?? "") : item.description
        guard !name.isEmpty || !item.pageUrl.isEmpty else { return nil }
        id = item.clientDetectionTypeCode.map(String.init) ?? item.pageUrl
        self.name = name.isEmpty ? "设备检测" : name
        pageUrl = item.pageUrl
        fallbackRoute = known?.route
        symbolName = known?.symbolName ?? "waveform.path.ecg"
    }

    private static func knownType(_ code: Int?) -> (name: String, route: String, symbolName: String)? {
        switch code {
        case 15:
            return ("鹰瞳眼底检测", "/health/metrics/fundus", "eye")
        case 16:
            return ("呼吸道炎症仪检测", "/health/metrics/respiratory-inflammation", "waveform.path.ecg")
        case 17:
            return ("消化道菌群失衡检测", "/health/metrics/gut-flora", "circle.hexagongrid")
        default:
            return nil
        }
    }
}

private extension MemberActivityClientListVO {
    static func decodeFlexibleString<K: CodingKey>(
        _ c: KeyedDecodingContainer<K>,
        key: K
    ) -> String? {
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let n = try? c.decodeIfPresent(Int64.self, forKey: key) { return String(n) }
        if let n = try? c.decodeIfPresent(Int.self, forKey: key) { return String(n) }
        return nil
    }

    static func decodeFlexibleInt<K: CodingKey>(
        _ c: KeyedDecodingContainer<K>,
        key: K
    ) -> Int? {
        if let n = try? c.decodeIfPresent(Int.self, forKey: key) { return n }
        if let n = try? c.decodeIfPresent(Int64.self, forKey: key) { return Int(n) }
        if let s = try? c.decodeIfPresent(String.self, forKey: key),
           let n = Int(s.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return n
        }
        return nil
    }
}

private extension MemberActivityDetailVO {
    static func decodeFlexibleString<K: CodingKey>(
        _ c: KeyedDecodingContainer<K>,
        key: K
    ) -> String? {
        MemberActivityClientListVO.decodeFlexibleString(c, key: key)
    }
}
