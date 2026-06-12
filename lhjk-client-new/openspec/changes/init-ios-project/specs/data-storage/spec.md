## ADDED Requirements

### Requirement: FMDB Database Manager
系统 SHALL 在 DAL 层提供 `DatabaseManager`，基于 FMDB 封装 SQLite 数据库操作。

#### Scenario: 数据库初始化
- **WHEN** 应用启动时
- **THEN** `DatabaseManager` 创建或打开 SQLite 数据库文件，执行数据库迁移（建表/升级），确保 `FMDatabaseQueue` 线程安全访问

#### Scenario: 表创建与迁移
- **WHEN** 数据库版本升级
- **THEN** `DatabaseManager` 根据版本号执行对应的 SQL 迁移脚本（CREATE TABLE / ALTER TABLE），保证数据不丢失

#### Scenario: 增删改查操作
- **WHEN** BLL 层需要存取结构化数据
- **THEN** `DatabaseManager` 提供 `executeUpdate`（增/删/改）和 `executeQuery`（查）方法，所有操作在 `FMDatabaseQueue.inDatabase` 中串行执行，保证线程安全

#### Scenario: 批量写入
- **WHEN** BLL 层需要批量插入大量数据（如同步离线消息）
- **THEN** `DatabaseManager` 提供 `inTransaction` 方法，在事务中执行批量操作，失败时自动回滚

#### Scenario: 数据模型映射
- **WHEN** 存取业务模型对象
- **THEN** 业务模型实现 `DBModel` 协议（`init(from: FMResultSet)` + `insert/replace SQL`），`DatabaseManager` 提供泛型方法完成 ResultSet ↔ Model 的自动映射

### Requirement: UserDefaults Manager
系统 SHALL 在 DAL 层提供 `UserDefaultsManager`，封装 UserDefaults 的类型安全读写。

#### Scenario: 读写基本类型
- **WHEN** BLL 层需要存储简单配置
- **THEN** `UserDefaultsManager` 提供 `@UserDefault` 属性包装器，支持 `String`、`Int`、`Bool`、`Double`、`Date`、`Data`、`URL` 及它们的 Optional 类型

#### Scenario: 读写 Codable 类型
- **WHEN** BLL 层需要存储轻量级结构化数据（如 UserSettings）
- **THEN** `UserDefaultsManager` 支持 `Codable` 类型的 JSON 编解码存取

#### Scenario: 清除数据
- **WHEN** 用户登出
- **THEN** `UserDefaultsManager` 提供 `removeAll()` 方法，清除所有应用写入的 UserDefaults 键值（不包括系统级键值）

#### Scenario: 数据迁移
- **WHEN** 应用版本升级需要修改 UserDefaults 键名或默认值
- **THEN** `UserDefaultsManager` 在初始化时执行版本迁移逻辑，保证旧数据兼容

### Requirement: Data Classification Principle
系统 SHALL 遵循以下数据分类原则选择存储方式：

#### Scenario: 需要 SQL 查询的数据 → FMDB
- **WHEN** 数据需要复杂的 SQL 查询（排序、分页、聚合、多表关联）
- **THEN** 使用 FMDB (SQLite) 存储，如消息列表分页查询、会话按时间排序、健康数据按日期聚合

#### Scenario: 简单键值配置 → UserDefaults
- **WHEN** 数据为简单的键值对且不需要查询能力
- **THEN** 使用 UserDefaults 存储，如主题模式（暗黑/明亮）、通知开关、上次同步时间

#### Scenario: 安全敏感数据 → Keychain
- **WHEN** 数据涉及安全凭证（Token、密码、支付密钥等）
- **THEN** 使用 Keychain 存储，`UserDefaultsManager` 提供 `Keychain` 子模块封装 Keychain 存取
