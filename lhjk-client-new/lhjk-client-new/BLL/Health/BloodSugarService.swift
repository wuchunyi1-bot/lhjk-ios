import Foundation

// MARK: - 血糖监测服务 (BLL)

final class BloodSugarService {

    static let shared = BloodSugarService()
    private init() {}

    // MARK: - 餐次类型

    func fetchMealTypes() async throws -> [BloodSugarMealType] {
        let response: APIResponse<[BloodSugarMealType]> = try await APIManager.shared.postAsync(
            path: "/v1/monitor/getSugarTypes",
            parameters: [:],
            responseType: APIResponse<[BloodSugarMealType]>.self
        )
        guard response.isSuccess else {
            throw BloodSugarServiceError.apiFailed(response.msg ?? "获取餐次类型失败")
        }
        return response.data ?? []
    }

    // MARK: - 首页 / 详情

    func fetchHomePage(monitorId: String? = nil, sugarId: String? = nil) async throws -> BloodSugarRecord {
        var request = BloodSugarHomeRequest.default
        request.monitorId = monitorId
        request.sugarId = sugarId
        let response: APIResponse<BloodSugarRecord> = try await APIManager.shared.postAsync(
            path: "/v1/monitor/getSugarHomePageData",
            parameters: request.asDictionary(),
            responseType: APIResponse<BloodSugarRecord>.self
        )
        guard response.isSuccess, let data = response.data else {
            throw BloodSugarServiceError.apiFailed(response.msg ?? "获取血糖数据失败")
        }
        return data
    }

    // MARK: - 保存

    func saveRecord(
        value: String,
        mealType: BloodSugarMealType,
        recordTime: Date,
        collectionType: BloodSugarConstants.CollectionType,
        submitTimes: Int = 1,
        equipmentMac: String? = nil,
        equipmentName: String? = nil,
        timeStamp: String? = nil
    ) async throws -> BloodSugarSaveResult {
        let stamp = BloodPressureTime.milliStamp(from: recordTime)
        var payload = BloodSugarMonitorDataPayload(
            recordTime: stamp,
            value: value,
            type: mealType.typeValue,
            typeRemark: mealType.name,
            dataSource: collectionType == .manual ? "手动记录" : "蓝牙记录"
        )
        payload.timeStamp = timeStamp

        let request = BloodSugarSaveRequest(
            beginTime: stamp,
            endTime: stamp,
            businessId: BloodSugarConstants.businessId,
            collectionType: collectionType.rawValue,
            version: BloodPressureTime.milliStamp(),
            submitTimes: submitTimes,
            equipmentMac: equipmentMac,
            equipmentName: equipmentName,
            serialNumber: equipmentMac,
            monitorData: BloodSugarMonitorDataWrapper(data: payload)
        )

        let response: APIResponse<BloodSugarSaveResponseData> = try await APIManager.shared.postAsync(
            path: "/v1/monitor/saveOrUpdateMonitorData",
            parameters: request.asDictionary(),
            responseType: APIResponse<BloodSugarSaveResponseData>.self
        )

        if response.code == BloodSugarConstants.duplicateErrorCode {
            throw BloodSugarServiceError.duplicateRecord(response.msg ?? "已有监测数据，确认继续提交吗?")
        }
        guard response.isSuccess else {
            throw BloodSugarServiceError.apiFailed(response.msg ?? "保存失败")
        }

        let monitorId = response.data?.monitorData?.monitorId?.value
            ?? response.data?.id?.value
        guard let monitorId else {
            throw BloodSugarServiceError.apiFailed("保存成功但未返回记录 ID")
        }
        return BloodSugarSaveResult(monitorId: monitorId, sugarId: response.data?.id?.value)
    }

    // MARK: - 历史

