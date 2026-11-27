import Foundation
import HealthKit

/// 苹果健康读取。授权后写入本机队列，再把体温、基础体温、体重、血压、运动、血氧、饮水批量上传。
final class AppleHealthSyncService {

    static let shared = AppleHealthSyncService()

    private let health = AppleHealthStore.shared
    private let outbox = AppleHealthOutboxStore.shared
    private let defaults = UserDefaults.standard
    private let gate = AppleHealthKindGate()
    /// 从新到旧的体重，仅体能训练估算消耗时使用。
    private var bodyMasses: [(date: Date, kilograms: Double)] = []

    private static let enabledKey = "fd_apple_health_enabled"
    private static let lookbackDays = 30
    private static let pageSize = 300
    private static let uploadPageSize = 80
    private static let uploadPath = "/v1/monitor/batchSavePlatformHealthData"

    private enum SyncResult {
        case localFailed
        case savedLocally
        case synced
    }

    private init() {}

    var isEnabled: Bool {
        guard let key = enabledStorageKey() else { return false }
        return defaults.bool(forKey: key)
    }

    var statusText: String { isEnabled ? "已开启" : "未开启" }

    /// 设置页点击。系统授权弹窗关掉后开始同步。读权限被拒绝时系统不报错，查询结果会是空的。
    func connectAndSync() async -> String {
        guard health.isAvailable else { return "此设备无法读取健康数据" }
        guard currentUserId != nil else { return "请先登录后再同步" }
        do {
            try await health.requestReadAuthorization(types: Self.readTypes)
        } catch {
            return "健康数据授权失败"
        }
        if let key = enabledStorageKey() {
            defaults.set(true, forKey: key)
        }
        switch await sync(trigger: "手动") {
        case .localFailed:
            return "部分数据保存失败"
        case .savedLocally:
            return "已保存到本机，部分未上传"
        case .synced:
            return "已同步"
        }
    }

    /// 已开启时补拉新增数据。前台回到 App 时调用。
    func syncIfEnabled() {
        guard isEnabled else { return }
        Task { await sync(trigger: "前台") }
    }

    private func sync(trigger: String) async -> SyncResult {
        guard let userId = currentUserId else {
            print("[AppleHealth] 无账号，跳过 trigger=\(trigger)")
            return .localFailed
        }
        print("[AppleHealth] 开始同步 trigger=\(trigger)")
        await health.disableBackgroundDelivery()
        do {
            try await health.requestReadAuthorization(types: Self.readTypes)
        } catch {
            print("[AppleHealth] 授权失败")
            return .localFailed
        }
        printStoredSamples(userId: userId)
        var saved = true
        for kind in Kind.allCases {
            let kindSaved = await gate.run(kind: kind.rawValue) { [weak self] in
                guard let self else { return false }
                return await self.sync(kind, userId: userId)
            }
            if !kindSaved { saved = false }
        }
        print("[AppleHealth] 本地写入结束")
        printStoredSamples(userId: userId, headline: "落库后、上传前")
        let uploaded = await uploadPending(userId: userId)
        print("[AppleHealth] 同步结束")
        guard saved else { return .localFailed }
        return uploaded ? .synced : .savedLocally
    }

