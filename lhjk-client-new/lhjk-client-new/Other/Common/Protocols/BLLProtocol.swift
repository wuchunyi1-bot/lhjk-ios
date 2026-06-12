import Foundation

/// Business Logic Layer 基础协议
protocol BLLProtocol: AnyObject {
    /// 关联的 DAL 层服务类型
    associatedtype DALService

    /// DAL 服务实例
    var dalService: DALService { get }
}
