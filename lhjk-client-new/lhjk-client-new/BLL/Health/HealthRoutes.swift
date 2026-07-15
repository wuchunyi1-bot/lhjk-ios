import Foundation

/// 健康模块路由注册
enum HealthRoutes {

    /// 兼容历史深链的子路径；均打开同一 H5 入口，由 H5 处理内部导航
    private static let metricSubPaths: [String: [String]] = [
        "blood-pressure": ["manual", "history", "service", "detail"],
        "blood-sugar": ["manual", "history", "service", "detail"],
        "weight": ["manual", "history", "service", "detail"],
        "exercise": ["home", "add-diet", "add-motion", "search"],
    ]

    static func register() {
        let r = Router.shared

        // Hub
        r.register(path: "/health") { _ in HealthViewController() }

        // Sub pages
        r.register(path: "/health/record") { _ in HealthRecordViewController() }

        // Health record sub-pages (deferred — placeholder)
        r.register(path: "/health/record/profile") { _ in PlaceholderViewController(title: "基础信息") }
        r.register(path: "/health/record/history") { _ in PlaceholderViewController(title: "健康史") }
        r.register(path: "/health/record/lifestyle") { _ in PlaceholderViewController(title: "生活习惯") }
        r.register(path: "/health/record/condition") { _ in PlaceholderViewController(title: "慢病标签") }
        r.register(path: "/health/metrics") { _ in MetricsViewController() }
        r.register(path: "/health/assessment/six-dim") { _ in PlaceholderViewController(title: "六维评测") }
        r.register(path: "/health/assessment/report") { _ in HealthReportViewController() }
        r.register(path: "/health/assessment/risk") { _ in PlaceholderViewController(title: "风险评估") }

        registerAllMetricH5Routes(r)
    }

    // MARK: - 体征监测 H5

    private static func registerAllMetricH5Routes(_ r: Router) {
        for (key, title) in H5Config.metricKeys {
            registerMetricH5(r, key: key, title: title)
            for suffix in metricSubPaths[key] ?? [] {
                registerMetricH5(r, key: key, title: title, pathSuffix: suffix)
            }
        }

        r.register(path: "/health/metrics/add") { params in
            let key = params["key"] as? String ?? ""
            return metricWebView(for: key)
        }
    }

    private static func registerMetricH5(
        _ r: Router,
        key: String,
        title: String,
        pathSuffix: String? = nil
    ) {
        let path: String
        if let pathSuffix, !pathSuffix.isEmpty {
            path = "/health/metrics/\(key)/\(pathSuffix)"
        } else {
            path = "/health/metrics/\(key)"
        }
        r.register(path: path) { _ in
            metricWebView(for: key, title: title)
        }
    }

    private static func metricWebView(for key: String, title: String? = nil) -> WebViewController {
        WebViewController(
            urlString: H5Config.metricPageURL(for: key).absoluteString,
            title: title ?? H5Config.metricTitle(for: key)
        )
    }
}