    private func sync(_ kind: Kind, userId: String) async -> Bool {
        if kind == .workout {
            await refreshBodyMasses()
            guard await backfillWorkouts(userId: userId) else { return false }
        }
        var cursor = loadAnchor(userId: userId, kind: kind)
        var predicate: NSPredicate? = cursor == nil ? lastMonthPredicate() : nil
        var added = 0
        var deleted = 0
        do {
            while true {
                let page = try await health.anchoredSamples(
                    type: kind.sampleType,
                    predicate: predicate,
                    anchor: cursor,
                    limit: Self.pageSize
                )
                if cursor == nil && page.samples.isEmpty && page.deleted.isEmpty {
                    break
                }
                guard let newAnchor = page.anchor,
                      let anchorData = try? NSKeyedArchiver.archivedData(
                        withRootObject: newAnchor,
                        requiringSecureCoding: true
                      ) else {
                    print("[AppleHealth] \(kind.title) 写入失败")
                    return false
                }
                let previousAnchor = cursor.flatMap {
                    try? NSKeyedArchiver.archivedData(withRootObject: $0, requiringSecureCoding: true)
                }
                let pageFull = page.samples.count >= Self.pageSize || page.deleted.count >= Self.pageSize
                if pageFull, previousAnchor == anchorData {
                    print("[AppleHealth] \(kind.title) 写入失败")
                    return false
                }
                let samples = page.samples.map { queuedSample(kind: kind, sample: $0) }
                let deletedIDs = page.deleted.map(\.uuid.uuidString)
                let committed = outbox.commit(
                    userId: userId,
                    kind: kind.rawValue,
                    added: samples,
                    deletedUUIDs: deletedIDs,
                    anchor: anchorData
                )
                guard committed else {
                    print("[AppleHealth] \(kind.title) 写入失败")
                    return false
                }
                added += samples.count
                deleted += deletedIDs.count
                cursor = newAnchor
                predicate = nil
                if !pageFull { break }
            }
        } catch {
            print("[AppleHealth] \(kind.title) 读取失败")
            return false
        }
        print("[AppleHealth] \(kind.title) 新增 \(added) 删除 \(deleted) 写入成功")
        return true
    }

    private func backfillWorkouts(userId: String) async -> Bool {
        let workouts: [HKSample]
        do {
            workouts = try await health.samples(
                type: Kind.workout.sampleType,
                predicate: lastMonthPredicate(),
                limit: HKObjectQueryNoLimit
            )
        } catch {
            print("[AppleHealth] 体能训练 读取失败")
            return false
        }
        let samples = workouts.map { queuedSample(kind: .workout, sample: $0) }
        guard outbox.saveSamples(userId: userId, samples: samples) else {
            print("[AppleHealth] 体能训练 写入失败")
            return false
        }
        print("[AppleHealth] 体能训练 近30天 \(samples.count) 条已写入")
        return true
    }

    private func refreshBodyMasses() async {
        bodyMasses = (try? await health.recentBodyMasses(limit: 80)) ?? []
    }

    /// 训练开始前最近的一次体重。
    private func weightKilograms(at date: Date) -> Double? {
        bodyMasses.first { $0.date <= date && $0.kilograms > 0 }?.kilograms
    }

    /// 同步结束后按体温、基础体温、体重、血压、运动、血氧、饮水的顺序上传。整批失败不删本地；单条新增或重复才删。
    private func uploadPending(userId: String) async -> Bool {
        var acceptedAll = true
        for kind in Kind.uploadOrder {
            let pending = outbox.pendingSamples(userId: userId, kinds: [kind.rawValue])
            if pending.isEmpty { continue }
            var pieces: [UploadPiece] = []
            var skipped = 0
            for record in pending {
                if let piece = uploadPiece(for: record) {
                    pieces.append(piece)
                } else {
                    skipped += 1
                }
            }
            if skipped > 0 {
                acceptedAll = false
                print("[AppleHealth] \(kind.title) 上传跳过 \(skipped) 条，缺少必填测量值")
            }
            var index = 0
            while index < pieces.count {
                let end = min(index + Self.uploadPageSize, pieces.count)
                let page = Array(pieces[index..<end])
                switch await post(page, userId: userId) {
                case .failed:
                    return false
                case .incomplete:
                    acceptedAll = false
                case .done:
                    break
                }
                index = end
            }
        }
        return acceptedAll
    }

    private enum PostResult {
        case failed
        case incomplete
        case done
    }

