import Foundation
import HealthKit

/// 苹果健康读取。授权后先取近 30 天并打印，之后只打印锚点之后的新数据。暂不上传。
final class AppleHealthSyncService {

    static let shared = AppleHealthSyncService()

    private let health = AppleHealthStore.shared
    private let defaults = UserDefaults.standard
    private var observers: [HKObserverQuery] = []
    private var didStartObservers = false
    private let lock = NSLock()

    private static let enabledKey = "fd_apple_health_enabled"
    private static let lookbackDays = 30
    private static let pageSize = 300
    private static let printLimit = 20

    private init() {}

    var isEnabled: Bool { defaults.bool(forKey: enabledKey(Self.enabledKey)) }

    var statusText: String { isEnabled ? "已开启" : "未开启" }

    /// 设置页点击。系统授权弹窗关掉后开始同步。读权限被拒绝时系统不报错，查询结果会是空的。
    func connectAndSync() async -> String {
        guard health.isAvailable else { return "此设备无法读取健康数据" }
        do {
            try await health.requestReadAuthorization(types: Self.readTypes)
        } catch {
            return "健康数据授权失败"
        }
        defaults.set(true, forKey: enabledKey(Self.enabledKey))
        await sync(trigger: "手动")
        startObserversIfNeeded()
        return "已同步，请在控制台查看 [AppleHealth]"
    }

    /// 已开启时补拉新增数据。前台回到 App 时调用。
    func syncIfEnabled() {
        guard isEnabled else { return }
        startObserversIfNeeded()
        Task { await sync(trigger: "前台") }
    }

    private func sync(trigger: String) async {
        print("[AppleHealth] 开始同步 trigger=\(trigger) user=\(userKey)")
        for kind in Kind.allCases {
            await sync(kind)
        }
        print("[AppleHealth] 同步结束")
    }

    private func sync(_ kind: Kind) async {
        let anchor = loadAnchor(kind)
        let predicate: NSPredicate? = anchor == nil ? lastMonthPredicate() : nil
        var cursor = anchor
        var printed = 0
        var total = 0
        do {
            while true {
                let page = try await health.anchoredSamples(
                    type: kind.sampleType,
                    predicate: predicate,
                    anchor: cursor,
                    limit: Self.pageSize
                )
                total += page.samples.count
                if printed < Self.printLimit {
                    let slice = page.samples.prefix(Self.printLimit - printed)
                    for sample in slice {
                        print(Self.describe(kind: kind, sample: sample))
                        printed += 1
                    }
                }
                if !page.deleted.isEmpty {
                    let ids = page.deleted.prefix(5).map(\.uuid.uuidString).joined(separator: ",")
                    print("[AppleHealth] \(kind.title) 删除 \(page.deleted.count) 条 \(ids)")
                }
                if let newAnchor = page.anchor {
                    saveAnchor(newAnchor, kind: kind)
                    cursor = newAnchor
                }
                if page.samples.count < Self.pageSize { break }
            }
        } catch {
            print("[AppleHealth] \(kind.title) 读取失败 \(error.localizedDescription)")
            return
        }
        let omitted = max(0, total - printed)
        print("[AppleHealth] \(kind.title) 共 \(total) 条\(omitted > 0 ? "，其余 \(omitted) 条已省略" : "")")
    }

    private func startObserversIfNeeded() {
        lock.lock()
        let already = didStartObservers
        if !already { didStartObservers = true }
        lock.unlock()
        guard !already else { return }
        for kind in Kind.allCases {
            Task { await health.enableBackgroundDelivery(for: kind.sampleType) }
            let query = health.observe(type: kind.sampleType) { [weak self] in
                guard let self else { return }
                await self.sync(kind)
            }
            observers.append(query)
        }
    }

    private func lastMonthPredicate() -> NSPredicate {
        let start = Calendar.current.date(byAdding: .day, value: -Self.lookbackDays, to: Date()) ?? Date()
        return HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
    }

    private func enabledKey(_ suffix: String) -> String { "\(suffix).\(userKey)" }

    private var userKey: String {
        let id = UserManager.shared.resolvedUserId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return id.isEmpty ? "anonymous" : id
    }

    private func anchorKey(_ kind: Kind) -> String { "fd_apple_health_anchor.\(userKey).\(kind.rawValue)" }

    private func loadAnchor(_ kind: Kind) -> HKQueryAnchor? {
        guard let data = defaults.data(forKey: anchorKey(kind)) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
    }

