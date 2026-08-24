import Foundation

/// 蓝牙设备绑定与监测上报 — BLL 封装
///
/// 对齐后端蓝牙连接流程图；**当前 Apifox 已发布 path** 如下（`App端/监测/设备绑定`、`监测/设备`、`监测/设备固件`、`监护/监测记录`）：
/// - `GET  /v1/equipmentUser/getEquipmentUserByParam`
/// - `GET  /v1/equipmentUser/getEquipmentByOne`
/// - `GET  /v1/equipment/getCompatibleBluetoothList`
/// - `POST /v1/equipment/getEquipmenByApp`
/// - `GET  /v1/equipmentUser/checkEquipmentVaild`（Apifox 拼写 Vaild）
/// - `GET  /v1/equipmentUser/checkEquipmentBind`
/// - `POST /v1/equipmentUser/bindEquipment`
/// - `GET  /v1/firmware/getFirmwareUrlByParam`
/// - `POST /v1/monitor/saveOrUpdateMonitorData`
/// - `POST /v1/monitor/getWeightHomePageData`
/// - `DELETE /v1/monitor/delMonitorDataByMonitorId`
/// - `DELETE /v1/equipmentUser/deleteEquipmentUserById`
///
/// 流程图中 `/v1/equipment/user/...`、`bindEquipmentByApp` 等新 path **Apifox 暂未发布**，接入时以联调环境为准。
final class EquipmentBindService {

    static let shared = EquipmentBindService()

    enum EquipmentBindServiceError: LocalizedError {
        case requestFailed(String)
        case missingMonitorId

        var errorDescription: String? {
            switch self {
            case .requestFailed(let msg): return msg
            case .missingMonitorId: return "保存成功但未返回 monitorId"
            }
        }
    }

    private let api: APIManager

    init(api: APIManager = .shared) {
        self.api = api
    }

    // MARK: - 绑定查询

    /// `GET /v1/equipmentUser/getEquipmentUserByParam`
    func fetchBoundDevices(
        category: EquipmentCategoryType,
        pageNum: Int = 1,
        pageSize: Int = 100
    ) async throws -> PaginatedEquipmentUserData {
        let response: APIResponse<PaginatedEquipmentUserData> = try await api.getAsync(
            path: "/v1/equipmentUser/getEquipmentUserByParam",
            parameters: [
                "type": category.rawValue,
                "pageNum": pageNum,
                "pageSize": pageSize,
            ],
            responseType: APIResponse<PaginatedEquipmentUserData>.self
        )
        try throwIfFailed(response, defaultMessage: "获取绑定设备列表失败")
        return response.data ?? .empty
    }

    /// `GET /v1/equipmentUser/getEquipmentByOne`
    func fetchLastUsedDevice(category: EquipmentCategoryType) async throws -> EquipmentUserVO? {
        let response: APIResponse<EquipmentUserVO> = try await api.getAsync(
            path: "/v1/equipmentUser/getEquipmentByOne",
            parameters: ["type": category.rawValue],
            responseType: APIResponse<EquipmentUserVO>.self
        )
        try throwIfFailed(response, defaultMessage: "获取最近使用设备失败")
        return response.data
    }

    // MARK: - 型号与白名单

    /// `POST /v1/equipment/getEquipmenByApp` — 可连接设备型号列表（流程图「设备型号 / getEquipmentType」对齐此接口）
    func fetchEquipmentCatalog(
        category: EquipmentCategoryType,
        pageNum: Int = 1,
        pageSize: Int = 50,
        userId: Int64? = nil
    ) async throws -> PaginatedEquipmentCatalogData {
        var body: [String: Any] = [
            "type": category.rawValue,
            "pageNum": pageNum,
            "pageSize": pageSize,
        ]
        if let userId, userId > 0 {
            body["userId"] = userId
        }
        let response: APIResponse<PaginatedEquipmentCatalogData> = try await api.postAsync(
            path: "/v1/equipment/getEquipmenByApp",
            parameters: body,
            responseType: APIResponse<PaginatedEquipmentCatalogData>.self
        )
        try throwIfFailed(response, defaultMessage: "获取设备型号列表失败")
        return response.data ?? .empty
    }