    private func post(_ page: [UploadPiece], userId: String) async -> PostResult {
        let response: APIResponse<AppleHealthBatchSaveResult>
        do {
            response = try await APIManager.shared.postAsync(
                path: Self.uploadPath,
                parameters: ["items": page.map(\.body)],
                responseType: APIResponse<AppleHealthBatchSaveResult>.self
            )
        } catch {
            print("[AppleHealth] 上传失败")
            return .failed
        }
        guard response.isSuccess else {
            print("[AppleHealth] 上传失败")
            return .failed
        }
        let items = response.data?.items ?? []
        if items.isEmpty {
            print("[AppleHealth] 上传失败")
            return .failed
        }
        var removable: [(uuid: String, updatedAt: TimeInterval)] = []
        var inserted = 0
        var duplicate = 0
        var skipped = 0
        var failed = 0
        let byUUID = Dictionary(uniqueKeysWithValues: page.map { ($0.uuid, $0) })
        for item in items {
            let status = item.itemStatus?.uppercased() ?? ""
            guard let uuid = item.externalUuid, let piece = byUUID[uuid] else {
                failed += 1
                continue
            }
            switch status {
            case "INSERTED":
                inserted += 1
                removable.append((piece.uuid, piece.updatedAt))
                removable.append(contentsOf: piece.extras)
            case "DUPLICATE":
                duplicate += 1
                removable.append((piece.uuid, piece.updatedAt))
                removable.append(contentsOf: piece.extras)
            case "SKIPPED":
                skipped += 1
            default:
                failed += 1
            }
        }
        let removed = outbox.removeUploaded(userId: userId, rows: removable)
        print("[AppleHealth] 上传 新增 \(inserted) 重复 \(duplicate) 跳过 \(skipped) 失败 \(failed)")
        guard removed else { return .failed }
        let accounted = inserted + duplicate + skipped + failed
        if skipped == 0, failed == 0, accounted == page.count { return .done }
        return .incomplete
    }

    private func uploadPiece(for record: AppleHealthStoredSample) -> UploadPiece? {
        guard let kind = Kind(rawValue: record.kind) else { return nil }
        let payload = Self.object(record.payload)
        let recordTime = Self.milliseconds(record.startAt)
        var data: [String: Any] = [
            "recordTime": recordTime,
            "dataSource": "5"
        ]
        switch kind {
        case .temperature, .basalTemperature:
            guard let value = Self.number(payload, "value") else { return nil }
            data["temperature"] = Self.uploaded(value)
        case .weight:
            guard let value = Self.number(payload, "value") else { return nil }
            data["weight"] = Self.uploaded(value)
            data["bodyFatScaleMonitor"] = 0
        case .bloodPressure:
            guard let high = Self.number(payload, "systolic"),
                  let low = Self.number(payload, "diastolic") else { return nil }
            data["highBloodPressure"] = Self.uploaded(high)
            data["lowBloodPressure"] = Self.uploaded(low)
        case .oxygen:
            guard let value = Self.number(payload, "value") else { return nil }
            data["oxygen"] = Self.uploaded(value)
        case .water:
            guard let liters = Self.number(payload, "value") else { return nil }
            let milliliters = liters * 1000
            guard milliliters > 0 else { return nil }
            data["waterAmount"] = Self.uploaded(milliliters)
        case .workout:
            guard let activity = Self.number(payload, "activity"),
                  let duration = Self.number(payload, "duration") else { return nil }
            let raw = UInt(activity)
            data["name"] = WorkoutNames.name(raw)
            data["quantity"] = Self.uploaded(duration / 60)
            data["type"] = 1
            if let calorie = Self.number(payload, "energyKcal") {
                data["calorie"] = Self.uploaded(calorie)
            }
        }
        let endTime = kind == .workout ? Self.milliseconds(record.endAt) : recordTime
        let body: [String: Any] = [
            "businessId": kind.businessId,
            "beginTime": String(recordTime),
            "endTime": String(endTime > 0 ? endTime : recordTime),
            "collectionType": 5,
            "externalUuid": record.uuid,
            "monitorData": ["data": data]
        ]
        return UploadPiece(uuid: record.uuid, updatedAt: record.updatedAt, body: body, extras: [])
    }

