import Foundation

/// 门店营业时段。`tradeStartTime` / `tradeEndTime` 组成 `09:00-19:00`。
enum CabinHours {
    static func range(start: String?, end: String?) -> String? {
        guard let start = clock(start), let end = clock(end) else { return nil }
        return "\(start)-\(end)"
    }

    /// 列表和门店详情：周几在时段前，例如 `周一至周五 09:00-19:00`。没有合法 `tradeWeek` 时只返回时段。
    static func display(week: String?, start: String?, end: String?) -> String? {
        guard let range = range(start: start, end: end) else { return nil }
        guard let weekText = weekdays(week) else { return range }
        return "\(weekText) \(range)"
    }

    /// `tradeWeek`：1–7 表示周一到周日，逗号分隔。连续天用「至」，断开用「、」。
    static func weekdays(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let days = Array(Set(raw.split { !$0.isNumber }.compactMap { Int($0) }.filter { (1...7).contains($0) })).sorted()
        guard !days.isEmpty else { return nil }
        let names = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        var groups: [[Int]] = []
        for day in days {
            if let last = groups.last, last.last == day - 1 {
                groups[groups.count - 1].append(day)
            } else {
                groups.append([day])
            }
        }
        return groups.map { group in
            let first = names[group[0] - 1]
            guard group.count > 1, let end = group.last else { return first }
            return "\(first)至\(names[end - 1])"
        }.joined(separator: "、")
    }

    /// 已经是时段的旧文案可以展示。`yyyy-MM-dd` 开业日期不当成营业时间。
    static func period(_ raw: String?) -> String? {
        guard let text = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        if text.range(of: #"\d{4}-\d{2}-\d{2}"#, options: .regularExpression) != nil { return nil }
        return text
    }

    private static func clock(_ raw: String?) -> String? {
        guard let text = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        let parts = text.split(separator: ":").map(String.init)
        guard parts.count >= 2,
              parts[0].allSatisfy(\.isNumber),
              parts[1].allSatisfy(\.isNumber) else { return nil }
        return "\(parts[0]):\(parts[1])"
    }
}

// MARK: - 康养小屋列表
// Apifox: GET /v1/cabin/list
// https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529266269e0.md

struct PaginatedCabinListData: Decodable {
    let totalRecords: Int?
    let pageSize: Int?
    let totalPages: Int?
    let currentPage: Int?
    let records: [CabinStoreVO]?

    enum CodingKeys: String, CodingKey {
        case totalRecords = "totalCount"
        case pageSize
        case totalPages = "totalPage"
        case currentPage = "currPage"
        case records = "list"
        case totalRecordsCN = "总记录数"
        case pageSizeCN = "每页记录数"
        case totalPagesCN = "总页数"
        case currentPageCN = "当前页数"
        case recordsCN = "数据集合"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalRecords = Self.int(c, .totalRecords) ?? Self.int(c, .totalRecordsCN)
        pageSize = Self.int(c, .pageSize) ?? Self.int(c, .pageSizeCN)
        totalPages = Self.int(c, .totalPages) ?? Self.int(c, .totalPagesCN)
        currentPage = Self.int(c, .currentPage) ?? Self.int(c, .currentPageCN)
        records = (try? c.decodeIfPresent([CabinStoreVO].self, forKey: .records))
            ?? (try? c.decodeIfPresent([CabinStoreVO].self, forKey: .recordsCN))
    }