    /// `GET /v1/equipment/getCompatibleBluetoothList` — 蓝牙广播名白名单
    func fetchCompatibleBluetoothNames(category: EquipmentCategoryType) async throws -> [String] {
        let response: APIResponse<[String]> = try await api.getAsync(
            path: "/v1/equipment/getCompatibleBluetoothList",
            parameters: ["type": category.rawValue],
            responseType: APIResponse<[String]>.self
        )
        try throwIfFailed(response, defaultMessage: "获取蓝牙白名单失败")
        return response.data ?? []
    }

    // MARK: - 校验与绑定

    /// `GET /v1/equipmentUser/checkEquipmentVaild` — `equipmentType` 必填（型号主键）
    func checkEquipmentValid(
        equipmentType: String,
        mac: String? = nil,
        deviceId: String? = nil
    ) async throws {
        let trimmedType = equipmentType.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedType.isEmpty else {
            throw EquipmentBindServiceError.requestFailed("equipmentType 不能为空")
        }
        var params: [String: Any] = ["equipmentType": trimmedType]
        if let mac = nonEmpty(mac) { params["mac"] = mac }
        if let deviceId = nonEmpty(deviceId) { params["deviceId"] = deviceId }

        let response: APIResponse<EmptyResponse> = try await api.getAsync(
            path: "/v1/equipmentUser/checkEquipmentVaild",
            parameters: params,
            responseType: APIResponse<EmptyResponse>.self
        )
        try throwIfFailed(response, defaultMessage: "设备校验失败")
    }

    /// `GET /v1/equipmentUser/checkEquipmentBind`
    /// - `isAlreadyBound == true`：`isSuccess == true`，设备**已经绑定**
    /// - `isAlreadyBound == false`：`isSuccess == false`，设备**未绑定**
    func checkEquipmentBind(mac: String? = nil, deviceId: String? = nil) async throws -> EquipmentBindCheckResult {
        var params: [String: Any] = [:]
        if let mac = nonEmpty(mac) { params["mac"] = mac }
        if let deviceId = nonEmpty(deviceId) { params["deviceId"] = deviceId }
        guard !params.isEmpty else {
            throw EquipmentBindServiceError.requestFailed("mac 与 deviceId 不能同时为空")
        }

        let response: APIResponse<EmptyResponse> = try await api.getAsync(
            path: "/v1/equipmentUser/checkEquipmentBind",
            parameters: params,
            responseType: APIResponse<EmptyResponse>.self
        )
        return EquipmentBindCheckResult(
            isAlreadyBound: response.isSuccess,
            message: response.msg
        )
    }

    /// `POST /v1/equipmentUser/bindEquipment`
    @discardableResult
    func bindEquipment(_ request: BindEquipmentRequest) async throws -> EmptyResponse? {
        let response: APIResponse<EmptyResponse> = try await api.postAsync(
            path: "/v1/equipmentUser/bindEquipment",
            parameters: encode(request),
            responseType: APIResponse<EmptyResponse>.self
        )
        try throwIfFailed(response, defaultMessage: "绑定设备失败")
        return response.data
    }

    /// `DELETE /v1/equipmentUser/deleteEquipmentUserById`
    func unbindEquipment(equipmentUserId: Int64) async throws {
        guard equipmentUserId > 0 else {
            throw EquipmentBindServiceError.requestFailed("equipmentUserId 无效")
        }
        let response: APIResponse<Int> = try await api.deleteAsync(
            path: "/v1/equipmentUser/deleteEquipmentUserById",
            parameters: ["equipmentUserId": equipmentUserId],
            responseType: APIResponse<Int>.self
        )
        try throwIfFailed(response, defaultMessage: "解绑设备失败")
    }

    // MARK: - 固件（可选）

