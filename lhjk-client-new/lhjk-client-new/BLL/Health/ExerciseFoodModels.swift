import Foundation

// MARK: - 业务常量

enum ExerciseFoodConstants {
    static let sportBusinessId = 8
    static let dietBusinessId = 9
    static let definitionTypeSport = 1
    static let definitionTypeFood = 2
    static let foodCategoryParentId: Int64 = 1_373_093_850_922_487_808
    static let defaultPageSize = 20
    static let duplicatePhotoRecordId: Int64 = 0
}

enum MealTimeType: Int, CaseIterable {
    case breakfast = 1
    case morningSnack = 2
    case lunch = 3
    case afternoonSnack = 4
    case dinner = 5
    case eveningSnack = 6

    var title: String {
        switch self {
        case .breakfast: return "早餐"
        case .morningSnack: return "早加餐"
        case .lunch: return "午餐"
        case .afternoonSnack: return "午加餐"
        case .dinner: return "晚餐"
        case .eveningSnack: return "晚加餐"
        }
    }

    static func title(for timeType: Int?) -> String {
        guard let timeType, let meal = MealTimeType(rawValue: timeType) else { return "饮食" }
        return meal.title
    }
}

// MARK: - 请求体

struct ExerciseFoodDayRequest: Encodable {
    let date: String
}

struct ExerciseFoodCalendarRequest: Encodable {
    let dates: String
}

struct ExerciseFoodDefinitionRequest: Encodable {
    let type: Int
    var pageNum: Int = 1
    var pageSize: Int = ExerciseFoodConstants.defaultPageSize
    var status: Int = 1
    var category: Int = 0
    var name: String?
}

struct ExerciseFoodSaveItemPayload: Encodable {
    var id: String?
    var name: String?
    var quantity: Int?
    var calorie: String?
    var description: String?
    var timeType: Int?
    var type: Int?
    var unit: Int?
    var imgSmallUrl: String?
    var imgBigUrl: String?
    var category: Int?
    var categoryName: String?
    var dataSource: String?
    var monitorId: String?
    var showCalorie: String?
    var showQuantity: String?
}

struct ExerciseFoodSaveRequest: Encodable {
    let beginTime: String
    let endTime: String
    let description: String
    let businessId: Int
    var timeType: Int?
    let data: [ExerciseFoodSaveItemPayload]
}

// MARK: - 响应体

struct ExerciseFoodDaySummary: Decodable, Equatable {
    let remainingIntake: FlexibleString?
    let recommendCalories: String?
    let intake: FlexibleString?
    let status: String?
    let sport: ExerciseFoodSportSection?
    let diet: [ExerciseFoodDietSection]?
}

struct ExerciseFoodSportSection: Decodable, Equatable {
    let consumeNum: FlexibleString?
    let timeType: FlexibleInt?
    let list: [ExerciseFoodRecordItem]?
}

struct ExerciseFoodDietSection: Decodable, Equatable {
    let consumeNum: FlexibleString?
    let timeType: FlexibleInt?
    let list: [ExerciseFoodRecordItem]?
}

struct ExerciseFoodRecordItem: Decodable, Identifiable, Equatable {
    var id: String {
        if let monitor = monitorId?.value { return monitor }
        if let itemId = itemId?.value { return itemId }
        return UUID().uuidString
    }

    let itemId: FlexibleString?
    let name: String?
    let imgSmallUrl: String?
    let imgBigUrl: String?
    let quantity: FlexibleInt?
    let showQuantity: String?
    let showCalorie: String?
    let calorie: FlexibleString?
    let monitorId: FlexibleString?
    let timeType: FlexibleInt?
    let dateStr: String?
    let unit: FlexibleInt?
    let coefficient: FlexibleInt?
    let maxNum: FlexibleInt?
    let dataSource: String?
    let category: FlexibleInt?
    let categoryName: String?
    let type: FlexibleInt?
    let notice: String?

