import Foundation
import HealthKit

/// HealthKit 读取封装。只读，不写入健康 App。
final class AppleHealthStore {

    static let shared = AppleHealthStore()

    let store = HKHealthStore()

    private init() {}

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestReadAuthorization(types: Set<HKObjectType>) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.requestAuthorization(toShare: [], read: types) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func anchoredSamples(
        type: HKSampleType,
        predicate: NSPredicate?,
        anchor: HKQueryAnchor?,
        limit: Int
    ) async throws -> (samples: [HKSample], deleted: [HKDeletedObject], anchor: HKQueryAnchor?) {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKAnchoredObjectQuery(
                type: type,
                predicate: predicate,
                anchor: anchor,
                limit: limit
            ) { _, samples, deleted, newAnchor, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (samples ?? [], deleted ?? [], newAnchor))
            }
            store.execute(query)
        }
    }

    func samples(type: HKSampleType, predicate: NSPredicate?, limit: Int) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: limit, sortDescriptors: nil) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples ?? [])
            }
            store.execute(query)
        }
    }

    /// 最近的体重，按测量时间从新到旧。
    func recentBodyMasses(limit: Int) async throws -> [(date: Date, kilograms: Double)] {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKQuantityType(.bodyMass),
                predicate: nil,
                limit: limit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let rows = (samples as? [HKQuantitySample])?.map {
                    ($0.endDate, $0.quantity.doubleValue(for: .gramUnit(with: .kilo)))
                } ?? []
                continuation.resume(returning: rows)
            }
            store.execute(query)
        }
    }

    /// 按天累计。同一天里手表和手机的重叠片段不会加两次。
    func dailySums(
        type: HKQuantityType,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async throws -> [(start: Date, end: Date, value: Double)] {
        let anchor = Calendar.current.startOfDay(for: start)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchor,
                intervalComponents: DateComponents(day: 1)
            )
            query.initialResultsHandler = { _, collection, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                var rows: [(start: Date, end: Date, value: Double)] = []
                collection?.enumerateStatistics(from: start, to: end) { statistics, _ in
                    guard let sum = statistics.sumQuantity()?.doubleValue(for: unit) else { return }
                    rows.append((statistics.startDate, statistics.endDate, sum))
                }
                continuation.resume(returning: rows)
            }
            store.execute(query)
        }
    }

    /// 关掉此前打开的后台投递。当前同步不再注册监听。
    func disableBackgroundDelivery() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            store.disableAllBackgroundDelivery { _, _ in
                continuation.resume()
            }
        }
    }
}
