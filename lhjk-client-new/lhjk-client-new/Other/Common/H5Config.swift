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
        ("temperature", "体温"),
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
            "add": "add",
            "manual": "add",
            "history": "records",
            "detail": "detail",
            "service": "",
        ],
        "blood-sugar": [
            "add": "add",
            "manual": "add",
            "history": "records",
            "detail": "detail",
            "service": "",
        ],
        "weight": [
            "add": "add",
            "manual": "add",
            "history": "records",
            "detail": "detail",
            "service": "",
        ],
        "heart-rate": [
            "add": "add",
            "manual": "add",
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

    /// 健康档案 H5：`#/health/record?token&platform=ios`
    /// 参考宿主文档 `h5接入文档`；「我的」`/me/health-profile` 与健康 Tab `/health/record` 共用。
    static var healthRecordPageURL: URL {
        authenticatedPageURL(path: "health/record")
    }

    /// 体检报告单列表 H5：`#/medical-reports?token&platform=ios`
    static var medicalReportsPageURL: URL {
        authenticatedPageURL(path: "medical-reports")
    }

    /// 上传体检报告 H5：`#/medical-reports/upload?token&platform=ios`
    static var medicalReportsUploadPageURL: URL {
        authenticatedPageURL(path: "medical-reports/upload")
    }

    /// 体检报告详情 H5：`#/medical-reports/detail?token&platform=ios&reportId=`
    static func medicalReportsDetailPageURL(reportId: String) -> URL {
        var extra: [String: String] = [:]
        let trimmed = reportId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            extra["reportId"] = trimmed
        }
        return authenticatedPageURL(path: "medical-reports/detail", extraQuery: extra)
    }

    /// 监测方案 H5：`#/monitoring-plan?token&platform=ios`
    static var monitoringPlanPageURL: URL {
        authenticatedPageURL(path: "monitoring-plan")
    }

    /// 健康评估 H5：`#/health-assessment?token&platform=ios`
    static var healthAssessmentPageURL: URL {
        authenticatedPageURL(path: "health-assessment")
    }

    /// 用药 H5：`#/medication?token&platform=ios`
    static var medicationPageURL: URL {
        authenticatedPageURL(path: "medication")
    }

    /// 营养补剂 H5：`#/supplement?token&platform=ios`
    static var supplementPageURL: URL {
        authenticatedPageURL(path: "supplement")
    }

    /// 血氧 H5：`#/spo2?token&platform=ios`（与 `/health/metrics/spo2` 相同）
    static var spo2PageURL: URL {
        authenticatedPageURL(path: "spo2")
    }

    /// 健康陪伴列表 H5：`#/companion?token&platform=ios`（首页「更多 ›」）
    static var companionPageURL: URL {
        authenticatedPageURL(path: "companion")
    }

    /// 构建任意 H5 鉴权 URL：`{base}#/{path}?token&platform=ios&...`
    /// 含套餐中间页 `package/bridge`（点击后经 `FundeBridge` 打开原生套餐详情）。
    static func authenticatedPageURL(path: String, extraQuery: [String: String] = [:]) -> URL {
        buildAuthenticatedURL(h5Path: path, extraQuery: extraQuery)
    }

    /// 资讯详情 H5：`#/content/detail?id={内容ID}&platform=ios`（本页接口无需登录，token 可选）
    static func contentDetailPageURL(contentId: String) -> URL {
        var extra: [String: String] = [:]
        let trimmed = contentId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            extra["id"] = trimmed
        }
        return authenticatedPageURL(path: "content/detail", extraQuery: extra)
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
        // Hash 路由必须以 `origin/#/path` 打开，不能写成 `origin#/path`；
        // 否则 WebKit 解析文档 URL 异常，相对路径 `./assets/*` 的 JS/CSS 可能加载失败。
        let origin = h5OriginBaseURLString()
        let queryString = queryItems
            .map { key, value in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(encodedKey)=\(encodedValue)"
            }
            .joined(separator: "&")

        let urlString: String
        if queryString.isEmpty {
            urlString = "\(origin)#/\(normalizedPath)"
        } else {
            urlString = "\(origin)#/\(normalizedPath)?\(queryString)"
        }
        return URL(string: urlString) ?? environment.baseURL
    }

    private static func h5OriginBaseURLString() -> String {
        let raw = environment.baseURL.absoluteString
        return raw.hasSuffix("/") ? raw : "\(raw)/"
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
            return URL(string: "https://h5-dev.lianhaojiankang.com")!
//            return URL(string: "http://192.168.15.86:5181")! //跟H5连调
        case .staging:
            return URL(string: "https://staging-h5.lhjk.com")!
        case .production:
            return URL(string: "https://h5.lhjk.com")!
        }
    }
}