    enum CodingKeys: String, CodingKey {
        case itemId = "id"
        case name, imgSmallUrl, imgBigUrl, quantity, showQuantity, showCalorie, calorie
        case monitorId, timeType, dateStr, unit, coefficient, maxNum, dataSource
        case category, categoryName, type, notice
    }

    var calorieDisplay: String {
        if let show = showCalorie, !show.isEmpty { return "\(show)kcal" }
        if let raw = calorie?.value { return "\(raw)kcal" }
        return "--"
    }

    var quantityDisplay: String {
        if let show = showQuantity, !show.isEmpty { return show }
        if let q = quantity?.value { return "\(q)" }
        return "--"
    }

    var isPhotoCustomRecord: Bool {
        (itemId?.value.flatMap(Int.init) ?? 0) == 0
    }
}

struct ExerciseFoodDefinitionListData: Decodable {
    let list: [ExerciseFoodDefinitionItem]?
}

struct ExerciseFoodDefinitionItem: Decodable, Identifiable, Equatable {
    var id: String { itemId?.value ?? UUID().uuidString }

    let itemId: FlexibleString?
    let name: String?
    let imgSmallUrl: String?
    let imgBigUrl: String?
    let quantity: FlexibleInt?
    let showQuantity: String?
    let showCalorie: String?
    let calorie: FlexibleString?
    let unit: FlexibleInt?
    let unitName: String?
    let coefficient: FlexibleInt?
    let maxNum: FlexibleInt?
    let category: FlexibleInt?
    let categoryName: String?
    let type: FlexibleInt?
    let notice: String?
    let status: FlexibleInt?

    enum CodingKeys: String, CodingKey {
        case itemId = "id"
        case name, imgSmallUrl, imgBigUrl, quantity, showQuantity, showCalorie, calorie
        case unit, unitName, coefficient, maxNum, category, categoryName, type, notice, status
    }

    func toSavePayload(timeType: Int?, quantity: Int, calorie: String) -> ExerciseFoodSaveItemPayload {
        ExerciseFoodSaveItemPayload(
            id: itemId?.value,
            name: name,
            quantity: quantity,
            calorie: calorie,
            description: notice,
            timeType: timeType,
            type: type?.value,
            unit: unit?.value,
            imgSmallUrl: imgSmallUrl,
            imgBigUrl: imgBigUrl,
            category: category?.value,
            categoryName: categoryName,
            dataSource: "手动记录",
            showCalorie: showCalorie,
            showQuantity: showQuantity
        )
    }

    func toRecordItem() -> ExerciseFoodRecordItem {
        ExerciseFoodRecordItem(
            itemId: itemId,
            name: name,
            imgSmallUrl: imgSmallUrl,
            imgBigUrl: imgBigUrl,
            quantity: quantity,
            showQuantity: showQuantity,
            showCalorie: showCalorie,
            calorie: calorie,
            monitorId: nil,
            timeType: FlexibleInt(nil),
            dateStr: nil,
            unit: unit,
            coefficient: coefficient,
            maxNum: maxNum,
            dataSource: "手动记录",
            category: category,
            categoryName: categoryName,
            type: type,
            notice: notice
        )
    }
}

struct ExerciseFoodCategory: Identifiable, Equatable {
    let id: String
    let name: String
    let value: Int
}

extension Notification.Name {
    static let exerciseFoodRecordDidChange = Notification.Name("exerciseFoodRecordDidChange")
    static let exerciseFoodSearchDidSelect = Notification.Name("exerciseFoodSearchDidSelect")
}

enum ExerciseFoodCalorieCenter {
    static func title(recommendCalories: String?, remaining: Double) -> String {
        let hasPlan = recommendCalories != nil
        if hasPlan {
            return remaining < 0 ? "您多摄入了" : "您还可摄入"
        }
        return remaining < 0 ? "您实际消耗" : "您实际摄入"
    }

    static func valueText(remainingRaw: String?) -> String {
        guard let raw = remainingRaw, let value = Double(raw) else { return "--" }
        return String(format: "%.1f", abs(value))
    }
}
