import Foundation

final class WeightService {

    static let shared = WeightService()
    private init() {}

    func fetchHomePage(monitorId: String? = nil) async throws -> WeightRecord {
        var request = WeightHomeRequest.default
        request.monitorId = monitorId
        let response: APIResponse<WeightRecord> = try await APIManager.shared.postAsync(
            path: "/v1/monitor/getWeightHomePageData",
            parameters: request.asDictionary(),
            responseType: APIResponse<WeightRecord>.self
        )
        guard response.isSuccess, let data = response.data else {
            throw WeightServiceError.apiFailed(response.msg ?? "获取体重数据失败")
        }
        return data
    }

    func saveRecord(
        weightKg: Double,
        recordTime: Date,
        collectionType: WeightConstants.CollectionType,
        heightCm: Double? = nil,
        bodyFatMetrics: WeightBodyFatMetrics? = nil,
        equipmentMac: String? = nil,
        equipmentName: String? = nil
    ) async throws -> String {
        let stamp = BloodPressureTime.milliStamp(from: recordTime)
        let weight = String(format: "%.1f", weightKg)
        var payload = WeightMonitorDataPayload(
            recordTime: stamp,
            weight: weight,
            bmi: WeightBMI.calculate(weightKg: weightKg, heightCm: heightCm)
        )
        if let bodyFatMetrics {
            payload.bodyFatScaleMonitor = bodyFatMetrics.isFatScale ? 1 : 0
            payload.muscle = bodyFatMetrics.muscle
            payload.bodyFat = bodyFatMetrics.bodyFat
            payload.bodyWater = bodyFatMetrics.bodyWater
            payload.basalMetabolism = bodyFatMetrics.basalMetabolism
            payload.fatVolume = bodyFatMetrics.fatVolume
            payload.bone = bodyFatMetrics.bone
        }

        let request = WeightSaveRequest(
            beginTime: stamp,
            endTime: stamp,
            businessId: WeightConstants.businessId,
            collectionType: collectionType.rawValue,
            version: BloodPressureTime.milliStamp(),
            equipmentMac: equipmentMac,
            equipmentName: equipmentName,
            serialNumber: equipmentMac,
            monitorData: WeightMonitorDataWrapper(data: payload)
        )

        let response: APIResponse<WeightSaveResponseData> = try await APIManager.shared.postAsync(
            path: "/v1/monitor/saveOrUpdateMonitorData",
            parameters: request.asDictionary(),
            responseType: APIResponse<WeightSaveResponseData>.self
        )
        guard response.isSuccess else {
            throw WeightServiceError.apiFailed(response.msg ?? "保存失败")
        }
        let monitorId = response.data?.monitorData?.monitorId?.value ?? response.data?.id?.value
        guard let monitorId else {
            throw WeightServiceError.apiFailed("保存成功但未返回记录 ID")
        }
        return monitorId
    }

    func fetchChartHistory() async throws -> [WeightHistoryDataPoint] {
        let request = WeightHistoryChartRequest(
            dateType: WeightConstants.dateType,
            type: WeightConstants.historyType,
            pageSize: WeightConstants.chartPageSize
        )
        let response: APIResponse<[WeightHistoryDataPoint]> = try await APIManager.shared.postAsync(
            path: "/v1/monitor/selectWeightHistoryData",
            parameters: request.asDictionary(),
            responseType: APIResponse<[WeightHistoryDataPoint]>.self
        )
        guard response.isSuccess else {
            throw WeightServiceError.apiFailed(response.msg ?? "获取趋势数据失败")
        }
        return response.data ?? []
    }

    func fetchLogRecords(monthMilliStamp: String, pageNum: Int, pageSize: Int = WeightConstants.defaultPageSize) async throws -> [WeightLogItem] {
        let request = WeightLogRequest(
            dateType: WeightConstants.dateType,
            searchTime: monthMilliStamp,
            pageNum: pageNum,
            pageSize: pageSize
        )
        let response: APIResponse<WeightLogListData> = try await APIManager.shared.postAsync(
            path: "/v1/monitor/getWeightRecords",
            parameters: request.asDictionary(),
            responseType: APIResponse<WeightLogListData>.self
        )
        guard response.isSuccess else {
            throw WeightServiceError.apiFailed(response.msg ?? "获取日志失败")
        }
        return response.data?.list ?? []
    }

    func deleteRecord(monitorId: String) async throws {
        let response: APIResponse<EmptyResponse> = try await APIManager.shared.deleteAsync(
            path: "/v1/monitor/delMonitorDataByMonitorId",
            parameters: ["monitorId": monitorId],
            responseType: APIResponse<EmptyResponse>.self
        )
        guard response.isSuccess else {
            throw WeightServiceError.apiFailed(response.msg ?? "删除失败")
        }
    }

    func fetchBoundEquipments(pageNum: Int = 1, pageSize: Int = 100) async throws -> [BloodPressureEquipment] {
        let response: APIResponse<BloodPressureEquipmentListData> = try await APIManager.shared.getAsync(
            path: "/v1/equipmentUser/getEquipmentUserByParam",
            parameters: [
                "type": WeightConstants.equipmentType,
                "pageNum": pageNum,
                "pageSize": pageSize,
            ],
            responseType: APIResponse<BloodPressureEquipmentListData>.self
        )
        guard response.isSuccess else {
            throw WeightServiceError.apiFailed(response.msg ?? "获取设备列表失败")
        }
        return response.data?.list ?? []
    }
}

struct WeightBodyFatMetrics {
    let isFatScale: Bool
    let muscle: String?
    let bodyFat: String?
    let bodyWater: String?
    let basalMetabolism: String?
    let fatVolume: String?
    let bone: String?
}

enum WeightServiceError: LocalizedError {
    case apiFailed(String)
    var errorDescription: String? {
        switch self {
        case .apiFailed(let message): return message
        }
    }
}

private extension Encodable {
    func asDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dict = object as? [String: Any] else { return [:] }
        return dict
    }
}
