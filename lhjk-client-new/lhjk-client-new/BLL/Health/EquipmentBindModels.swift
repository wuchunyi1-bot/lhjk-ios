import Foundation

// MARK: - 设备大类（Apifox `type` / `getEquipmenByApp.type`）

/// 监测设备大类字典值（与后端 `equipmentUser` / `getEquipmenByApp` 的 `type` 一致）
///
/// | type | 含义 |
/// |------|------|
/// | 2 | 血糖 |
/// | 3 | 体重 |
/// | 4 | 血压 |
/// | 5 | 体温 |
/// | 6 | 血氧 |
enum EquipmentCategoryType: Int {
    case bloodSugar = 2
    case weight = 3
    case bloodPressure = 4
    case temperature = 5
    case bloodOxygen = 6
}

// MARK: - 监测业务 / 采集方式

/// `MonitorDataVo.businessId`
enum MonitorBusinessId: Int {
    case fetalHeart = 1
    case bloodPressure = 2
    case bloodOxygen = 3
    case weight = 4
    case bloodSugar = 5
    case temperature = 6
    case jaundice = 7
}

/// `MonitorDataVo.collectionType`：1 手动 / 2 蓝牙 / 3 医用设备
enum MonitorCollectionType: Int {
    case manual = 1
    case bluetooth = 2
    case medicalDevice = 3
}

// MARK: - 用户绑定设备

/// `GET /v1/equipmentUser/getEquipmentUserByParam` / `getEquipmentByOne` → `EquipmentUserVo`
struct EquipmentUserVO: Decodable {
    let id: String?
    let name: String?
    let imgUrl: String?
    let type: Int?
    let model: String?
    let connectionMethod: Int?
    let application: String?
    let battery: String?
    let supplier: Int?
    let verify: Int?
    let bluetoothName: String?
    let contentId: String?
    let status: Int?
    let description: String?
    let deviceId: String?
    let mac: String?
    let equipmentTypeId: String?
    let commodityName: String?
    let equipmentId: String?
    let bindingTime: String?

    private enum CodingKeys: String, CodingKey {
        case id, name, imgUrl, type, model, connectionMethod, application, battery
        case supplier, verify, bluetoothName, contentId, status, description
        case deviceId, mac, equipmentTypeId, commodityName, equipmentId, bindingTime
        case macAddress, equipmentMac
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.decodeFlexibleString(c, key: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        imgUrl = try c.decodeIfPresent(String.self, forKey: .imgUrl)
        type = Self.decodeFlexibleInt(c, key: .type)
        model = try c.decodeIfPresent(String.self, forKey: .model)
        connectionMethod = Self.decodeFlexibleInt(c, key: .connectionMethod)
        application = try c.decodeIfPresent(String.self, forKey: .application)
        battery = try c.decodeIfPresent(String.self, forKey: .battery)
        supplier = Self.decodeFlexibleInt(c, key: .supplier)
        verify = Self.decodeFlexibleInt(c, key: .verify)
        bluetoothName = try c.decodeIfPresent(String.self, forKey: .bluetoothName)
        contentId = Self.decodeFlexibleString(c, key: .contentId)
        status = Self.decodeFlexibleInt(c, key: .status)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        deviceId = try c.decodeIfPresent(String.self, forKey: .deviceId)
        mac = Self.decodeFlexibleString(c, key: .mac)
            ?? Self.decodeFlexibleString(c, key: .macAddress)
            ?? Self.decodeFlexibleString(c, key: .equipmentMac)
        equipmentTypeId = Self.decodeFlexibleString(c, key: .equipmentTypeId)
        commodityName = try c.decodeIfPresent(String.self, forKey: .commodityName)
        equipmentId = Self.decodeFlexibleString(c, key: .equipmentId)
        bindingTime = try c.decodeIfPresent(String.self, forKey: .bindingTime)
    }

    private static func decodeFlexibleString<K: CodingKey>(
        _ c: KeyedDecodingContainer<K>,
        key: K
    ) -> String? {
        if let s = try? c.decodeIfPresent(String.self, forKey: key) { return s }
        if let n = try? c.decodeIfPresent(Int64.self, forKey: key) { return String(n) }
        if let n = try? c.decodeIfPresent(Int.self, forKey: key) { return String(n) }
        return nil
    }

    private static func decodeFlexibleInt<K: CodingKey>(
        _ c: KeyedDecodingContainer<K>,
        key: K
    ) -> Int? {
        if let n = try? c.decodeIfPresent(Int.self, forKey: key) { return n }
        if let s = try? c.decodeIfPresent(String.self, forKey: key),
           let n = Int(s.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return n
        }
        return nil
    }
}

/// 标准分页 — 用户绑定设备列表
struct PaginatedEquipmentUserData: Decodable {
    let totalRecords: Int?
    let pageSize: Int?
    let totalPages: Int?
    let currentPage: Int?
    let records: [EquipmentUserVO]?

    private enum CodingKeys: String, CodingKey {
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

