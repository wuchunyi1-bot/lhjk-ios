import Foundation

/// Data Access Layer 基础协议
protocol DALProtocol: AnyObject {
    /// 数据源标识（如 API base path，数据库表名等）
    static var identifier: String { get }
}
