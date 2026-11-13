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

    func enableBackgroundDelivery(for type: HKSampleType) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            store.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
                if let error {
                    print("[AppleHealth] 后台投递未打开 \(type.identifier) \(error.localizedDescription)")
                } else if !success {
                    print("[AppleHealth] 后台投递未打开 \(type.identifier)")
                }
                continuation.resume()
            }
        }
    }

    func observe(type: HKSampleType, update: @escaping () async -> Void) -> HKObserverQuery {
        let query = HKObserverQuery(sampleType: type, predicate: nil) { _, completion, error in
            if let error {
                print("[AppleHealth] 监听失败 \(type.identifier) \(error.localizedDescription)")
                completion()
                return
            }
            Task {
                await update()
                completion()
            }
        }
        store.execute(query)
        return query
    }
}