    init(
        totalRecords: Int? = nil,
        pageSize: Int? = nil,
        totalPages: Int? = nil,
        currentPage: Int? = nil,
        records: [EquipmentUserVO]? = nil
    ) {
        self.totalRecords = totalRecords
        self.pageSize = pageSize
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.records = records
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalRecords = (try? c.decodeIfPresent(Int.self, forKey: .totalRecords))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .totalRecordsCN))
        pageSize = (try? c.decodeIfPresent(Int.self, forKey: .pageSize))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .pageSizeCN))
        totalPages = (try? c.decodeIfPresent(Int.self, forKey: .totalPages))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .totalPagesCN))
        currentPage = (try? c.decodeIfPresent(Int.self, forKey: .currentPage))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .currentPageCN))
        records = (try? c.decodeIfPresent([EquipmentUserVO].self, forKey: .records))
            ?? (try? c.decodeIfPresent([EquipmentUserVO].self, forKey: .recordsCN))
    }

    static let empty = PaginatedEquipmentUserData(records: [])
}

// MARK: - App 可连接设备型号

/// `POST /v1/equipment/getEquipmenByApp` → `EquipmentBo`
struct EquipmentCatalogItemVO: Decodable {
    let id: String
    let name: String?
    let imgUrl: String?
    let type: Int?
    let model: String?
    let connectionMethod: Int?
    let application: String?
    let battery: String?
    let supplier: Int?
    let verify: Int?
    let bluetoothName: String?
    let contentId: String?
    let status: Int?
    let description: String?

    private enum CodingKeys: String, CodingKey {
        case id, name, imgUrl, type, model, connectionMethod, application, battery
        case supplier, verify, bluetoothName, contentId, status, description
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try? c.decode(String.self, forKey: .id) {
            id = s
        } else if let n = try? c.decode(Int64.self, forKey: .id) {
            id = String(n)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: c, debugDescription: "missing equipment id")
        }
        name = try c.decodeIfPresent(String.self, forKey: .name)
        imgUrl = try c.decodeIfPresent(String.self, forKey: .imgUrl)
        type = try c.decodeIfPresent(Int.self, forKey: .type)
        model = try c.decodeIfPresent(String.self, forKey: .model)
        connectionMethod = try c.decodeIfPresent(Int.self, forKey: .connectionMethod)
        application = try c.decodeIfPresent(String.self, forKey: .application)
        battery = try c.decodeIfPresent(String.self, forKey: .battery)
        supplier = try c.decodeIfPresent(Int.self, forKey: .supplier)
        verify = try c.decodeIfPresent(Int.self, forKey: .verify)
        bluetoothName = try c.decodeIfPresent(String.self, forKey: .bluetoothName)
        if let s = try? c.decodeIfPresent(String.self, forKey: .contentId) {
            contentId = s
        } else if let n = try? c.decodeIfPresent(Int64.self, forKey: .contentId) {
            contentId = String(n)
        } else {
            contentId = nil
        }
        status = try c.decodeIfPresent(Int.self, forKey: .status)
        description = try c.decodeIfPresent(String.self, forKey: .description)
    }

    /// 可绑定：`status` 为空或非 0（0 为停用）
    var isBindable: Bool {
        guard let status else { return true }
        return status != 0
    }
}

struct PaginatedEquipmentCatalogData: Decodable {
    let totalRecords: Int?
    let pageSize: Int?
    let totalPages: Int?
    let currentPage: Int?
    let records: [EquipmentCatalogItemVO]?

    private enum CodingKeys: String, CodingKey {
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

    init(
        totalRecords: Int? = nil,
        pageSize: Int? = nil,
        totalPages: Int? = nil,
        currentPage: Int? = nil,
        records: [EquipmentCatalogItemVO]? = nil
    ) {
        self.totalRecords = totalRecords
        self.pageSize = pageSize
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.records = records
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalRecords = (try? c.decodeIfPresent(Int.self, forKey: .totalRecords))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .totalRecordsCN))
        pageSize = (try? c.decodeIfPresent(Int.self, forKey: .pageSize))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .pageSizeCN))
        totalPages = (try? c.decodeIfPresent(Int.self, forKey: .totalPages))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .totalPagesCN))
        currentPage = (try? c.decodeIfPresent(Int.self, forKey: .currentPage))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .currentPageCN))
        records = (try? c.decodeIfPresent([EquipmentCatalogItemVO].self, forKey: .records))
            ?? (try? c.decodeIfPresent([EquipmentCatalogItemVO].self, forKey: .recordsCN))
    }

    static let empty = PaginatedEquipmentCatalogData(records: [])
}

/// `GET /v1/equipmentUser/checkEquipmentBind`：`isSuccess == true` 表示已经绑定
struct EquipmentBindCheckResult {
    let isAlreadyBound: Bool
    let message: String?
}

// MARK: - 绑定 / 校验

/// `POST /v1/equipmentUser/bindEquipment`
struct BindEquipmentRequest: Encodable {
    var orderId: Int64?
    var businessId: Int?
    var packageType: Int?
    var commodityId: Int64?
    var userId: Int64?
    /// 型号主键（`getEquipmenByApp.id` / 字典 equipmentType）
    var equipmentType: Int64?
    var equipmentId: Int64?
    var deviceId: String?
    var bluetoothName: String?
    var mac: String?
}