    private static func milliseconds(_ seconds: TimeInterval) -> Int {
        Int((seconds * 1000).rounded())
    }

    private static func object(_ payload: String) -> [String: Any] {
        guard let data = payload.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        return object
    }

    private static func number(_ object: [String: Any], _ key: String) -> Double? {
        (object[key] as? NSNumber)?.doubleValue
    }

    private func lastMonthPredicate() -> NSPredicate {
        let start = Calendar.current.date(byAdding: .day, value: -Self.lookbackDays, to: Date()) ?? Date()
        return HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
    }

    private var currentUserId: String? {
        let id = UserManager.shared.resolvedUserId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return id.isEmpty ? nil : id
    }

    private func enabledStorageKey() -> String? {
        guard let currentUserId else { return nil }
        return "\(Self.enabledKey).\(currentUserId)"
    }

    private func printStoredSamples(userId: String, headline: String = "本地已有") {
        let records = outbox.storedSamples(userId: userId)
        print("[AppleHealth] \(headline) \(records.count) 条")
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        for record in records {
            let title = Kind(rawValue: record.kind)?.title ?? record.kind
            let when = formatter.string(from: Date(timeIntervalSince1970: record.startAt))
            let unit = record.unit.map { " \($0)" } ?? ""
            print("[AppleHealth] 本地 \(title) \(when) \(record.payload)\(unit) state=\(record.syncState) source=\(record.sourceName) uuid=\(record.uuid)")
        }
    }

    private func loadAnchor(userId: String, kind: Kind) -> HKQueryAnchor? {
        guard let data = outbox.anchorData(userId: userId, kind: kind.rawValue) else { return nil }
        guard let anchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data) else {
            print("[AppleHealth] \(kind.title) anchor 无法读取，按近 30 天重新读取")
            return nil
        }
        return anchor
    }

    private func queuedSample(kind: Kind, sample: HKSample) -> AppleHealthQueuedSample {
        let source = sample.sourceRevision.source
        let unit = kind.unitName.isEmpty ? nil : kind.unitName
        return AppleHealthQueuedSample(
            uuid: sample.uuid.uuidString,
            kind: kind.rawValue,
            startAt: sample.startDate.timeIntervalSince1970,
            endAt: sample.endDate.timeIntervalSince1970,
            timeZone: sample.metadata?[HKMetadataKeyTimeZone] as? String,
            payload: payload(kind: kind, sample: sample),
            unit: unit,
            sourceName: source.name,
            sourceBundle: source.bundleIdentifier
        )
    }

    private func payload(kind: Kind, sample: HKSample) -> String {
        let object: [String: Any]
        if let workout = sample as? HKWorkout {
            var body: [String: Any] = [
                "activity": Int(workout.workoutActivityType.rawValue),
                "duration": workout.duration
            ]
            if let energy = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                body["energyKcal"] = energy
            } else if let kilograms = weightKilograms(at: workout.startDate),
                      let estimated = WorkoutEnergy.estimatedKcal(
                        activity: workout.workoutActivityType.rawValue,
                        duration: workout.duration,
                        weightKg: kilograms
                      ) {
                body["energyKcal"] = estimated
                body["energyEstimated"] = true
            }
            object = body
        } else if let correlation = sample as? HKCorrelation {
            var body: [String: Any] = [:]
            if let systolic = Self.quantity(in: correlation, identifier: .bloodPressureSystolic, unit: Self.millimeterOfMercury) {
                body["systolic"] = systolic
            }
            if let diastolic = Self.quantity(in: correlation, identifier: .bloodPressureDiastolic, unit: Self.millimeterOfMercury) {
                body["diastolic"] = diastolic
            }
            object = body
        } else if let quantity = sample as? HKQuantitySample, let unit = kind.unit {
            var number = quantity.quantity.doubleValue(for: unit)
            if kind == .oxygen {
                number *= 100
            }
            if kind == .temperature || kind == .basalTemperature {
                object = ["value": Self.celsius(number)]
            } else {
                object = ["value": number]
            }
        } else {
            object = [:]
        }
        return Self.json(object)
    }

    /// 上传的测量值保留两位小数。直接放 Double 时，245.7 会被序列化成 245.69999999999999。
    private static func uploaded(_ value: Double) -> NSDecimalNumber {
        let handler = NSDecimalNumberHandler(
            roundingMode: .plain,
            scale: 2,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )
        return NSDecimalNumber(value: value).rounding(accordingToBehavior: handler)
    }

    /// 体温按健康 App 的一位小数写入本地。直接放 Double 时，36.9 会被序列化成 36.899999999999999。
    private static func celsius(_ value: Double) -> NSDecimalNumber {
        let handler = NSDecimalNumberHandler(
            roundingMode: .plain,
            scale: 1,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )
        return NSDecimalNumber(value: value).rounding(accordingToBehavior: handler)
    }

    private static func json(_ object: [String: Any]) -> String {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
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

    private static let millimeterOfMercury = HKUnit.millimeterOfMercury()

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
}

