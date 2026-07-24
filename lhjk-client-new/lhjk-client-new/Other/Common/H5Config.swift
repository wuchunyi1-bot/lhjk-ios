import Foundation

// MARK: - H5 页面配置

/// H5 页面路由配置 — 健康体征监测等内嵌页
///
/// 健康模块体征监测由 H5 承载；打开时按宿主文档拼接 `token` + `platform=ios`。
/// 其它 WebView（协议页等）不在此扩展鉴权逻辑。
enum H5Config {

    /// 当前 H5 环境（可与 `APIManager.shared.environment` 同步切换）
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

    private static let metricRootPathOverrides: [String: String] = [
        "exercise": "exercise-food",
    ]

    /// 原生子路由 suffix → H5 子路径（空字符串表示回指标首页）
    private static let nativeSuffixToH5Subpath: [String: [String: String]] = [
        "blood-pressure": [
            "manual": "add",
            "history": "records",
            "detail": "detail",
            "service": "",
        ],
        "blood-sugar": [
            "manual": "add",
            "history": "records",
            "detail": "detail",
            "service": "",
        ],
        "weight": [
            "manual": "add",
            "history": "records",
            "detail": "detail",
            "service": "",
        ],
        "exercise": [
            "home": "",
            "add-diet": "add",
            "add-motion": "check-in",
            "search": "",
        ],
    ]

    /// 指标 H5 入口（兼容旧调用，等同首页鉴权 URL）
    static func metricPageURL(for key: String) -> URL {
        authenticatedMetricURL(metricKey: key)
    }

    /// 指标中文标题；未知 key 时回退为「体征监测」
    static func metricTitle(for key: String) -> String {
        metricKeys.first { $0.key == key }?.title ?? "体征监测"
    }

    /// 构建健康体征 H5 鉴权 URL：`{base}#/{path}?token&platform=ios&...`
    static func authenticatedMetricURL(
        metricKey: String,
        nativeSuffix: String? = nil,
        routeParams: [String: Any] = [:]
    ) -> URL {
        let h5Path = resolvedH5Path(metricKey: metricKey, nativeSuffix: nativeSuffix)
        let businessQuery = businessQueryItems(
            metricKey: metricKey,
            nativeSuffix: nativeSuffix,
            routeParams: routeParams
        )
        return buildAuthenticatedURL(h5Path: h5Path, extraQuery: businessQuery)
    }

    // MARK: - Private

    private static func resolvedH5Path(metricKey: String, nativeSuffix: String?) -> String {
        let root = metricRootPathOverrides[metricKey] ?? metricKey
        guard let nativeSuffix, !nativeSuffix.isEmpty else { return root }

        let mapped = nativeSuffixToH5Subpath[metricKey]?[nativeSuffix] ?? ""
        guard !mapped.isEmpty else { return root }
        return "\(root)/\(mapped)"
    }

    private static func businessQueryItems(
        metricKey: String,
        nativeSuffix: String?,
        routeParams: [String: Any]
    ) -> [String: String] {
        var query: [String: String] = [:]

        if nativeSuffix == "detail" {
            if let monitorId = stringParam(routeParams["monitorId"]) {
                query["monitorId"] = monitorId
            }
            if metricKey == "blood-sugar", let sugarId = stringParam(routeParams["sugarId"]) {
                query["sugarId"] = sugarId
            }
        }

        if metricKey == "exercise", nativeSuffix == "add-diet" {
            let meal = stringParam(routeParams["meal"]) ?? "breakfast"
            query["meal"] = meal
        }

        if metricKey == "exercise", nativeSuffix == "add-motion",
           let monitorId = stringParam(routeParams["monitorId"]) {
            query["monitorId"] = monitorId
        }

        if nativeSuffix == "detail", metricKey == "exercise" {
            for key in ["foodId", "name", "showCalorie", "notice", "description", "imgUrl"] {
                if let value = stringParam(routeParams[key]) {
                    query[key] = value
                }
            }
        }

        return query
    }

    private static func buildAuthenticatedURL(h5Path: String, extraQuery: [String: String]) -> URL {
        var queryItems: [(String, String)] = []
        if let token = accessToken() {
            queryItems.append(("token", token))
        }
        queryItems.append(("platform", "ios"))
        for (key, value) in extraQuery where !value.isEmpty {
            queryItems.append((key, value))
        }

        let normalizedPath = h5Path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let base = environment.baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let queryString = queryItems
            .map { key, value in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(encodedKey)=\(encodedValue)"
            }
            .joined(separator: "&")

        let urlString: String
        if queryString.isEmpty {
            urlString = "\(base)#/\(normalizedPath)"
        } else {
            urlString = "\(base)#/\(normalizedPath)?\(queryString)"
        }
        return URL(string: urlString) ?? environment.baseURL
    }

    private static func accessToken() -> String? {
        guard let token = UserDefaults.standard.string(forKey: authAccessTokenKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !token.isEmpty else {
            return nil
        }
        return token
    }

    private static let authAccessTokenKey = "auth_access_token"

    private static func stringParam(_ value: Any?) -> String? {
        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        if let int = value as? Int {
            return String(int)
        }
        if let int64 = value as? Int64 {
            return String(int64)
        }
        return nil
    }
}

enum H5Environment: String {
    case development
    case staging
    case production

    var baseURL: URL {
        switch self {
        case .development:
            return URL(string: "http://h5-dev.lianhaojiankang.com")!
        case .staging:
            return URL(string: "https://staging-h5.lhjk.com")!
        case .production:
            return URL(string: "https://h5.lhjk.com")!
        }
    }
}