    func fetchHistory(days: Int, mealType: Int? = nil) async throws -> BloodSugarHistoryData {
        let request = BloodSugarHistoryRequest(
            dateType: BloodSugarConstants.dateType,
            timeType: days,
            pageSize: BloodSugarConstants.chartPageSize,
            type: mealType
        )
        let response: APIResponse<BloodSugarHistoryData> = try await APIManager.shared.postAsync(
            path: "/v1/monitor/getSugarHistory",
            parameters: request.asDictionary(),
            responseType: APIResponse<BloodSugarHistoryData>.self
        )
        guard response.isSuccess, let data = response.data else {
            throw BloodSugarServiceError.apiFailed(response.msg ?? "获取历史数据失败")
        }
        return data
    }

    // MARK: - 日志

    func fetchLogRecords(monthMilliStamp: String, pageNum: Int, pageSize: Int = BloodSugarConstants.defaultPageSize) async throws -> [BloodSugarLogItem] {
        let request = BloodSugarLogRequest(
            dateType: BloodSugarConstants.dateType,
            searchTime: monthMilliStamp,
            pageNum: pageNum,
            pageSize: pageSize
        )
        let response: APIResponse<BloodSugarLogListData> = try await APIManager.shared.postAsync(
            path: "/v1/monitor/getSugarRecords",
            parameters: request.asDictionary(),
            responseType: APIResponse<BloodSugarLogListData>.self
        )
        guard response.isSuccess else {
            throw BloodSugarServiceError.apiFailed(response.msg ?? "获取日志失败")
        }
        return response.data?.list ?? []
    }

    // MARK: - 统计

    func fetchStatistics() async throws -> BloodPressureStatisticsData {
        let request = BloodSugarStatisticsRequest(
            dateType: BloodSugarConstants.dateType,
            searchTime: BloodPressureTime.milliStamp()
        )
        let response: APIResponse<BloodPressureStatisticsData> = try await APIManager.shared.postAsync(
            path: "/v1/monitor/getMonitorStatistics",
            parameters: request.asDictionary(),
            responseType: APIResponse<BloodPressureStatisticsData>.self
        )
        guard response.isSuccess, let data = response.data else {
            throw BloodSugarServiceError.apiFailed(response.msg ?? "获取统计数据失败")
        }
        return data
    }

    // MARK: - 删除

    func deleteRecord(monitorId: String, sugarId: String?) async throws {
        var params: [String: Any] = ["monitorId": monitorId]
        if let sugarId { params["sugarId"] = sugarId }
        let response: APIResponse<EmptyResponse> = try await APIManager.shared.deleteAsync(
            path: "/v1/monitor/delMonitorDataByMonitorId",
            parameters: params,
            responseType: APIResponse<EmptyResponse>.self
        )
        guard response.isSuccess else {
            throw BloodSugarServiceError.apiFailed(response.msg ?? "删除失败")
        }
    }

    // MARK: - 设备

    func fetchBoundEquipments(pageNum: Int = 1, pageSize: Int = 100) async throws -> [BloodPressureEquipment] {
        let response: APIResponse<BloodPressureEquipmentListData> = try await APIManager.shared.getAsync(
            path: "/v1/equipmentUser/getEquipmentUserByParam",
            parameters: [
                "type": BloodSugarConstants.equipmentType,
                "pageNum": pageNum,
                "pageSize": pageSize,
            ],
            responseType: APIResponse<BloodPressureEquipmentListData>.self
        )
        guard response.isSuccess else {
            throw BloodSugarServiceError.apiFailed(response.msg ?? "获取设备列表失败")
        }
        return response.data?.list ?? []
    }
}

enum BloodSugarServiceError: LocalizedError {
    case apiFailed(String)
    case duplicateRecord(String)

    var errorDescription: String? {
        switch self {
        case .apiFailed(let message): return message
        case .duplicateRecord(let message): return message
        }
    }
}

private extension Encodable {
    func asDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dict = object as? [String: Any] else {
            return [:]
        }
        return dict
    }
}