private struct UploadPiece {
    let uuid: String
    let updatedAt: TimeInterval
    let body: [String: Any]
    let extras: [(uuid: String, updatedAt: TimeInterval)]
}

private struct AppleHealthBatchSaveResult: Decodable {
    let items: [AppleHealthBatchSaveItem]?
}

private struct AppleHealthBatchSaveItem: Decodable {
    let externalUuid: String?
    let itemStatus: String?
}

private enum WorkoutNames {
    static func name(_ raw: UInt) -> String {
        names[raw] ?? "其他"
    }

    private static let names: [UInt: String] = [
        1: "美式橄榄球", 2: "射箭", 3: "澳式足球", 4: "羽毛球", 5: "棒球",
        6: "篮球", 7: "保龄球", 8: "拳击", 9: "攀岩", 10: "板球",
        11: "交叉训练", 12: "冰壶", 13: "骑行", 14: "舞蹈", 15: "舞蹈启发训练",
        16: "椭圆机", 17: "马术", 18: "击剑", 19: "钓鱼", 20: "功能性力量训练",
        21: "高尔夫", 22: "体操", 23: "手球", 24: "徒步", 25: "曲棍球",
        26: "打猎", 27: "长曲棍球", 28: "武术", 29: "身心运动", 30: "混合代谢有氧",
        31: "划桨", 32: "玩耍", 33: "准备与恢复", 34: "短柄墙球", 35: "划船",
        36: "橄榄球", 37: "跑步", 38: "帆船", 39: "滑冰", 40: "雪上运动",
        41: "足球", 42: "垒球", 43: "壁球", 44: "踏步机", 45: "冲浪",
        46: "游泳", 47: "乒乓球", 48: "网球", 49: "田径", 50: "传统力量训练",
        51: "排球", 52: "步行", 53: "水中健身", 54: "水球", 55: "水上运动",
        56: "摔跤", 57: "瑜伽", 58: "芭蕾塑形", 59: "核心训练", 60: "越野滑雪",
        61: "高山滑雪", 62: "柔韧性", 63: "高强度间歇训练", 64: "跳绳", 65: "踢拳",
        66: "普拉提", 67: "单板滑雪", 68: "楼梯", 69: "踏板训练", 70: "轮椅配速步行",
        71: "轮椅配速跑", 72: "太极", 73: "混合有氧", 74: "手摇车", 75: "飞盘",
        76: "健身游戏", 77: "有氧舞蹈", 78: "社交舞", 79: "匹克球", 80: "放松",
        82: "铁人三项", 83: "换项", 84: "潜水", 3000: "其他"
    ]
}