    private static func int(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Int? {
        if let value = try? c.decodeIfPresent(Int.self, forKey: key) { return value }
        if let value = try? c.decodeIfPresent(Int64.self, forKey: key) { return Int(value) }
        if let value = try? c.decodeIfPresent(String.self, forKey: key) {
            return Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

struct CabinStoreVO: Decodable, Equatable {
    let id: String
    let name: String
    let province: String
    let city: String
    let area: String
    let address: String
    let serviceTags: [String]
    /// 1 仅限内部员工，0 否
    let internalOnly: Int
    /// 1 / true 时名称旁展示推荐标。当前公开文档未列出该字段，缺省不展示。
    let recommended: Bool
    /// 1 启用，0 禁用。禁用不可进门店
    let status: Int?
    /// 按营业周和营业时段判断，true 为休息中，不可进门店
    let restFlag: Bool
    let todayAvailableCount: Int?
    /// 与查询坐标的距离。接口未返回时，列表会用门店坐标补算。
    var distanceMeters: Int64?
    /// 开业日期。接口字段 `openTime`，形如 `2026-11-09 00:00:00`，不是营业时段。
    let openTime: String?
    /// 营业星期，1–7 表示周一到周日，逗号分隔。
    let tradeWeek: String?
    /// 营业开始，`HH:mm`
    let tradeStartTime: String?
    /// 营业结束，`HH:mm`
    let tradeEndTime: String?
    let mobile: String?
    let imgUrl: String?
    /// 门店轮播图，逗号分隔的图片地址
    let banner: String?
    let longitude: String?
    let latitude: String?

    var isEnterable: Bool { status != 0 && !restFlag }

    var distanceLabel: String? {
        Self.formatDistance(meters: distanceMeters)
    }

    /// 省市区 + 详细地址，不含距离
    var placeLine: String {
        Self.joinedAddress(province: province, city: city, area: area, address: address)
    }

    /// 营业时段，例如 `周一至周五 09:00-19:00`。不用 `openTime`。
    var businessHours: String? {
        CabinHours.display(week: tradeWeek, start: tradeStartTime, end: tradeEndTime)
    }

    var addressLine: String {
        let place = placeLine
        guard let distanceLabel, !place.contains("距离约") else { return place }
        if place.isEmpty { return "距离约\(distanceLabel)" }
        return "\(place) · 距离约\(distanceLabel)"
    }

    var galleryURLs: [URL] {
        let banners = CabinMedia.urls(from: banner)
        if !banners.isEmpty { return banners }
        return CabinMedia.urls(from: imgUrl)
    }

    var coordinate: (longitude: String, latitude: String)? {
        guard let longitude, let latitude, !longitude.isEmpty, !latitude.isEmpty else { return nil }
        return (longitude, latitude)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, province, city, area, address, serviceTags, internalOnly, status
        case todayAvailableCount, distanceMeters, openTime, mobile, imgUrl, banner, longitude, latitude
        case tradeWeek, tradeStartTime, tradeEndTime, restFlag
        case recommended
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.string(c, .id) ?? ""
        name = Self.string(c, .name) ?? ""
        province = Self.string(c, .province) ?? ""
        city = Self.string(c, .city) ?? ""
        area = Self.string(c, .area) ?? ""
        address = Self.string(c, .address) ?? ""
        serviceTags = (try? c.decodeIfPresent([String].self, forKey: .serviceTags)) ?? []
        internalOnly = Self.flag(c, .internalOnly) ? 1 : 0
        recommended = Self.flag(c, .recommended)
        status = Self.int(c, .status)
        restFlag = Self.flag(c, .restFlag)
        todayAvailableCount = Self.int(c, .todayAvailableCount)
        distanceMeters = Self.int64(c, .distanceMeters)
        openTime = Self.string(c, .openTime)
        tradeWeek = Self.string(c, .tradeWeek)
        tradeStartTime = Self.string(c, .tradeStartTime)
        tradeEndTime = Self.string(c, .tradeEndTime)
        mobile = Self.string(c, .mobile)
        imgUrl = Self.string(c, .imgUrl)
        banner = Self.string(c, .banner)
        longitude = Self.string(c, .longitude)
        latitude = Self.string(c, .latitude)
    }

    private static func joinedAddress(province: String, city: String, area: String, address: String) -> String {
        var region: [String] = []
        for part in [province, city, area] where !part.isEmpty && region.last != part {
            region.append(part)
        }
        let prefix = region.joined()
        if address.isEmpty { return prefix }
        if !prefix.isEmpty, address.hasPrefix(prefix) { return address }
        return prefix + address
    }

    private static func formatDistance(meters: Int64?) -> String? {
        guard let meters, meters >= 0 else { return nil }
        if meters < 1000 { return "\(meters)m" }
        return String(format: "%.1fkm", Double(meters) / 1000)
    }

    private static func string(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> String? {
        if let value = try? c.decode(String.self, forKey: key) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let value = try? c.decode(Int64.self, forKey: key) { return String(value) }
        if let value = try? c.decode(Int.self, forKey: key) { return String(value) }
        return nil
    }

    private static func int(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Int? {
        if let value = try? c.decode(Int.self, forKey: key) { return value }
        if let value = try? c.decode(Int64.self, forKey: key) { return Int(value) }
        if let value = try? c.decode(String.self, forKey: key) {
            return Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    private static func flag(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Bool {
        if let value = int(c, key) { return value == 1 }
        if let value = try? c.decode(Bool.self, forKey: key) { return value }
        return false
    }

    private static func int64(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Int64? {
        if let value = try? c.decode(Int64.self, forKey: key) { return value }
        if let value = try? c.decode(Int.self, forKey: key) { return Int64(value) }
        if let value = try? c.decode(String.self, forKey: key) {
            return Int64(value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

// MARK: - 门店详情：分类与项目
// GET /v1/cabin/categoryList 、 GET /v1/cabin/configList

struct CabinCategoryVO: Decodable, Equatable {
    let id: String
    let name: String
    let sortId: Int

    /// 活动报名走活动详情，其余走项目预约
    var isActivity: Bool { name.contains("活动") }

    private enum CodingKeys: String, CodingKey {
        case id, name, sortId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = CabinJSON.string(c, .id) ?? ""
        name = CabinJSON.string(c, .name) ?? ""
        sortId = CabinJSON.int(c, .sortId) ?? 0
    }
}

struct CabinConfigItemVO: Decodable, Equatable {
    let id: String
    let name: String
    let price: Double?
    /// 1 免费直接预约，2 需购买后预约
    let payType: Int?
    let duration: Int?
    let unitName: String?
    let categoryName: String?
    /// 导航图。列表封面只用这张，不用介绍图 `imgUrls`。
    private let navigateUrl: String?

    var coverURL: URL? { CabinMedia.urls(from: navigateUrl).first }

    var priceLabel: String? {
        if payType == 1 {
            return (categoryName?.contains("活动") == true) ? "免费报名" : "免费"
        }
        guard let price else { return nil }
        let number = Self.formatPrice(price)
        if let unitName, !unitName.isEmpty { return "¥\(number)/\(unitName)" }
        return "¥\(number)"
    }

    var durationLabel: String? {
        guard let duration, duration > 0 else { return nil }
        return "\(duration) 分钟"
    }

    /// 预约页底栏金额。预约详情接口没有价格，沿用项目列表的 price。
    var plainPrice: String? {
        guard let price else { return nil }
        return Self.formatPrice(price)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, price, payType, duration, unitName, categoryName, navigateUrl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = CabinJSON.string(c, .id) ?? ""
        name = CabinJSON.string(c, .name) ?? ""
        price = CabinJSON.double(c, .price)
        payType = CabinJSON.int(c, .payType)
        duration = CabinJSON.int(c, .duration)
        unitName = CabinJSON.string(c, .unitName)
        categoryName = CabinJSON.string(c, .categoryName)
        navigateUrl = CabinJSON.string(c, .navigateUrl)
    }

    private static func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}

enum CabinMedia {
    static func urls(from raw: String?) -> [URL] {
        guard let raw else { return [] }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        if trimmed.hasPrefix("[") {
            if let data = trimmed.data(using: .utf8),
               let values = try? JSONDecoder().decode([String].self, from: data) {
                return values.compactMap(url(from:))
            }
        }
        if trimmed.contains(",") {
            return trimmed.split(separator: ",").compactMap { url(from: String($0)) }
        }
        return url(from: trimmed).map { [$0] } ?? []
    }

    private static func url(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil { return url }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return encoded.flatMap { URL(string: $0) }
    }
}

enum CabinJSON {
    static func string<K: CodingKey>(_ c: KeyedDecodingContainer<K>, _ key: K) -> String? {
        if let value = try? c.decode(String.self, forKey: key) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let value = try? c.decode(Int64.self, forKey: key) { return String(value) }
        if let value = try? c.decode(Int.self, forKey: key) { return String(value) }
        return nil
    }

    static func int<K: CodingKey>(_ c: KeyedDecodingContainer<K>, _ key: K) -> Int? {
        if let value = try? c.decode(Int.self, forKey: key) { return value }
        if let value = try? c.decode(Int64.self, forKey: key) { return Int(value) }
        if let value = try? c.decode(String.self, forKey: key) {
            return Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    static func double<K: CodingKey>(_ c: KeyedDecodingContainer<K>, _ key: K) -> Double? {
        if let value = try? c.decode(Double.self, forKey: key) { return value }
        if let value = try? c.decode(Int.self, forKey: key) { return Double(value) }
        if let value = try? c.decode(String.self, forKey: key) {
            return Double(value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    static func bool<K: CodingKey>(_ c: KeyedDecodingContainer<K>, _ key: K) -> Bool? {
        if let value = try? c.decode(Bool.self, forKey: key) { return value }
        if let value = try? c.decode(Int.self, forKey: key) { return value != 0 }
        if let value = try? c.decode(String.self, forKey: key) {
            switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "1", "true", "yes": return true
            case "0", "false", "no": return false
            default: return nil
            }
        }
        return nil
    }
}

// MARK: - 预约限流
// GET /v1/cabin/bookLimitCheck

struct CabinBookLimitCheckVO: Decodable, Equatable {
    /// 0 可预约，1 当日名额已满，2 超每人每日，3 超每人每月。
    let limitType: Int
    let title: String?
    let message: String?

    var blocksBooking: Bool { limitType != 0 }

    var alertTitle: String {
        if let title, !title.isEmpty { return title }
        switch limitType {
        case 1: return "名额已经约满"
        case 2: return "今天不能再约"
        case 3: return "本月不能再约"
        default: return "暂时不能预约"
        }
    }

    var alertMessage: String {
        if let message, !message.isEmpty { return message }
        switch limitType {
        case 1: return "这个服务的可预约名额已经用完，暂时不能再预约。"
        case 2: return "您今天预约这个服务的次数已经用完，请明天再来。"
        case 3: return "您本月预约这个服务的次数已经用完，请下个月再来。"
        default: return "当前不可预约，请稍后再试。"
        }
    }

    enum CodingKeys: String, CodingKey {
        case limitType, title, msg
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        limitType = CabinJSON.int(container, .limitType) ?? 0
        title = CabinJSON.string(container, .title)
        message = CabinJSON.string(container, .msg)
    }
}

// MARK: - 预约页详情
// GET /v1/cabin/bookDetail

struct CabinBookDetailVO: Decodable, Equatable {
    let id: String
    let name: String
    /// 1 免费，2 消耗卡，3 付费预约
    let sourceType: Int?
    let availableQuantity: Int?
    /// 1 免费直接预约，2 需购买后预约
    let payType: Int?
    let duration: Int?
    let applicablePeople: String?
    let restrictedPeople: String?
    let description: String?
    let notice: String?
    /// yyyy-MM-dd
    let date: String?
    let bookDaysAhead: Int?
    let hospitalId: String?
    /// 付费预约关联套餐。
    let packageId: String?
    /// 付费项目金额。免费项目为空。
    let price: Double?
    private let imgUrls: String?
    let slots: [CabinSlotVO]

    var galleryURLs: [URL] { CabinMedia.urls(from: imgUrls) }

    var hasContent: Bool { !id.isEmpty || !name.isEmpty }

    /// 接口没给 sourceType 时，用 payType 兜底：需购买视为付费，其余视为免费。
    var billingSource: Int {
        if let sourceType, (1...3).contains(sourceType) { return sourceType }
        return payType == 2 ? 3 : 1
    }

    var durationText: String? {
        guard let duration, duration > 0 else { return nil }
        return "单次时长：\(duration) 分钟"
    }

    var plainPrice: String? {
        guard let price, price > 0 else { return nil }
        if price == floor(price) { return String(Int(price)) }
        return String(format: "%.2f", price)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, sourceType, availableQuantity, payType, duration
        case applicablePeople, restrictedPeople, description, notice, date
        case bookDaysAhead, hospitalId, packageId, price, imgUrls, slots
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = CabinJSON.string(c, .id) ?? ""
        name = CabinJSON.string(c, .name) ?? ""
        sourceType = CabinJSON.int(c, .sourceType)
        availableQuantity = CabinJSON.int(c, .availableQuantity)
        payType = CabinJSON.int(c, .payType)
        duration = CabinJSON.int(c, .duration)
        applicablePeople = CabinJSON.string(c, .applicablePeople)
        restrictedPeople = CabinJSON.string(c, .restrictedPeople)
        description = CabinJSON.string(c, .description)
        notice = CabinJSON.string(c, .notice)
        date = CabinJSON.string(c, .date)
        bookDaysAhead = CabinJSON.int(c, .bookDaysAhead)
        hospitalId = CabinJSON.string(c, .hospitalId)
        packageId = CabinJSON.string(c, .packageId)
        price = CabinJSON.double(c, .price)
        imgUrls = CabinJSON.string(c, .imgUrls)
        slots = (try? c.decodeIfPresent([CabinSlotVO].self, forKey: .slots)) ?? []
    }
}

struct CabinSlotVO: Decodable, Equatable {
    let bookable: Bool
    let bookedCount: Int
    let startTime: String
    let endTime: String
    /// 不限容量时为空
    let remainingCount: Int?

    var key: String { "\(startTime)|\(endTime)" }

    var isBookable: Bool {
        guard bookable else { return false }
        if let remainingCount { return remainingCount > 0 }
        return true
    }

    var timeText: String {
        if startTime.isEmpty { return endTime }
        if endTime.isEmpty { return startTime }
        return "\(startTime)-\(endTime)"
    }

    var statusText: String {
        if !isBookable { return "已约满" }
        if let remainingCount { return "已约\(bookedCount)/剩\(remainingCount)" }
        return "已约\(bookedCount)"
    }

    private enum CodingKeys: String, CodingKey {
        case bookable, bookedCount, startTime, endTime, remainingCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let remaining = CabinJSON.int(c, .remainingCount)
        if let flag = CabinJSON.bool(c, .bookable) {
            bookable = flag
        } else if let remaining {
            bookable = remaining > 0
        } else {
            bookable = true
        }
        bookedCount = CabinJSON.int(c, .bookedCount) ?? 0
        startTime = CabinJSON.string(c, .startTime) ?? ""
        endTime = CabinJSON.string(c, .endTime) ?? ""
        remainingCount = remaining
    }
}

/// 付费预约带到确认订单。页面不展示这些字段。支付成功后用订单 id 再提交预约。
struct CabinPaidBookContext: Equatable {
    let configId: String
    let reserveDate: String
    let startTime: String
    let endTime: String

    init(configId: String, reserveDate: String, startTime: String, endTime: String) {
        self.configId = configId
        self.reserveDate = reserveDate
        self.startTime = startTime
        self.endTime = endTime
    }

    func routeParams() -> [String: Any] {
        [
            "cabinConfigId": configId,
            "cabinReserveDate": reserveDate,
            "cabinStartTime": startTime,
            "cabinEndTime": endTime,
        ]
    }

    init?(routeParams params: [String: Any]) {
        guard let configId = Self.string(params["cabinConfigId"]),
              let reserveDate = Self.string(params["cabinReserveDate"]),
              let startTime = Self.string(params["cabinStartTime"]),
              let endTime = Self.string(params["cabinEndTime"]) else {
            return nil
        }
        self.configId = configId
        self.reserveDate = reserveDate
        self.startTime = startTime
        self.endTime = endTime
    }

    private static func string(_ value: Any?) -> String? {
        let raw: String?
        if let text = value as? String {
            raw = text
        } else if let number = value as? NSNumber {
            raw = number.stringValue
        } else {
            raw = nil
        }
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct CabinBookDay: Equatable {
    /// yyyy-MM-dd
    let id: String
    /// 今天 / 明天 / 周三
    let title: String
    /// 10/30
    let subtitle: String
}

// MARK: - 预约记录
// GET /v1/cabin/appointments

struct PaginatedCabinAppointmentData: Decodable {
    let totalRecords: Int?
    let pageSize: Int?
    let totalPages: Int?
    let currentPage: Int?
    let records: [CabinAppointmentVO]?

    init(
        totalRecords: Int?,
        pageSize: Int?,
        totalPages: Int?,
        currentPage: Int?,
        records: [CabinAppointmentVO]?
    ) {
        self.totalRecords = totalRecords
        self.pageSize = pageSize
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.records = records
    }

    enum CodingKeys: String, CodingKey {
        case totalRecords = "totalCount"
        case pageSize
        case totalPages = "totalPage"
        case currentPage = "currPage"
        case records = "list"
        case totalRecordsCN = "总记录数"
        case pageSizeCN = "每页记录数"
        case totalPagesCN = "总页数"
        case currentPageCN = "当前页数"
        case recordsCN = "数据集合"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalRecords = Self.int(c, .totalRecords) ?? Self.int(c, .totalRecordsCN)
        pageSize = Self.int(c, .pageSize) ?? Self.int(c, .pageSizeCN)
        totalPages = Self.int(c, .totalPages) ?? Self.int(c, .totalPagesCN)
        currentPage = Self.int(c, .currentPage) ?? Self.int(c, .currentPageCN)
        records = (try? c.decodeIfPresent([CabinAppointmentVO].self, forKey: .records))
            ?? (try? c.decodeIfPresent([CabinAppointmentVO].self, forKey: .recordsCN))
    }

    private static func int(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Int? {
        if let value = try? c.decodeIfPresent(Int.self, forKey: key) { return value }
        if let value = try? c.decodeIfPresent(Int64.self, forKey: key) { return Int(value) }
        if let value = try? c.decodeIfPresent(String.self, forKey: key) {
            return Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

struct CabinAppointmentVO: Decodable, Equatable {
    let id: String
    let name: String
    let hospitalId: String
    let hospitalName: String
    let address: String
    /// 服务项目 id，不是项目配置 id
    let projectId: String
    /// 项目配置 id。再次预约用它打开原项目预约页。
    let configId: String
    let duration: Int?
    let reserveDate: String
    let startTime: String
    let endTime: String
    /// 3 待服务，4 服务中，5 已完成，6 已取消，7 已过期
    let status: Int?

    var statusTitle: String {
        switch status {
        case 3: return "待服务"
        case 4: return "服务中"
        case 5: return "已完成"
        case 6: return "已取消"
        case 7: return "已过期"
        default: return ""
        }
    }

    var durationText: String? {
        guard let duration, duration > 0 else { return nil }
        return "\(duration) 分钟"
    }

    var timeText: String {
        if startTime.isEmpty { return endTime }
        if endTime.isEmpty { return startTime }
        return "\(startTime)-\(endTime)"
    }

    /// 已完成、已取消、已过期可以再次预约。
    var canBookAgain: Bool {
        guard status == 5 || status == 6 || status == 7 else { return false }
        return !configId.isEmpty || !hospitalId.isEmpty
    }

    /// 待服务且已过当天时段。接口不返回说明文案。
    var overdueNotice: String? {
        guard status == 3, !reserveDate.isEmpty, !endTime.isEmpty else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        guard let end = formatter.date(from: "\(reserveDate) \(endTime)"),
              calendar.isDateInToday(end),
              end < Date() else { return nil }
        return "超时未使用，当天可以根据门店情况沟通核销，超过当天订单失效"
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, hospitalId, hospitalName, address, projectId, configId
        case duration, reserveDate, startTime, endTime, status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = CabinJSON.string(c, .id) ?? ""
        name = CabinJSON.string(c, .name) ?? ""
        hospitalId = CabinJSON.string(c, .hospitalId) ?? ""
        hospitalName = CabinJSON.string(c, .hospitalName) ?? ""
        address = CabinJSON.string(c, .address) ?? ""
        projectId = CabinJSON.string(c, .projectId) ?? ""
        configId = CabinJSON.string(c, .configId) ?? ""
        duration = CabinJSON.int(c, .duration)
        reserveDate = CabinJSON.string(c, .reserveDate) ?? ""
        startTime = CabinJSON.string(c, .startTime) ?? ""
        endTime = CabinJSON.string(c, .endTime) ?? ""
        status = CabinJSON.int(c, .status)
    }
}

/// 用户侧预约详情。GET /v1/cabin/reservationDetail
struct CabinReservationDetailVO: Decodable, Equatable {
    let id: String
    let name: String
    let status: Int?
    let hospitalId: String
    let hospitalName: String
    let address: String
    let mobile: String?
    /// 开业日期，不是营业时段。
    let openTime: String?
    let tradeWeek: String?
    let tradeStartTime: String?
    let tradeEndTime: String?
    let duration: Int?
    let reserveDate: String
    let startTime: String
    let endTime: String
    let quantity: Int?
    let reservationNumber: String?
    /// 核销码。待服务时展示。
    let cancellationCode: String?
    /// 服务端生成的核销二维码，png 的 base64。
    let qrCode: String?
    /// 项目介绍，富文本，介绍图写在正文里。
    let description: String?
    /// 服务分类，项目父级名称。
    let parentName: String?
    let notice: String?
    let applicablePeople: String?
    let restrictedPeople: String?
    let cancelReason: String?
    let cancelTime: String?
    /// 核销时间。服务中、已完成返回。
    let verifyTime: String?
    /// 完成时间。已完成返回。
    let finishTime: String?
    /// 过期时间。已过期返回。
    let expireTime: String?
    let createTime: String?
    /// 再次预约用。详情文档即将补上，缺省为空。
    let configId: String
    let longitude: String?
    let latitude: String?
    let contactName: String?
    let contactPhone: String?

    var statusTitle: String {
        switch status {
        case 1: return "待安排"
        case 2: return "待确认"
        case 3: return "待服务"
        case 4: return "服务中"
        case 5: return "已完成"
        case 6: return "已取消"
        case 7: return "已过期"
        default: return ""
        }
    }

    var durationText: String? {
        guard let duration, duration > 0 else { return nil }
        return "\(duration) 分钟"
    }

    var timeText: String {
        if startTime.isEmpty { return endTime }
        if endTime.isEmpty { return startTime }
        return "\(startTime)-\(endTime)"
    }

    var showsVerifyCode: Bool {
        guard status == 3 else { return false }
        if let cancellationCode, !cancellationCode.isEmpty { return true }
        if let qrCode, !qrCode.isEmpty { return true }
        return false
    }

    var coordinate: (longitude: String, latitude: String)? {
        guard let longitude, let latitude, !longitude.isEmpty, !latitude.isEmpty else { return nil }
        return (longitude, latitude)
    }

    /// 门店营业时段。有 `tradeWeek` 时拼在时段前，例如 `周一至周五 09:00-19:00`。
    var businessHours: String? {
        CabinHours.display(week: tradeWeek, start: tradeStartTime, end: tradeEndTime)
            ?? CabinHours.period(openTime)
    }

    var canCancel: Bool { status == 3 }

    var overdueNotice: String? {
        guard status == 3, !reserveDate.isEmpty, !endTime.isEmpty else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        guard let end = formatter.date(from: "\(reserveDate) \(endTime)"),
              calendar.isDateInToday(end),
              end < Date() else { return nil }
        return "超时未使用，当天可以根据门店情况沟通核销，超过当天订单失效"
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, status, hospitalId, hospitalName, address, mobile, openTime
        case tradeWeek, tradeStartTime, tradeEndTime
        case duration, reserveDate, startTime, endTime, quantity, reservationNumber
        case cancellationCode, qrCode, description, parentName, notice, applicablePeople, restrictedPeople
        case cancelReason, cancelTime, verifyTime, finishTime, expireTime, createTime
        case configId, longitude, latitude, contactName, contactPhone
        case lng, lat
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = CabinJSON.string(c, .id) ?? ""
        name = CabinJSON.string(c, .name) ?? ""
        status = CabinJSON.int(c, .status)
        hospitalId = CabinJSON.string(c, .hospitalId) ?? ""
        hospitalName = CabinJSON.string(c, .hospitalName) ?? ""
        address = CabinJSON.string(c, .address) ?? ""
        mobile = CabinJSON.string(c, .mobile)
        openTime = CabinJSON.string(c, .openTime)
        tradeWeek = CabinJSON.string(c, .tradeWeek)
        tradeStartTime = CabinJSON.string(c, .tradeStartTime)
        tradeEndTime = CabinJSON.string(c, .tradeEndTime)
        duration = CabinJSON.int(c, .duration)
        reserveDate = CabinJSON.string(c, .reserveDate) ?? ""
        startTime = CabinJSON.string(c, .startTime) ?? ""
        endTime = CabinJSON.string(c, .endTime) ?? ""
        quantity = CabinJSON.int(c, .quantity)
        reservationNumber = CabinJSON.string(c, .reservationNumber)
        cancellationCode = CabinJSON.string(c, .cancellationCode)
        qrCode = CabinJSON.string(c, .qrCode)
        description = CabinJSON.string(c, .description)
        parentName = CabinJSON.string(c, .parentName)
        notice = CabinJSON.string(c, .notice)
        applicablePeople = CabinJSON.string(c, .applicablePeople)
        restrictedPeople = CabinJSON.string(c, .restrictedPeople)
        cancelReason = CabinJSON.string(c, .cancelReason)
        cancelTime = CabinJSON.string(c, .cancelTime)
        verifyTime = CabinJSON.string(c, .verifyTime)
        finishTime = CabinJSON.string(c, .finishTime)
        expireTime = CabinJSON.string(c, .expireTime)
        createTime = CabinJSON.string(c, .createTime)
        configId = CabinJSON.string(c, .configId) ?? ""
        longitude = CabinJSON.string(c, .longitude) ?? CabinJSON.string(c, .lng)
        latitude = CabinJSON.string(c, .latitude) ?? CabinJSON.string(c, .lat)
        contactName = CabinJSON.string(c, .contactName)
        contactPhone = CabinJSON.string(c, .contactPhone)
    }
}
