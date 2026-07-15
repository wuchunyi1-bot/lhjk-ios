import Foundation

// MARK: - H5 页面配置

/// H5 页面路由配置 — 健康体征监测等内嵌页
///
/// 体征监测 10 个指标已全部迁移至 H5，App 仅以 WebView 承载入口。
/// 与 `APIEnvironment` 对齐：默认使用 development 环境 H5 地址。
enum H5Config {

    /// 当前 H5 环境（默认 development，可与 `APIManager.shared.environment` 同步切换）
    static var environment: H5Environment = .development

    /// 体征监测指标 key 与导航栏标题（与 Hub / MetricsView 一致）
    static let metricKeys: [(key: String, title: String)] = [
        ("blood-pressure", "血压"),
        ("blood-sugar", "血糖"),
        ("weight", "体重"),
        ("heart-rate", "心率"),
        ("sleep", "睡眠"),
        ("ecg", "心电"),
        ("fundus", "鹰瞳眼底"),
        ("exercise", "饮食运动"),
        ("spo2", "血氧"),
        ("digestive", "消化道"),
    ]

    /// 指标 H5 入口（hash 路由 `#/{key}`）
    static func metricPageURL(for key: String) -> URL {
        environment.baseURL.appending("#/\(key)")
    }

    /// 指标中文标题；未知 key 时回退为「体征监测」
    static func metricTitle(for key: String) -> String {
        metricKeys.first { $0.key == key }?.title ?? "体征监测"
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