    /// `GET /v1/firmware/getFirmwareUrlByParam`
    func fetchFirmwareUpgradeInfo(query: FirmwareCheckQuery) async throws -> FirmwareUpgradeInfoVO? {
        let response: APIResponse<FirmwareUpgradeInfoVO> = try await api.getAsync(
            path: "/v1/firmware/getFirmwareUrlByParam",
            parameters: query.asParameters(),
            responseType: APIResponse<FirmwareUpgradeInfoVO>.self
        )
        try throwIfFailed(response, defaultMessage: "查询固件升级失败")
        return response.data
    }

    // MARK: - 监测上报

    /// `POST /v1/monitor/saveOrUpdateMonitorData`
    @discardableResult
    func saveMonitorData(_ request: SaveMonitorDataRequest) async throws -> String {
        let response: APIResponse<SaveMonitorDataResultVO> = try await api.postAsync(
            path: "/v1/monitor/saveOrUpdateMonitorData",
            parameters: encode(request),
            responseType: APIResponse<SaveMonitorDataResultVO>.self
        )
        try throwIfFailed(response, defaultMessage: "保存监测数据失败")
        return response.data?.monitorId ?? ""
    }

    /// 体重蓝牙测量快捷上报（`businessId=4`，`collectionType=2`）
    func saveWeightBluetoothMonitor(
        mac: String,
        equipmentName: String,
        payload: WeightBluetoothMonitorData,
        equipmentType: String? = nil,
        businessId: MonitorBusinessId = .weight,
        collectionType: MonitorCollectionType = .bluetooth
    ) async throws -> String {
        let now = payload.recordTimeMs
        let request = SaveMonitorDataRequest(
            beginTime: String(now),
            endTime: String(now),
            businessId: businessId.rawValue,
            collectionType: collectionType.rawValue,
            version: String(now),
            equipmentMac: mac,
            equipmentName: equipmentName,
            serialNumber: mac,
            type: nonEmpty(equipmentType),
            monitorData: .init(data: payload.asDictionary())
        )
        print("[Scale-BLL] saveWeightBluetoothMonitor mac=\(mac) name=\(equipmentName) type=\(equipmentType ?? "-")")
        return try await saveMonitorData(request)
    }

    /// `POST /v1/monitor/getWeightHomePageData` — 体重详情 / 上传成功后拉取记录
    func fetchWeightHomePageData(monitorId: String? = nil) async throws -> WeightHomePageDataVO? {
        let request = WeightHomePageDataRequest(
            businessId: MonitorBusinessId.weight.rawValue,
            monitorId: nonEmpty(monitorId)
        )
        let response: APIResponse<WeightHomePageDataVO> = try await api.postAsync(
            path: "/v1/monitor/getWeightHomePageData",
            parameters: encode(request),
            responseType: APIResponse<WeightHomePageDataVO>.self
        )
        try throwIfFailed(response, defaultMessage: "获取体重详情失败")
        return response.data
    }

    /// `DELETE /v1/monitor/delMonitorDataByMonitorId`
    func deleteMonitorData(monitorId: String) async throws {
        let trimmed = monitorId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw EquipmentBindServiceError.requestFailed("monitorId 无效")
        }
        let response: APIResponse<APIDataID> = try await api.deleteAsync(
            path: "/v1/monitor/delMonitorDataByMonitorId",
            parameters: ["monitorId": trimmed],
            responseType: APIResponse<APIDataID>.self
        )
        try throwIfFailed(response, defaultMessage: "删除监测数据失败")
    }

    // MARK: - Helpers

    private func throwIfFailed<T>(_ response: APIResponse<T>, defaultMessage: String) throws {
        guard response.isSuccess else {
            throw EquipmentBindServiceError.requestFailed(response.msg ?? defaultMessage)
        }
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private func encode<T: Encodable>(_ value: T) -> [String: Any] {
        guard let data = try? JSONEncoder().encode(value),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return stripNulls(object)
    }

    private func stripNulls(_ object: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in object {
            if value is NSNull { continue }
            if let nested = value as? [String: Any] {
                result[key] = stripNulls(nested)
            } else {
                result[key] = value
            }
        }
        return result
    }
}
