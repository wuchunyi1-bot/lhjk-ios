import Foundation

final class ExerciseFoodService {

    static let shared = ExerciseFoodService()
    private init() {}

    func fetchDaySummary(date: String) async throws -> ExerciseFoodDaySummary {
        let response: APIResponse<ExerciseFoodDaySummary> = try await APIManager.shared.postAsync(
            path: "/v1/sportDiet/getSportDietListByToday",
            parameters: ExerciseFoodDayRequest(date: date).asDictionary(),
            responseType: APIResponse<ExerciseFoodDaySummary>.self
        )
        guard response.isSuccess, let data = response.data else {
            throw ExerciseFoodServiceError.apiFailed(response.msg ?? "获取饮食运动数据失败")
        }
        return data
    }

    func fetchCalendarMarks(dates: String) async throws -> [String] {
        let response: APIResponse<[String]> = try await APIManager.shared.postAsync(
            path: "/v1/sportDiet/getSportDietCalendar",
            parameters: ExerciseFoodCalendarRequest(dates: dates).asDictionary(),
            responseType: APIResponse<[String]>.self
        )
        guard response.isSuccess else {
            throw ExerciseFoodServiceError.apiFailed(response.msg ?? "获取日历数据失败")
        }
        return response.data ?? []
    }

    func fetchDefinitions(
        type: Int,
        pageNum: Int,
        category: Int = 0,
        name: String? = nil,
        pageSize: Int = ExerciseFoodConstants.defaultPageSize
    ) async throws -> [ExerciseFoodDefinitionItem] {
        var request = ExerciseFoodDefinitionRequest(type: type, pageNum: pageNum, pageSize: pageSize)
        request.category = category
        request.name = name?.isEmpty == true ? nil : name
        let response: APIResponse<ExerciseFoodDefinitionListData> = try await APIManager.shared.postAsync(
            path: "/v1/definitionCommon/getDefinitionCommonByParam",
            parameters: request.asDictionary(),
            responseType: APIResponse<ExerciseFoodDefinitionListData>.self
        )
        guard response.isSuccess else {
            throw ExerciseFoodServiceError.apiFailed(response.msg ?? "获取列表失败")
        }
        return response.data?.list ?? []
    }

    func fetchFoodCategories() async throws -> [ExerciseFoodCategory] {
        let response: APIResponse<[SDictionary]> = try await APIManager.shared.postAsync(
            path: "/v1/dictionary/getDictionaryByParentId2",
            parameters: [
                "parentIds": [ExerciseFoodConstants.foodCategoryParentId],
                "allStatus": true,
            ],
            responseType: APIResponse<[SDictionary]>.self
        )
        guard response.isSuccess else {
            throw ExerciseFoodServiceError.apiFailed(response.msg ?? "获取食材分类失败")
        }
        let nodes = response.data?.first?.children ?? response.data ?? []
        return nodes.compactMap { node in
            guard let name = node.name, let valueRaw = node.value, let value = Int(valueRaw) else { return nil }
            return ExerciseFoodCategory(id: node.id, name: name, value: value)
        }
    }

    func saveRecords(
        businessId: Int,
        items: [ExerciseFoodSaveItemPayload],
        beginTime: String,
        endTime: String,
        timeType: Int? = nil
    ) async throws {
        let request = ExerciseFoodSaveRequest(
            beginTime: beginTime,
            endTime: endTime,
            description: "",
            businessId: businessId,
            timeType: timeType,
            data: items
        )
        let response: APIResponse<EmptyResponse> = try await APIManager.shared.postAsync(
            path: "/v1/sportDiet/saveSportDietData",
            parameters: request.asDictionary(),
            responseType: APIResponse<EmptyResponse>.self
        )
        guard response.isSuccess else {
            throw ExerciseFoodServiceError.apiFailed(response.msg ?? "保存失败")
        }
    }

    func saveDietItems(
        items: [ExerciseFoodSaveItemPayload],
        date: String,
        timeType: Int?
    ) async throws {
        let stamp = dietTimestamp(for: date)
        try await saveRecords(
            businessId: ExerciseFoodConstants.dietBusinessId,
            items: items,
            beginTime: stamp,
            endTime: stamp,
            timeType: timeType
        )
    }

    func saveSportItems(
        items: [ExerciseFoodSaveItemPayload],
        beginTime: String
    ) async throws {
        try await saveRecords(
            businessId: ExerciseFoodConstants.sportBusinessId,
            items: items,
            beginTime: beginTime,
            endTime: BloodPressureTime.milliStamp()
        )
    }

    func updateRecord(
        item: ExerciseFoodRecordItem,
        quantity: Int,
        calorie: String,
        businessId: Int,
        timeType: Int?
    ) async throws {
        var payload = ExerciseFoodSaveItemPayload(
            id: item.itemId?.value,
            name: item.name,
            quantity: quantity,
            calorie: calorie,
            description: item.notice,
            timeType: timeType ?? item.timeType?.value,
            type: item.type?.value,
            unit: item.unit?.value,
            imgSmallUrl: item.imgSmallUrl,
            imgBigUrl: item.imgBigUrl,
            category: item.category?.value,
            categoryName: item.categoryName,
            dataSource: item.dataSource,
            monitorId: item.monitorId?.value,
            showCalorie: item.showCalorie,
            showQuantity: item.showQuantity
        )
        if businessId == ExerciseFoodConstants.sportBusinessId {
            payload.monitorId = item.monitorId?.value
        }
        let stamp = BloodPressureTime.milliStamp()
        try await saveRecords(
            businessId: businessId,
            items: [payload],
            beginTime: stamp,
            endTime: stamp,
            timeType: timeType
        )
    }

    func deleteRecord(monitorId: String) async throws {
        let response: APIResponse<EmptyResponse> = try await APIManager.shared.deleteAsync(
            path: "/v1/monitor/delMonitorDataByMonitorId",
            parameters: ["monitorId": monitorId],
            responseType: APIResponse<EmptyResponse>.self
        )
        guard response.isSuccess else {
            throw ExerciseFoodServiceError.apiFailed(response.msg ?? "删除失败")
        }
    }

    func dietTimestamp(for date: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        let combined = "\(date) \(timeFormatter.string(from: Date()))"
        return BloodPressureTime.milliStamp(from: formatter.date(from: combined) ?? Date())
    }

    func sportTimestamp(date: String, time: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let combined = "\(date) \(time)"
        return BloodPressureTime.milliStamp(from: formatter.date(from: combined) ?? Date())
    }

    static func calorie(for quantity: Int, baseQuantity: Int, baseCalorie: String) -> String {
        guard let base = Double(baseCalorie), baseQuantity > 0 else { return baseCalorie }
        let value = base * Double(quantity) / Double(baseQuantity)
        return String(format: "%.1f", value)
    }
}

enum ExerciseFoodServiceError: LocalizedError {
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