// MARK: - 固件

struct FirmwareCheckQuery: Encodable {
    let name: String?
    let model: String?
    let devmodelSn: String?
    let battery: String?
    let versionCode: String?

    func asParameters() -> [String: Any] {
        var params: [String: Any] = [:]
        if let name, !name.isEmpty { params["name"] = name }
        if let model, !model.isEmpty { params["model"] = model }
        if let devmodelSn, !devmodelSn.isEmpty { params["devmodelSn"] = devmodelSn }
        if let battery, !battery.isEmpty { params["battery"] = battery }
        if let versionCode, !versionCode.isEmpty { params["versionCode"] = versionCode }
        return params
    }
}

/// `GET /v1/firmware/getFirmwareUrlByParam` → `data`（字段以运行时为准）
struct FirmwareUpgradeInfoVO: Decodable {
    let url: String?
    let versionCode: String?

    private enum CodingKeys: String, CodingKey {
        case url, versionCode, firmwareUrl, upgradeUrl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        url = (try? c.decodeIfPresent(String.self, forKey: .url))
            ?? (try? c.decodeIfPresent(String.self, forKey: .firmwareUrl))
            ?? (try? c.decodeIfPresent(String.self, forKey: .upgradeUrl))
        versionCode = try c.decodeIfPresent(String.self, forKey: .versionCode)
    }
}

// MARK: - 监测上报

/// `POST /v1/monitor/saveOrUpdateMonitorData` 请求体（通用壳）
struct SaveMonitorDataRequest: Encodable {
    let beginTime: String
    let endTime: String
    let businessId: Int
    let collectionType: Int
    let version: String
    let equipmentMac: String?
    let equipmentName: String?
    let serialNumber: String?
    let type: String?
    let monitorData: MonitorDataPayload

    struct MonitorDataPayload: Encodable {
        let data: [String: SaveMonitorJSONValue]
    }
}

/// 监测保存响应 — 提取 `monitorId`（兼容 `id`、嵌套 `monitorData`、以及 data 直接为数字/字符串）
struct SaveMonitorDataResultVO: Decodable {
    let monitorId: String?

    private enum CodingKeys: String, CodingKey {
        case monitorId
        case monitorData
        case id
    }

    init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer() {
            if let s = try? single.decode(String.self), !s.isEmpty {
                monitorId = s
                return
            }
            if let n = try? single.decode(Int64.self) {
                monitorId = String(n)
                return
            }
        }

        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let top = Self.decodeMonitorId(c, key: .monitorId) {
            monitorId = top
            return
        }
        if let top = Self.decodeMonitorId(c, key: .id) {
            monitorId = top
            return
        }
        if let nested = try c.decodeIfPresent(MonitorDataNested.self, forKey: .monitorData) {
            monitorId = nested.monitorId
            return
        }
        monitorId = nil
    }

    private struct MonitorDataNested: Decodable {
        let monitorId: String?

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            monitorId = SaveMonitorDataResultVO.decodeMonitorId(c, key: .monitorId)
                ?? SaveMonitorDataResultVO.decodeMonitorId(c, key: .id)
        }

        private enum CodingKeys: String, CodingKey {
            case monitorId
            case id
        }
    }

    private static func decodeMonitorId<K: CodingKey>(
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
}

/// 体重蓝牙监测 `monitorData.data` 字段构建
struct WeightBluetoothMonitorData {
    let recordTimeMs: Int64
    let weightKg: Double
    let bmi: Double?
    let bodyFatScaleMonitor: Bool
    let bodyFat: Int?
    let muscle: Int?
    let bodyWater: Int?
    let basalMetabolism: Int?
    let fatVolume: Int?
    let bone: Int?

    func asDictionary() -> [String: SaveMonitorJSONValue] {
        var data: [String: SaveMonitorJSONValue] = [
            "recordTime": .string(String(recordTimeMs)),
            "weight": .string(Self.formatWeight(weightKg)),
            "bodyFatScaleMonitor": .int(bodyFatScaleMonitor ? 1 : 0),
        ]
        if let bmi {
            data["bmi"] = .string(String(format: "%.1f", bmi))
        }
        if let bodyFat { data["bodyFat"] = .int(bodyFat) }
        if let muscle { data["muscle"] = .int(muscle) }
        if let bodyWater { data["bodyWater"] = .int(bodyWater) }
        if let basalMetabolism { data["basalMetabolism"] = .int(basalMetabolism) }
        if let fatVolume { data["fatVolume"] = .int(fatVolume) }
        if let bone { data["bone"] = .int(bone) }
        return data
    }

    private static func formatWeight(_ kg: Double) -> String {
        let hundredths = (kg * 100).rounded() / 100
        let tenths = (kg * 10).rounded() / 10
        if abs(hundredths - tenths) < 0.001 {
            return String(format: "%.1f", tenths)
        }
        return String(format: "%.2f", hundredths)
    }
}

enum SaveMonitorJSONValue: Encodable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        }
    }
}
