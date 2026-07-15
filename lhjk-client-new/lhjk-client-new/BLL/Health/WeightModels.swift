import Foundation

enum WeightConstants {
    static let businessId = 4
    static let dateType = 4
    static let historyType = 2
    static let equipmentType = 3
    static let defaultPageSize = 20
    static let chartPageSize = 1000

    enum CollectionType: Int {
        case manual = 1
        case bluetooth = 2
    }
}

struct WeightHomeRequest: Encodable {
    let businessId: Int
    var monitorId: String?

    static var `default`: WeightHomeRequest {
        WeightHomeRequest(businessId: WeightConstants.businessId)
    }
}

struct WeightHistoryChartRequest: Encodable {
    let dateType: Int
    let type: Int
    let pageSize: Int
}

struct WeightLogRequest: Encodable {
    let dateType: Int
    let searchTime: String
    let pageNum: Int
    let pageSize: Int
}

struct WeightMonitorDataPayload: Encodable {
    let recordTime: String
    let weight: String
    var bmi: String?
    var bodyFatScaleMonitor: Int = 0
    var muscle: String?
    var bodyFat: String?
    var bodyWater: String?
    var basalMetabolism: String?
    var fatVolume: String?
    var bone: String?
}

struct WeightMonitorDataWrapper: Encodable {
    let data: WeightMonitorDataPayload
}

struct WeightSaveRequest: Encodable {
    let beginTime: String
    let endTime: String
    let businessId: Int
    let collectionType: Int
    let version: String
    var equipmentMac: String?
    var equipmentName: String?
    var serialNumber: String?
    let monitorData: WeightMonitorDataWrapper
}

struct WeightRecord: Decodable, Equatable {
    let weight: FlexibleString?
    let bmi: FlexibleString?
    let color: String?
    let recordTime: FlexibleInt?
    let monitorResults: String?
    let monitorResultsId: FlexibleString?
    let description: String?
    let dataSource: String?
    let monitorId: FlexibleString?
    let recommendStr: String?
    let increasedWeight: FlexibleString?
    let recommend: FlexibleString?
    let distanceTarget: FlexibleString?
    let weekRecommend: FlexibleString?
    let showStatus: FlexibleInt?
    let bodyFat: FlexibleString?
    let muscle: FlexibleString?
    let bodyWater: FlexibleString?
    let basalMetabolism: FlexibleString?
    let fatVolume: FlexibleString?
    let bone: FlexibleString?
    let bodyFatScaleMonitor: FlexibleInt?

    var weightDisplay: String {
        guard let value = weight?.value else { return "--" }
        return value
    }

    var bmiDisplay: String {
        guard let value = bmi?.value else { return "--" }
        return value
    }

    var formattedRecordTime: String {
        guard let ms = recordTime?.value else { return "--" }
        let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月dd日HH:mm"
        return formatter.string(from: date)
    }

    var pregnancyStatusText: String? {
        switch showStatus?.value {
        case 1: return "备孕中"
        case 2: return "怀孕中"
        case 3: return "已分娩"
        case 4: return "双胎BMI<18.5"
        default: return nil
        }
    }
}

struct WeightHistoryDataPoint: Decodable, Identifiable, Equatable {
    var id: String { "\(dayStr ?? "")-\(recordTime?.value ?? "")" }
    let dayStr: String?
    let dateStr: String?
    let timeStr: String?
    let recordTime: FlexibleString?
    let xresult: FlexibleString?
    let yresult: FlexibleString?
    let weightData: WeightHistoryWeightData?

    var chartLabel: String {
        let parts = (dayStr ?? dateStr ?? "").split(separator: " ")
        return parts.first.map(String.init) ?? (timeStr ?? "")
    }

    var weightValue: Double? {
        guard let raw = weightData?.weight?.value, let value = Double(raw) else { return nil }
        return value
    }

    var minRange: Double? { xresult?.value.flatMap { Double($0) } }
    var maxRange: Double? { yresult?.value.flatMap { Double($0) } }

    var pointColorHex: String {
        guard let value = weightValue else { return "#5AD480" }
        if let min = minRange, value < min { return "#FE6186" }
        if let max = maxRange, value > max { return "#FFB25C" }
        return "#5AD480"
    }
}

struct WeightHistoryWeightData: Decodable, Equatable {
    let weight: FlexibleString?
    let bmi: FlexibleString?
    let color: String?
    let monitorResults: String?
    let dataSource: String?
}

struct WeightLogItem: Decodable, Identifiable, Equatable {
    var id: String { monitorId?.value ?? UUID().uuidString }
    let dateStr: String?
    let timeStr: String?
    let weight: FlexibleString?
    let monitorResults: String?
    let color: String?
    let dataSource: String?
    let monitorId: FlexibleString?
    let bodyFat: FlexibleInt?
    let muscle: FlexibleInt?
    let bodyWater: FlexibleInt?
    let bodyFatScaleMonitor: FlexibleInt?

    var weightDisplay: String {
        guard let w = weight?.value else { return "--" }
        return "\(w) kg"
    }

    var timeDisplay: String {
        [dateStr, timeStr].compactMap { $0 }.joined(separator: " ")
    }
}

struct WeightLogListData: Decodable {
    let list: [WeightLogItem]?
}

struct WeightSaveResponseData: Decodable {
    let id: FlexibleString?
    let monitorData: WeightSaveMonitorData?
}

struct WeightSaveMonitorData: Decodable {
    let monitorId: FlexibleString?
}

enum WeightBMI {
    static func calculate(weightKg: Double, heightCm: Double?) -> String? {
        guard let heightCm, heightCm > 0 else { return nil }
        let meters = heightCm / 100
        let bmi = weightKg / (meters * meters)
        return String(format: "%.1f", bmi)
    }
}

extension Notification.Name {
    static let weightRecordDidDelete = Notification.Name("weightRecordDidDelete")
}
