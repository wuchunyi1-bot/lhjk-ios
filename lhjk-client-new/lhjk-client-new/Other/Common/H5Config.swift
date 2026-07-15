import Foundation

// MARK: - H5 页面配置

/// H5 页面路由配置 — 健康 H5 等内嵌页
///
/// 与 `APIEnvironment` 对齐：默认使用 development 环境 H5 地址。
/// 体重等模块已整体迁移至 H5，App 仅以 WebView 承载，不再调用相关原生接口。
enum H5Config {

    /// 当前 H5 环境（默认 development，可与 `APIManager.shared.environment` 同步切换）
    static var environment: H5Environment = .development

    /// 体重模块 H5 入口（hash 路由 `#/weight`）
    static var weightPageURL: URL {
        environment.baseURL.appending("#/weight")
    }
}

enum H5Environment: String {
    case development
    case staging
    case production

    var baseURL: URL {
        switch self {
        case .development:
            return URL(string: "http://192.168.15.249:5181")!
        case .staging:
            return URL(string: "https://staging-h5.lhjk.com")!
        case .production:
            return URL(string: "https://h5.lhjk.com")!
        }
    }
}

private extension URL {
    /// 拼接 hash 路由片段（如 `#/weight`）
    func appending(_ hash: String) -> URL {
        URL(string: absoluteString + hash) ?? self
    }
}
