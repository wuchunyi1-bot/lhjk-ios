import FMDB
import Foundation

// MARK: - DBModel 协议

/// 业务模型实现此协议以支持 FMDB 自动映射
protocol DBModel {
    /// 从 FMResultSet 当前行构造模型
    init(from resultSet: FMResultSet) throws

    /// 插入 SQL 模板（INSERT OR REPLACE INTO table (col1, col2, ...) VALUES (?, ?, ...)）
    static var insertSQL: String { get }

    /// 插入参数（顺序与 insertSQL 中的 ? 一一对应）
    var insertValues: [Any] { get }
}

// MARK: - DatabaseManager (DAL)

/// FMDB 封装管理器 — 基于 FMDatabaseQueue 保证线程安全
///
/// 所有数据库操作在串行队列中执行，无需额外加锁。
/// 支持数据库迁移、事务批量写入、泛型 ResultSet → Model 映射。
final class DatabaseManager {

    // MARK: - Singleton

    static let shared = DatabaseManager()

    // MARK: - Properties

    private let queue: FMDatabaseQueue
    private let dbPath: String

    /// 当前数据库版本
    private let currentVersion: Int = 1

    // MARK: - Initialization

    private init() {
        let documents = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first!

        dbPath = (documents as NSString).appendingPathComponent("lhjk.db")
        queue = FMDatabaseQueue(path: dbPath)!

        // 首次启动或升级时执行迁移
        migrateIfNeeded()
    }

    // MARK: - Database Migration

    /// 按版本号执行数据库迁移
    private func migrateIfNeeded() {
        queue.inDatabase { db in
            // 创建版本管理表
            try? db.executeUpdate(
                """
                CREATE TABLE IF NOT EXISTS db_version (
                    version INTEGER NOT NULL
                )
                """,
                values: nil
            )

            // 读取当前版本
            var storedVersion = 0
            if let rs = try? db.executeQuery("SELECT MAX(version) FROM db_version", values: nil) {
                if rs.next() {
                    storedVersion = Int(rs.int(forColumnIndex: 0))
                }
                rs.close()
            }

            // 按版本顺序执行迁移
            if storedVersion < 1 {
                migrateV1(db: db)
            }

            // 更新版本号
            try? db.executeUpdate(
                "INSERT INTO db_version (version) VALUES (?)",
                values: [self.currentVersion]
            )
        }
    }

    /// V1 迁移：创建基础业务表
    private func migrateV1(db: FMDatabase) {
        // 用户表
        try? db.executeUpdate(
            """
            CREATE TABLE IF NOT EXISTS user (
                id TEXT PRIMARY KEY,
                nickname TEXT,
                avatar_url TEXT,
                phone TEXT,
                gender INTEGER DEFAULT 0,
                birthday TEXT,
                created_at REAL,
                updated_at REAL
            )
            """,
            values: nil
        )

        // 消息表（本地缓存，融云承担主存储）
        try? db.executeUpdate(
            """
            CREATE TABLE IF NOT EXISTS message (
                id TEXT PRIMARY KEY,
                conversation_id TEXT NOT NULL,
                sender_id TEXT,
                receiver_id TEXT,
                content TEXT,
                type INTEGER DEFAULT 0,
                status INTEGER DEFAULT 0,
                timestamp REAL NOT NULL,
                extra TEXT
            )
            """,
            values: nil
        )
        try? db.executeUpdate(
            "CREATE INDEX IF NOT EXISTS idx_msg_conv_time ON message(conversation_id, timestamp)",
            values: nil
        )

        // 会话表（本地缓存）
        try? db.executeUpdate(
            """
            CREATE TABLE IF NOT EXISTS conversation (
                id TEXT PRIMARY KEY,
                title TEXT,
                avatar_url TEXT,
                last_message TEXT,
                unread_count INTEGER DEFAULT 0,
                is_pinned INTEGER DEFAULT 0,
                updated_at REAL
            )
            """,
            values: nil
        )

        // 订单表
        try? db.executeUpdate(
            """
            CREATE TABLE IF NOT EXISTS payment_order (
                id TEXT PRIMARY KEY,
                product_id TEXT,
                product_name TEXT,
                amount INTEGER DEFAULT 0,
                channel TEXT,
                status TEXT DEFAULT 'created',
                created_at REAL,
                paid_at REAL
            )
            """,
            values: nil
        )

        // 健康数据表
        try? db.executeUpdate(
            """
            CREATE TABLE IF NOT EXISTS health_record (
                id TEXT PRIMARY KEY,
                type TEXT NOT NULL,
                value REAL,
                unit TEXT,
                source TEXT,
                recorded_at REAL NOT NULL,
                created_at REAL
            )
            """,
            values: nil
        )
        try? db.executeUpdate(
            "CREATE INDEX IF NOT EXISTS idx_health_type_time ON health_record(type, recorded_at)",
            values: nil
        )

        // 设备表
        try? db.executeUpdate(
            """
            CREATE TABLE IF NOT EXISTS device (
                id TEXT PRIMARY KEY,
                name TEXT,
                mac_address TEXT,
                device_type TEXT,
                is_connected INTEGER DEFAULT 0,
                last_connected_at REAL,
                created_at REAL
            )
            """,
            values: nil
        )
    }

    // MARK: - Execute Update (增 / 删 / 改)

    /// 执行写操作（INSERT / UPDATE / DELETE）
    @discardableResult
    func executeUpdate(_ sql: String, values: [Any]? = nil) -> Bool {
        var success = false
        queue.inDatabase { db in
            success = db.executeUpdate(sql, withArgumentsIn: values ?? [])
        }
        return success
    }

    // MARK: - Execute Query (查)

    /// 执行查询并返回 ResultSet → Model 映射数组
    func executeQuery<T: DBModel>(_ sql: String, values: [Any]? = nil) -> [T] {
        var results: [T] = []
        queue.inDatabase { db in
            guard let rs = db.executeQuery(sql, withArgumentsIn: values ?? []) else { return }
            while rs.next() {
                if let model = try? T(from: rs) {
                    results.append(model)
                }
            }
            rs.close()
        }
        return results
    }

    /// 执行查询并返回单条记录
    func executeQueryOne<T: DBModel>(_ sql: String, values: [Any]? = nil) -> T? {
        var result: T?
        queue.inDatabase { db in
            guard let rs = db.executeQuery(sql, withArgumentsIn: values ?? []) else { return }
            if rs.next() {
                result = try? T(from: rs)
            }
            rs.close()
        }
        return result
    }

    // MARK: - Insert / Replace Model

    /// 插入或替换模型
    func insert<T: DBModel>(_ model: T) -> Bool {
        executeUpdate(T.insertSQL, values: model.insertValues)
    }

    /// 批量插入（事务保证原子性，失败自动回滚）
    func insertBatch<T: DBModel>(_ models: [T]) -> Bool {
        var success = false
        queue.inTransaction { db, rollback in
            for model in models {
                guard db.executeUpdate(T.insertSQL, withArgumentsIn: model.insertValues) else {
                    rollback.pointee = true
                    return
                }
            }
            success = true
        }
        return success
    }

    // MARK: - Transaction

    /// 在事务中执行自定义操作，失败自动回滚
    func inTransaction(_ block: @escaping (FMDatabase, UnsafeMutablePointer<ObjCBool>) -> Void) -> Bool {
        var success = false
        queue.inTransaction { db, rollback in
            block(db, rollback)
            if !rollback.pointee.boolValue {
                success = true
            }
        }
        return success
    }
}
