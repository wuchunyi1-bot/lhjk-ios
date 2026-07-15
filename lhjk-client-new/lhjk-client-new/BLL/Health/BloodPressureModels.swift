import Foundation

// MARK: - 业务常量

enum BloodPressureConstants {
    static let businessId = 2
    static let dateType = 2
    static let equipmentType = 4
    static let defaultPageSize = 20
    static let chartPageSize = 1000

    enum CollectionType: Int {
        case manual = 1
        case bluetooth = 2
    }
}

// MARK: - 灵活解码（接口数值字段可能是 String 或 Number）

struct FlexibleString: Decodable, Equatable {
    let value: String?

    init(_ value: String?) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            return
        }
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = String(int)
        } else if let double = try? container.decode(Double.self) {
            value = String(Int(double))
        } else {
            value = nil
        }
    }

    var intValue: Int? {
        guard let value, let int = Int(value) else { return nil }
        return int
    }
}

struct FlexibleInt: Decodable, Equatable {
    let value: Int?

    init(_ value: Int?) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            return
        }
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let string = try? container.decode(String.self) {
            value = Int(string)
        } else if let double = try? container.decode(Double.self) {
            value = Int(double)
        } else {
            value = nil
        }
    }
}

// MARK: - 请求体

struct BloodPressureHomeRequest: Encodable {
    let businessId: Int
    var monitorId: String?
    var newbornId: String?
    var sugarId: String?
    var pregnantId: String?

    static var `default`: BloodPressureHomeRequest {
        BloodPressureHomeRequest(businessId: BloodPressureConstants.businessId)
    }
}

struct BloodPressureHistoryChartRequest: Encodable {
    let dateType: Int
    let timeType: Int
    let pageSize: Int
}

struct BloodPressureLogRequest: Encodable {
    let dateType: Int
    let searchTime: String
    let pageNum: Int
    let pageSize: Int
}

struct BloodPressureStatisticsRequest: Encodable {
    let dateType: Int
    let searchTime: String
}

struct BloodPressureMonitorDataPayload: Encodable {
    let recordTime: String
    let highBloodPressure: Int
    let lowBloodPressure: Int
    let heartRate: Int
}

struct BloodPressureMonitorDataWrapper: Encodable {
    let data: BloodPressureMonitorDataPayload
}

struct BloodPressureSaveRequest: Encodable {
    let beginTime: String
    let endTime: String
    let businessId: Int
    let collectionType: Int
    let version: String
    var equipmentMac: String?
    var equipmentName: String?
    var serialNumber: String?
    let monitorData: BloodPressureMonitorDataWrapper
}

// MARK: - 响应体

struct BloodPressureRecord: Decodable, Equatable {
    let highBloodPressure: FlexibleString?
    let lowBloodPressure: FlexibleString?
    let heartRate: FlexibleString?
    let monitorResults: String?
    let monitorResultsId: FlexibleString?
    let color: String?
    let description: String?
    let recordTime: FlexibleString?
    let monitorId: FlexibleString?
    let dataSource: String?
    let dataType: FlexibleInt?

    var systolicDisplay: String { highBloodPressure?.value ?? "--" }
    var diastolicDisplay: String { lowBloodPressure?.value ?? "--" }
    var heartRateDisplay: String { heartRate?.value ?? "--" }
    var pressureDisplay: String { "\(systolicDisplay)/\(diastolicDisplay)" }

    var formattedRecordTime: String {
        guard let ms = recordTime?.intValue else { return "--" }
        let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月dd日HH:mm"
        return formatter.string(from: date)
    }
}

struct BloodPressureChartPoint: Decodable, Identifiable, Equatable {
    var id: String { "\(dateStr)-\(timeStr)-\(highBloodPressure?.value ?? 0)" }
    let dateStr: String?
    let timeStr: String?
    let highBloodPressure: FlexibleInt?
    let lowBloodPressure: FlexibleInt?
    let heartRate: FlexibleInt?

    var chartLabel: String {
        let parts = (dateStr ?? "").split(separator: " ")
        return parts.first.map(String.init) ?? (timeStr ?? "")
    }
}

struct BloodPressureLogItem: Decodable, Identifiable, Equatable {
    var id: String { monitorId?.value ?? UUID().uuidString }
    let dateStr: String?
    let timeStr: String?
    let highBloodPressure: FlexibleInt?
    let lowBloodPressure: FlexibleInt?
    let heartRate: FlexibleInt?
    let monitorResults: String?
    let monitorResultsId: FlexibleInt?
    let color: String?
    let dataSource: String?
    let descriptionField: String?
    let monitorId: FlexibleString?

    var pressureDisplay: String {
        let sys = highBloodPressure?.value.map(String.init) ?? "--"
        let dia = lowBloodPressure?.value.map(String.init) ?? "--"
        return "\(sys)/\(dia)"
    }

    var heartRateDisplay: String {
        guard let hr = heartRate?.value else { return "--" }
        return "\(hr)次/分钟"
    }

    var timeDisplay: String {
        [dateStr, timeStr].compactMap { $0 }.joined(separator: " ")
    }
}

struct BloodPressureLogListData: Decodable {
    let list: [BloodPressureLogItem]?
}

struct BloodPressurePeriodStats: Decodable, Equatable {
    let days: FlexibleInt?
    let high: FlexibleInt?
    let low: FlexibleInt?
    let noRecordDays: FlexibleInt?
    let normal: FlexibleInt?
    let standardObtainedRate: String?
    let total: FlexibleInt?
}

struct BloodPressureStatisticsData: Decodable, Equatable {
    let ninety: BloodPressurePeriodStats?
    let seven: BloodPressurePeriodStats?
    let thirty: BloodPressurePeriodStats?
    let total: BloodPressurePeriodStats?
}

struct BloodPressureSaveResponseData: Decodable {
    let monitorData: BloodPressureSaveMonitorData?
}

struct BloodPressureSaveMonitorData: Decodable {
    let monitorId: FlexibleString?
}

struct BloodPressureEquipment: Decodable, Equatable {
    let mac: String?
    let name: String?
    let imgUrl: String?
    let type: FlexibleInt?
}

struct BloodPressureEquipmentListData: Decodable {
    let list: [BloodPressureEquipment]?
}

// MARK: - 时间工具

enum BloodPressureTime {
    static func milliStamp(from date: Date = Date()) -> String {
        String(Int(date.timeIntervalSince1970 * 1000))
    }

    static func milliStamp(year: Int, month: Int) -> String {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        let calendar = Calendar.current
        let date = calendar.date(from: components) ?? Date()
        return milliStamp(from: date)
    }

    static func monthString(from date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    static func displayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: date)
    }
}

extension Notification.Name {
    static let bloodPressureRecordDidDelete = Notification.Name("bloodPressureRecordDidDelete")
}
