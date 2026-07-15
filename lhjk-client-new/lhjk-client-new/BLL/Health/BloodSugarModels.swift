import Foundation

// MARK: - 业务常量

enum BloodSugarConstants {
    static let businessId = 5
    static let dateType = 5
    static let equipmentType = 2
    static let defaultPageSize = 20
    static let chartPageSize = 1000
    static let duplicateErrorCode = "G0009"

    enum CollectionType: Int {
        case manual = 1
        case bluetooth = 2
    }
}

// MARK: - 请求体

struct BloodSugarHomeRequest: Encodable {
    let businessId: Int
    var monitorId: String?
    var sugarId: String?
    var newbornId: String?
    var pregnantId: String?

    static var `default`: BloodSugarHomeRequest {
        BloodSugarHomeRequest(businessId: BloodSugarConstants.businessId)
    }
}

struct BloodSugarHistoryRequest: Encodable {
    let dateType: Int
    let timeType: Int
    let pageSize: Int
    var type: Int?
}

struct BloodSugarLogRequest: Encodable {
    let dateType: Int
    let searchTime: String
    let pageNum: Int
    let pageSize: Int
}

struct BloodSugarStatisticsRequest: Encodable {
    let dateType: Int
    let searchTime: String
}

struct BloodSugarMonitorDataPayload: Encodable {
    let recordTime: String
    let value: String
    let type: Int
    let typeRemark: String?
    let dataSource: String
    var timeStamp: String?
}

struct BloodSugarMonitorDataWrapper: Encodable {
    let data: BloodSugarMonitorDataPayload
}

struct BloodSugarSaveRequest: Encodable {
    let beginTime: String
    let endTime: String
    let businessId: Int
    let collectionType: Int
    let version: String
    var submitTimes: Int?
    var equipmentMac: String?
    var equipmentName: String?
    var serialNumber: String?
    let monitorData: BloodSugarMonitorDataWrapper
}

// MARK: - 响应体

struct BloodSugarMealType: Decodable, Identifiable, Equatable {
    var id: String { valueList?.value ?? UUID().uuidString }
    let name: String?
    let valueList: FlexibleString?
    let minValue: FlexibleString?
    let maxValue: FlexibleString?
    let checked: Bool?
    let configStatus: FlexibleInt?

    var typeValue: Int { Int(valueList?.value ?? "0") ?? 0 }

    var standardRangeText: String {
        let min = minValue?.value ?? "5.6"
        let max = maxValue?.value ?? "7.1"
        return "\(name ?? "")控糖标准为\(min)-\(max)mmol/L"
    }

    var isVisibleOnMeasurePage: Bool { configStatus?.value != 0 }
}

struct BloodSugarRecord: Decodable, Equatable {
    let value: FlexibleString?
    let unit: String?
    let type: FlexibleInt?
    let typeRemark: String?
    let monitorResults: String?
    let monitorResultsId: FlexibleString?
    let color: String?
    let description: String?
    let recordTime: FlexibleInt?
    let monitorId: FlexibleString?
    let id: FlexibleString?
    let maxValue: FlexibleString?
    let minValue: FlexibleString?
    let timeStamp: FlexibleString?

    var valueDisplay: String { value?.value ?? "--" }
    var unitDisplay: String { unit ?? "mmol/L" }

    var formattedRecordTime: String {
        guard let ms = recordTime?.value else { return "--" }
        let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月dd日HH:mm"
        return formatter.string(from: date)
    }
}

struct BloodSugarDayDataPoint: Decodable, Equatable {
    let type: FlexibleInt?
    let value: FlexibleString?
    let color: String?
    let recordTime: FlexibleInt?
    let typeRemark: String?
}

struct BloodSugarMonitorDay: Decodable, Identifiable, Equatable {
    var id: String { "\(monitorDate?.value ?? 0)" }
    let monitorDate: FlexibleInt?
    let data: [BloodSugarDayDataPoint]?

    var formattedDate: String {
        guard let ms = monitorDate?.value else { return "--" }
        let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return formatter.string(from: date)
    }

    var chartLabel: String {
        guard let point = data?.first, let ms = point.recordTime?.value else { return formattedDate }
        let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: date)
    }

    var chartValue: Double? {
        guard let raw = data?.first?.value?.value, let value = Double(raw) else { return nil }
        return value
    }
}

struct BloodSugarHistoryData: Decodable, Equatable {
    let monitors: [BloodSugarMonitorDay]?
    let highNum: FlexibleInt?
    let lowNum: FlexibleInt?
    let normalNum: FlexibleInt?
    let testNum: FlexibleInt?
}

struct BloodSugarLogItem: Decodable, Identifiable, Equatable {
    var id: String { sugarId?.value ?? monitorId?.value ?? UUID().uuidString }
    let dateStr: String?
    let timeStr: String?
    let typeRemark: String?
    let value: FlexibleString?
    let result: String?
    let color: String?
    let dataSource: String?
    let monitorId: FlexibleString?
    let sugarId: FlexibleString?

    enum CodingKeys: String, CodingKey {
        case dateStr, timeStr, typeRemark, value, result, color, dataSource, monitorId
        case sugarId = "id"
    }

    var valueDisplay: String {
        guard let v = value?.value else { return "--" }
        return "\(v) mmol/L"
    }

    var timeDisplay: String {
        [dateStr, timeStr].compactMap { $0 }.joined(separator: " ")
    }
}

struct BloodSugarLogListData: Decodable {
    let list: [BloodSugarLogItem]?
}

struct BloodSugarSaveResponseData: Decodable {
    let id: FlexibleString?
    let monitorData: BloodSugarSaveMonitorData?
}

struct BloodSugarSaveMonitorData: Decodable {
    let monitorId: FlexibleString?
}

struct BloodSugarSaveResult {
    let monitorId: String
    let sugarId: String?
}

extension Notification.Name {
    static let bloodSugarRecordDidDelete = Notification.Name("bloodSugarRecordDidDelete")
}