private actor AppleHealthKindGate {
    private var tails: [String: Task<Bool, Never>] = [:]

    func run(kind: String, _ operation: @escaping () async -> Bool) async -> Bool {
        let previous = tails[kind]
        let task = Task<Bool, Never> {
            _ = await previous?.value
            return await operation()
        }
        tails[kind] = task
        return await task.value
    }
}

extension AppleHealthSyncService {

    enum Kind: String, CaseIterable {
        case bloodPressure
        case weight
        case oxygen
        case water
        case temperature
        case basalTemperature
        case workout

        var title: String {
            switch self {
            case .bloodPressure: return "血压"
            case .weight: return "体重"
            case .oxygen: return "血氧"
            case .water: return "饮水"
            case .temperature: return "体温"
            case .basalTemperature: return "基础体温"
            case .workout: return "体能训练"
            }
        }

        var sampleType: HKSampleType {
            switch self {
            case .bloodPressure: return HKCorrelationType(.bloodPressure)
            case .weight: return HKQuantityType(.bodyMass)
            case .oxygen: return HKQuantityType(.oxygenSaturation)
            case .water: return HKQuantityType(.dietaryWater)
            case .temperature: return HKQuantityType(.bodyTemperature)
            case .basalTemperature: return HKQuantityType(.basalBodyTemperature)
            case .workout: return HKWorkoutType.workoutType()
            }
        }

        var unit: HKUnit? {
            switch self {
            case .weight:
                return .gramUnit(with: .kilo)
            case .oxygen:
                return .percent()
            case .water:
                return .liter()
            case .temperature, .basalTemperature:
                return .degreeCelsius()
            case .bloodPressure, .workout:
                return nil
            }
        }

        var unitName: String {
            switch self {
            case .bloodPressure: return "mmHg"
            case .weight: return "kg"
            case .oxygen: return "%"
            case .water: return "L"
            case .temperature, .basalTemperature: return "°C"
            case .workout: return "s"
            }
        }

        var businessId: Int {
            switch self {
            case .bloodPressure: return 2
            case .weight: return 4
            case .temperature, .basalTemperature: return 6
            case .workout: return 8
            case .oxygen: return 17
            case .water: return 19
            }
        }

        static var uploadOrder: [Kind] {
            [.temperature, .basalTemperature, .weight, .bloodPressure, .workout, .oxygen, .water]
        }

        static var extraReadTypes: Set<HKObjectType> {
            let systolic = HKQuantityType(.bloodPressureSystolic)
            let diastolic = HKQuantityType(.bloodPressureDiastolic)
            return [systolic, diastolic]
        }
    }
}

/// 体能训练缺消耗时的 MET 兜底。已停用的 15、30 和「其他」不在表中。
private enum WorkoutEnergy {
    private enum Formula {
        case adult
        case wheelchair
    }

    private struct Entry {
        let met: Double
        let formula: Formula
    }

    static func estimatedKcal(activity: UInt, duration: TimeInterval, weightKg: Double) -> Double? {
        guard duration > 0, weightKg > 0, let entry = table[activity] else { return nil }
        let kcal: Double
        switch entry.formula {
        case .adult:
            kcal = 3.5 * (entry.met - 1) * weightKg / 200 * (duration / 60)
        case .wheelchair:
            kcal = entry.met * 0.992 * weightKg * (duration / 3600)
        }
        guard kcal > 0 else { return nil }
        return (kcal * 10).rounded() / 10
    }

