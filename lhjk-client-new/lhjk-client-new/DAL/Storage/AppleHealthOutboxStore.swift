import Foundation
import FMDB

/// 队列里已经落下的一行，供拉取前打印。
struct AppleHealthStoredSample: DBModel {
    let uuid: String
    let kind: String
    let startAt: TimeInterval
    let endAt: TimeInterval
    let timeZone: String?
    let payload: String
    let unit: String?
    let sourceName: String
    let sourceBundle: String
    let syncState: String
    let updatedAt: TimeInterval

    init(from resultSet: FMResultSet) throws {
        uuid = resultSet.string(forColumn: "uuid") ?? ""
        kind = resultSet.string(forColumn: "kind") ?? ""
        startAt = resultSet.double(forColumn: "start_at")
        endAt = resultSet.double(forColumn: "end_at")
        timeZone = resultSet.string(forColumn: "time_zone")
        payload = resultSet.string(forColumn: "payload") ?? "{}"
        unit = resultSet.string(forColumn: "unit")
        sourceName = resultSet.string(forColumn: "source_name") ?? ""
        sourceBundle = resultSet.string(forColumn: "source_bundle") ?? ""
        syncState = resultSet.string(forColumn: "sync_state") ?? ""
        updatedAt = resultSet.double(forColumn: "updated_at")
    }

    static var insertSQL: String { "" }
    var insertValues: [Any] { [] }
}

/// 一页待写入的苹果健康样本。载荷已是 JSON 文本。
struct AppleHealthQueuedSample {
    let uuid: String
    let kind: String
    let startAt: TimeInterval
    let endAt: TimeInterval
    let timeZone: String?
    let payload: String
    let unit: String?
    let sourceName: String
    let sourceBundle: String
}

/// 苹果健康待上传队列。样本与 anchor 在同一事务里提交。
final class AppleHealthOutboxStore {

    static let shared = AppleHealthOutboxStore()

    private let database = DatabaseManager.shared

    private static let pending = "pending"
    private static let pendingDelete = "pending_delete"

    private init() {}

    func storedSamples(userId: String) -> [AppleHealthStoredSample] {
        database.executeQuery(
            """
            SELECT uuid, kind, start_at, end_at, time_zone, payload, unit,
                   source_name, source_bundle, sync_state, updated_at
            FROM apple_health_sample
            WHERE user_id = ?
            ORDER BY kind, start_at
            """,
            values: [userId]
        )
    }

    func anchorData(userId: String, kind: String) -> Data? {
        database.dataForQuery(
            "SELECT anchor FROM apple_health_anchor WHERE user_id = ? AND kind = ?",
            values: [userId, kind]
        )
    }

    func pendingSamples(userId: String, kinds: [String]) -> [AppleHealthStoredSample] {
        guard !kinds.isEmpty else { return [] }
        let marks = Array(repeating: "?", count: kinds.count).joined(separator: ", ")
        return database.executeQuery(
            """
            SELECT uuid, kind, start_at, end_at, time_zone, payload, unit,
                   source_name, source_bundle, sync_state, updated_at
            FROM apple_health_sample
            WHERE user_id = ? AND sync_state = ? AND kind IN (\(marks))
            ORDER BY start_at
            """,
            values: [userId, Self.pending] + kinds
        )
    }

    /// 服务端已接收的行删掉，并记下 uuid。`updated_at` 变过的行不删，留给下一次上传。
    func removeUploaded(userId: String, rows: [(uuid: String, updatedAt: TimeInterval)]) -> Bool {
        if rows.isEmpty { return true }
        return database.inTransaction { db, rollback in
            for row in rows {
                guard db.executeUpdate(
                    "DELETE FROM apple_health_sample WHERE user_id = ? AND uuid = ? AND updated_at = ?",
                    withArgumentsIn: [userId, row.uuid, row.updatedAt]
                ) else {
                    rollback.pointee = true
                    return
                }
                guard db.changes > 0 else { continue }
                guard db.executeUpdate(
                    "INSERT OR IGNORE INTO apple_health_sent (user_id, uuid) VALUES (?, ?)",
                    withArgumentsIn: [userId, row.uuid]
                ) else {
                    rollback.pointee = true
                    return
                }
            }
        }
    }

    /// 只覆盖样本，不改 anchor。步数日合计和体能训练回补用这条路径。
    func saveSamples(userId: String, samples: [AppleHealthQueuedSample]) -> Bool {
        if samples.isEmpty { return true }
        let now = Date().timeIntervalSince1970
        return database.inTransaction { db, rollback in
            for sample in samples {
                guard self.upsertPending(db, userId: userId, sample: sample, now: now) else {
                    rollback.pointee = true
                    return
                }
            }
        }
    }

