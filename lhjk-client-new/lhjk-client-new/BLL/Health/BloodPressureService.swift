import Foundation

// MARK: - 血压监测服务 (BLL)

/// 封装血压监测相关 API，对齐 jumper-angel-doctor `ABNetWorkABI+BlueToothDevice`
final class BloodPressureService {

    static let shared = BloodPressureService()
    private init() {}

    // MARK: - 首页 / 详情

    func fetchHomePage(monitorId: String? = nil) async throws -> BloodPressureRecord {
        var request = BloodPressureHomeRequest.default
        request.monitorId = monitorId
        let response: APIResponse<BloodPressureRecord> = try await APIManager.shared.postAsync(
            path: "/v1/monitor/getPressureHomePageData",
            parameters: request.asDictionary(),
            responseType: APIResponse<BloodPressureRecord>.self
        )
        guard response.isSuccess, let data = response.data else {
            throw BloodPressureServiceError.apiFailed(response.msg ?? "获取血压数据失败")
        }
        return data
    }

    // MARK: - 保存

    func saveRecord(
        systolic: Int,
        diastolic: Int,
        heartRate: Int,
        recordTime: Date,
        collectionType: BloodPressureConstants.CollectionType,
        equipmentMac: String? = nil,
        equipmentName: String? = nil
    ) async throws -> String {
        let stamp = BloodPressureTime.milliStamp(from: recordTime)
        let payload = BloodPressureSaveRequest(
            beginTime: stamp,
            endTime: stamp,
            businessId: BloodPressureConstants.businessId,
            collectionType: collectionType.rawValue,
            version: BloodPressureTime.milliStamp(),
            equipmentMac: equipmentMac,
            equipmentName: equipmentName,
            serialNumber: equipmentMac,
            monitorData: BloodPressureMonitorDataWrapper(
                data: BloodPressureMonitorDataPayload(
                    recordTime: stamp,
                    highBloodPressure: systolic,
                    lowBloodPressure: diastolic,
                    heartRate: heartRate
                )
            )
        )
        let response: APIResponse<BloodPressureSaveResponseData> = try await APIManager.shared.postAsync(
            path: "/v1/monitor/saveOrUpdateMonitorData",
            parameters: payload.asDictionary(),
            responseType: APIResponse<BloodPressureSaveResponseData>.self
        )
        guard response.isSuccess else {
            throw BloodPressureServiceError.apiFailed(response.msg ?? "保存失败")
        }
        guard let monitorId = response.data?.monitorData?.monitorId?.value else {
            throw BloodPressureServiceError.apiFailed("保存成功但未返回记录 ID")
        }
        return monitorId
    }

    // MARK: - 趋势

    func fetchChartHistory(days: Int) async throws -> [BloodPressureChartPoint] {
        let request = BloodPressureHistoryChartRequest(
            dateType: BloodPressureConstants.dateType,
            timeType: days,
            pageSize: BloodPressureConstants.chartPageSize
        )
        let response: APIResponse<[BloodPressureChartPoint]> = try await APIManager.shared.postAsync(
            path: "/v1/monitor/selectPressureHistoryData",
            parameters: request.asDictionary(),
            responseType: APIResponse<[BloodPressureChartPoint]>.self
        )
        guard response.isSuccess else {
            throw BloodPressureServiceError.apiFailed(response.msg ?? "获取趋势数据失败")
        }
        return response.data ?? []
    }

    // MARK: - 日志

    func fetchLogRecords(monthMilliStamp: String, pageNum: Int, pageSize: Int = BloodPressureConstants.defaultPageSize) async throws -> [BloodPressureLogItem] {
        let request = BloodPressureLogRequest(
            dateType: BloodPressureConstants.dateType,
            searchTime: monthMilliStamp,
            pageNum: pageNum,
            pageSize: pageSize
        )
        let response: APIResponse<BloodPressureLogListData> = try await APIManager.shared.postAsync(
            path: "/v1/monitor/getPressureRecords",
            parameters: request.asDictionary(),
            responseType: APIResponse<BloodPressureLogListData>.self
        )
        guard response.isSuccess else {
            throw BloodPressureServiceError.apiFailed(response.msg ?? "获取日志失败")
        }
        return response.data?.list ?? []
    }

    // MARK: - 统计

    func fetchStatistics() async throws -> BloodPressureStatisticsData {
        let request = BloodPressureStatisticsRequest(
            dateType: BloodPressureConstants.dateType,
            searchTime: BloodPressureTime.milliStamp()
        )
        let response: APIResponse<BloodPressureStatisticsData> = try await APIManager.shared.postAsync(
            path: "/v1/monitor/getMonitorStatistics",
            parameters: request.asDictionary(),
            responseType: APIResponse<BloodPressureStatisticsData>.self
        )
        guard response.isSuccess, let data = response.data else {
            throw BloodPressureServiceError.apiFailed(response.msg ?? "获取统计数据失败")
        }
        return data
    }

    // MARK: - 删除

    func deleteRecord(monitorId: String) async throws {
        let response: APIResponse<EmptyResponse> = try await APIManager.shared.deleteAsync(
            path: "/v1/monitor/delMonitorDataByMonitorId",
            parameters: ["monitorId": monitorId],
            responseType: APIResponse<EmptyResponse>.self
        )
        guard response.isSuccess else {
            throw BloodPressureServiceError.apiFailed(response.msg ?? "删除失败")
        }
    }

    // MARK: - 设备

    func fetchBoundEquipments(pageNum: Int = 1, pageSize: Int = 100) async throws -> [BloodPressureEquipment] {
        let response: APIResponse<BloodPressureEquipmentListData> = try await APIManager.shared.getAsync(
            path: "/v1/equipmentUser/getEquipmentUserByParam",
            parameters: [
                "type": BloodPressureConstants.equipmentType,
                "pageNum": pageNum,
                "pageSize": pageSize,
            ],
            responseType: APIResponse<BloodPressureEquipmentListData>.self
        )
        guard response.isSuccess else {
            throw BloodPressureServiceError.apiFailed(response.msg ?? "获取设备列表失败")
        }
        return response.data?.list ?? []
    }
}

// MARK: - Errors

enum BloodPressureServiceError: LocalizedError {
    case apiFailed(String)

    var errorDescription: String? {
        switch self {
        case .apiFailed(let message): return message
        }
    }
}

// MARK: - Encodable Helper

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