    private func saveAnchor(_ anchor: HKQueryAnchor, kind: Kind) {
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true) else { return }
        defaults.set(data, forKey: anchorKey(kind))
    }

    /// 血压关联类型不能拿去申请读权限，只能申请收缩压、舒张压，查询时仍用关联类型。
    private static let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        Kind.allCases.forEach { kind in
            if kind.sampleType is HKCorrelationType { return }
            types.insert(kind.sampleType)
        }
        Kind.extraReadTypes.forEach { types.insert($0) }
        return types
    }()

    private static func describe(kind: Kind, sample: HKSample) -> String {
        let when = Self.timeText(sample.startDate)
        let source = sample.sourceRevision.source.name
        let value = valueText(kind: kind, sample: sample)
        return "[AppleHealth] \(kind.title) \(when) \(value) source=\(source) uuid=\(sample.uuid.uuidString)"
    }

    private static func valueText(kind: Kind, sample: HKSample) -> String {
        if let workout = sample as? HKWorkout {
            let minutes = Int(workout.duration / 60)
            let energy = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
            let energyText = energy.map { String(format: " %.0f kcal", $0) } ?? ""
            return "\(workoutTitle(workout.workoutActivityType)) \(minutes)分钟\(energyText)"
        }
        if let correlation = sample as? HKCorrelation {
            let systolic = quantity(in: correlation, identifier: .bloodPressureSystolic, unit: millimeterOfMercury)
            let diastolic = quantity(in: correlation, identifier: .bloodPressureDiastolic, unit: millimeterOfMercury)
            return "\(text(systolic))/\(text(diastolic)) mmHg"
        }
        guard let quantity = sample as? HKQuantitySample, let unit = kind.unit else { return "" }
        let number = quantity.quantity.doubleValue(for: unit)
        switch kind {
        case .oxygen, .bodyFat:
            return String(format: "%.1f%%", number * 100)
        case .bmi:
            return String(format: "%.1f", number)
        case .heartRate:
            return String(format: "%.0f 次/分", number)
        default:
            return String(format: "%.2f %@", number, kind.unitName)
        }
    }

    private static func quantity(
        in correlation: HKCorrelation,
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier),
              let sample = correlation.objects(for: type).first as? HKQuantitySample else { return nil }
        return sample.quantity.doubleValue(for: unit)
    }

    private static func text(_ value: Double?) -> String {
        guard let value else { return "--" }
        return String(format: "%.0f", value)
    }

    private static let millimeterOfMercury = HKUnit.millimeterOfMercury()

    private static func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    private static func workoutTitle(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "跑步"
        case .walking: return "步行"
        case .cycling: return "骑行"
        case .swimming: return "游泳"
        case .yoga: return "瑜伽"
        case .traditionalStrengthTraining, .functionalStrengthTraining: return "力量训练"
        case .highIntensityIntervalTraining: return "间歇训练"
        default: return "体能训练(\(type.rawValue))"
        }
    }
}

extension AppleHealthSyncService {

    enum Kind: String, CaseIterable {
        case bloodGlucose
        case bloodPressure
        case heartRate
        case weight
        case bodyFat
        case bmi
        case oxygen
        case water
        case temperature
        case workout

        var title: String {
            switch self {
            case .bloodGlucose: return "血糖"
            case .bloodPressure: return "血压"
            case .heartRate: return "心率"
            case .weight: return "体重"
            case .bodyFat: return "体脂率"
            case .bmi: return "身高体重指数"
            case .oxygen: return "血氧"
            case .water: return "饮水"
            case .temperature: return "体温"
            case .workout: return "体能训练"
            }
        }

        var sampleType: HKSampleType {
            switch self {
            case .bloodGlucose: return HKQuantityType(.bloodGlucose)
            case .bloodPressure: return HKCorrelationType(.bloodPressure)
            case .heartRate: return HKQuantityType(.heartRate)
            case .weight: return HKQuantityType(.bodyMass)
            case .bodyFat: return HKQuantityType(.bodyFatPercentage)
            case .bmi: return HKQuantityType(.bodyMassIndex)
            case .oxygen: return HKQuantityType(.oxygenSaturation)
            case .water: return HKQuantityType(.dietaryWater)
            case .temperature: return HKQuantityType(.bodyTemperature)
            case .workout: return HKWorkoutType.workoutType()
            }
        }

        var unit: HKUnit? {
            switch self {
            case .bloodGlucose:
                return HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: .liter())
            case .heartRate:
                return HKUnit.count().unitDivided(by: .minute())
            case .weight:
                return .gramUnit(with: .kilo)
            case .bodyFat, .oxygen:
                return .percent()
            case .bmi:
                return .count()
            case .water:
                return .liter()
            case .temperature:
                return .degreeCelsius()
            case .bloodPressure, .workout:
                return nil
            }
        }

        var unitName: String {
            switch self {
            case .bloodGlucose: return "mmol/L"
            case .weight: return "kg"
            case .water: return "L"
            case .temperature: return "°C"
            default: return ""
            }
        }

        static var extraReadTypes: Set<HKObjectType> {
            let systolic = HKQuantityType(.bloodPressureSystolic)
            let diastolic = HKQuantityType(.bloodPressureDiastolic)
            return [systolic, diastolic]
        }
    }
}