    /// 先覆盖本页新增，再处理删除，最后写入 anchor。失败整页回滚。
    func commit(
        userId: String,
        kind: String,
        added: [AppleHealthQueuedSample],
        deletedUUIDs: [String],
        anchor: Data
    ) -> Bool {
        let now = Date().timeIntervalSince1970
        return database.inTransaction { db, rollback in
            for sample in added {
                guard self.upsertPending(db, userId: userId, sample: sample, now: now) else {
                    rollback.pointee = true
                    return
                }
            }
            for uuid in deletedUUIDs {
                switch self.lookupState(db, userId: userId, uuid: uuid) {
                case .failed:
                    rollback.pointee = true
                    return
                case .found(let state) where state == Self.pending:
                    guard self.deletePending(db, userId: userId, uuid: uuid) else {
                        rollback.pointee = true
                        return
                    }
                default:
                    guard self.upsertTombstone(db, userId: userId, uuid: uuid, kind: kind, now: now) else {
                        rollback.pointee = true
                        return
                    }
                }
            }
            guard self.upsertAnchor(db, userId: userId, kind: kind, anchor: anchor, now: now) else {
                rollback.pointee = true
                return
            }
        }
    }

    private enum Lookup {
        case missing
        case found(String)
        case failed
    }

    private func lookupState(_ db: FMDatabase, userId: String, uuid: String) -> Lookup {
        guard let rs = db.executeQuery(
            "SELECT sync_state FROM apple_health_sample WHERE user_id = ? AND uuid = ?",
            withArgumentsIn: [userId, uuid]
        ) else { return .failed }
        defer { rs.close() }
        guard rs.next() else { return .missing }
        return .found(rs.string(forColumn: "sync_state") ?? "")
    }

    private func upsertPending(_ db: FMDatabase, userId: String, sample: AppleHealthQueuedSample, now: TimeInterval) -> Bool {
        if sent(db, userId: userId, uuid: sample.uuid) { return true }
        return db.executeUpdate(
            """
            INSERT INTO apple_health_sample (
                user_id, uuid, kind, start_at, end_at, time_zone, payload, unit,
                source_name, source_bundle, sync_state, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(user_id, uuid) DO UPDATE SET
                kind = excluded.kind,
                start_at = excluded.start_at,
                end_at = excluded.end_at,
                time_zone = excluded.time_zone,
                payload = excluded.payload,
                unit = excluded.unit,
                source_name = excluded.source_name,
                source_bundle = excluded.source_bundle,
                sync_state = excluded.sync_state,
                updated_at = excluded.updated_at
            """,
            withArgumentsIn: [
                userId,
                sample.uuid,
                sample.kind,
                sample.startAt,
                sample.endAt,
                bind(sample.timeZone),
                sample.payload,
                bind(sample.unit),
                sample.sourceName,
                sample.sourceBundle,
                Self.pending,
                now
            ]
        )
    }

    private func sent(_ db: FMDatabase, userId: String, uuid: String) -> Bool {
        guard let rs = db.executeQuery(
            "SELECT 1 FROM apple_health_sent WHERE user_id = ? AND uuid = ? LIMIT 1",
            withArgumentsIn: [userId, uuid]
        ) else { return false }
        defer { rs.close() }
        return rs.next()
    }

    private func deletePending(_ db: FMDatabase, userId: String, uuid: String) -> Bool {
        db.executeUpdate(
            "DELETE FROM apple_health_sample WHERE user_id = ? AND uuid = ? AND sync_state = ?",
            withArgumentsIn: [userId, uuid, Self.pending]
        )
    }

    private func upsertTombstone(
        _ db: FMDatabase,
        userId: String,
        uuid: String,
        kind: String,
        now: TimeInterval
    ) -> Bool {
        db.executeUpdate(
            """
            INSERT INTO apple_health_sample (
                user_id, uuid, kind, start_at, end_at, time_zone, payload, unit,
                source_name, source_bundle, sync_state, updated_at
            ) VALUES (?, ?, ?, 0, 0, NULL, '{}', NULL, '', '', ?, ?)
            ON CONFLICT(user_id, uuid) DO UPDATE SET
                kind = excluded.kind,
                sync_state = excluded.sync_state,
                updated_at = excluded.updated_at
            """,
            withArgumentsIn: [userId, uuid, kind, Self.pendingDelete, now]
        )
    }

    private func upsertAnchor(
        _ db: FMDatabase,
        userId: String,
        kind: String,
        anchor: Data,
        now: TimeInterval
    ) -> Bool {
        db.executeUpdate(
            """
            INSERT INTO apple_health_anchor (user_id, kind, anchor, updated_at)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(user_id, kind) DO UPDATE SET
                anchor = excluded.anchor,
                updated_at = excluded.updated_at
            """,
            withArgumentsIn: [userId, kind, anchor, now]
        )
    }

    private func bind(_ value: String?) -> Any {
        value ?? NSNull()
    }
}