    private static let table: [UInt: Entry] = [
        1: Entry(met: 8, formula: .adult),
        2: Entry(met: 4.3, formula: .adult),
        3: Entry(met: 8, formula: .adult),
        4: Entry(met: 5.5, formula: .adult),
        5: Entry(met: 5, formula: .adult),
        6: Entry(met: 7.5, formula: .adult),
        7: Entry(met: 3, formula: .adult),
        8: Entry(met: 5.8, formula: .adult),
        9: Entry(met: 8, formula: .adult),
        10: Entry(met: 4.8, formula: .adult),
        11: Entry(met: 5, formula: .adult),
        12: Entry(met: 4, formula: .adult),
        13: Entry(met: 7, formula: .adult),
        14: Entry(met: 5, formula: .adult),
        16: Entry(met: 5, formula: .adult),
        17: Entry(met: 5.5, formula: .adult),
        18: Entry(met: 6, formula: .adult),
        19: Entry(met: 3.5, formula: .adult),
        20: Entry(met: 5, formula: .adult),
        21: Entry(met: 4.5, formula: .adult),
        22: Entry(met: 3.8, formula: .adult),
        23: Entry(met: 8, formula: .adult),
        24: Entry(met: 6, formula: .adult),
        25: Entry(met: 8, formula: .adult),
        26: Entry(met: 5, formula: .adult),
        27: Entry(met: 8, formula: .adult),
        28: Entry(met: 5.3, formula: .adult),
        29: Entry(met: 2.3, formula: .adult),
        31: Entry(met: 3.5, formula: .adult),
        32: Entry(met: 4, formula: .adult),
        33: Entry(met: 2.8, formula: .adult),
        34: Entry(met: 7, formula: .adult),
        35: Entry(met: 5, formula: .adult),
        36: Entry(met: 8.3, formula: .adult),
        37: Entry(met: 7.5, formula: .adult),
        38: Entry(met: 3, formula: .adult),
        39: Entry(met: 6, formula: .adult),
        40: Entry(met: 6.3, formula: .adult),
        41: Entry(met: 7, formula: .adult),
        42: Entry(met: 5, formula: .adult),
        43: Entry(met: 7.3, formula: .adult),
        44: Entry(met: 9.3, formula: .adult),
        45: Entry(met: 3, formula: .adult),
        46: Entry(met: 6, formula: .adult),
        47: Entry(met: 4, formula: .adult),
        48: Entry(met: 6.8, formula: .adult),
        49: Entry(met: 6, formula: .adult),
        50: Entry(met: 3.5, formula: .adult),
        51: Entry(met: 4, formula: .adult),
        52: Entry(met: 3.5, formula: .adult),
        53: Entry(met: 5.5, formula: .adult),
        54: Entry(met: 10, formula: .adult),
        55: Entry(met: 5, formula: .adult),
        56: Entry(met: 6, formula: .adult),
        57: Entry(met: 2.3, formula: .adult),
        58: Entry(met: 6.3, formula: .adult),
        59: Entry(met: 2.8, formula: .adult),
        60: Entry(met: 8.5, formula: .adult),
        61: Entry(met: 6.3, formula: .adult),
        62: Entry(met: 2.3, formula: .adult),
        63: Entry(met: 7, formula: .adult),
        64: Entry(met: 11, formula: .adult),
        65: Entry(met: 7.3, formula: .adult),
        66: Entry(met: 2.8, formula: .adult),
        67: Entry(met: 7.5, formula: .adult),
        68: Entry(met: 6.8, formula: .adult),
        69: Entry(met: 7.3, formula: .adult),
        70: Entry(met: 2.9, formula: .wheelchair),
        71: Entry(met: 7.9, formula: .wheelchair),
        72: Entry(met: 3.3, formula: .adult),
        73: Entry(met: 7.3, formula: .adult),
        74: Entry(met: 3.6, formula: .wheelchair),
        75: Entry(met: 3, formula: .adult),
        76: Entry(met: 4, formula: .adult),
        77: Entry(met: 4.8, formula: .adult),
        78: Entry(met: 4.5, formula: .adult),
        79: Entry(met: 4.1, formula: .adult),
        80: Entry(met: 2.3, formula: .adult),
        82: Entry(met: 7, formula: .adult),
        83: Entry(met: 2.8, formula: .adult),
        84: Entry(met: 7, formula: .adult)
    ]
}
