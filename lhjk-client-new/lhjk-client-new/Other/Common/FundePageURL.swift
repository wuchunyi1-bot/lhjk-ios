import UIKit

// MARK: - Funde pageUrl 约定

/// `getByCode` / `getCmsConfig` 等返回的 `pageUrl` 统一前缀解析。
///
/// - `FundeH5:` → 后缀为 H5 路由，经 `H5Config` 鉴权后打开 `WebViewController`（不要求本地 metric 路由已注册）
/// - `FundeApp:` → 后缀为本地路由，经 `Router.push`；未注册则跳过
///
/// OpenSpec: `openspec/changes/funde-page-url-scheme/`
enum FundePageURL {

    static let h5Prefix = "FundeH5:"
    static let appPrefix = "FundeApp:"

    enum Destination: Equatable {
        /// H5 hash 路由 path（不含 `#/`），及可选 query
        case h5(path: String, query: [String: String])
        /// 本地路由 path（以 `/` 开头）及 params
        case app(path: String, params: [String: String])
        case none
    }

    /// 解析 pageUrl；无法识别则 `.none`
    static func parse(_ pageUrl: String?) -> Destination {
        let trimmed = pageUrl?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return .none }

        if trimmed.hasPrefix(h5Prefix) {
            let remainder = String(trimmed.dropFirst(h5Prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = splitPathAndQuery(remainder)
            let path = normalizeH5Path(parts.path)
            guard !path.isEmpty else { return .none }
            return .h5(path: path, query: parts.query)
        }

        if trimmed.hasPrefix(appPrefix) {
            let remainder = String(trimmed.dropFirst(appPrefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = splitPathAndQuery(remainder)
            let path = normalizeAppPath(parts.path)
            guard !path.isEmpty else { return .none }
            return .app(path: path, params: parts.query)
        }

        return .none
    }

    /// 按解析结果打开。`FundeH5:` 一律打开 H5 地址；`FundeApp:` 仅已注册本地路由才 push。
    /// - Returns: 已打开则为 `true`；无法解析或 `FundeApp` 未注册则为 `false`（调用方可走业务兜底）
    @discardableResult
    @MainActor
    static func open(
        _ pageUrl: String?,
        title: String? = nil,
        from viewController: UIViewController? = nil
    ) -> Bool {
        switch parse(pageUrl) {
        case .h5(let path, let query):
            let url = H5Config.authenticatedPageURL(path: path, extraQuery: query)
            let enablesWeightBle = Self.shouldEnableWeightBle(forH5Path: path)
            let webVC = WebViewController(
                urlString: url.absoluteString,
                title: title,
                enablesWeightBle: enablesWeightBle
            )
            guard let source = viewController else { return true }
            if let nav = source.navigationController {
                nav.pushViewController(webVC, animated: true)
            } else {
                source.present(webVC, animated: true)
            }
            return true
        case .app(let path, let params):
            guard Router.shared.contains(path) else {
                print("[FundePageURL] skip unregistered app route path=\(path)")
                return false
            }
            Router.shared.push(path, params: params, from: viewController)
            return true
        case .none:
            return false
        }
    }

    /// 已按前缀解析为 `FundeH5:` 或 `FundeApp:`（不检查 Router 是否已注册）
    static func canOpen(_ pageUrl: String?) -> Bool {
        parse(pageUrl) != .none
    }

    /// 仅 `#/weight` 体重 H5 首页展示体脂秤蓝牙横条并启扫；跳转其他页面隐藏并关闭蓝牙
    static func shouldEnableWeightBle(forH5Path path: String) -> Bool {
        let normalized = path
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return normalized == "weight"
    }

    /// 是否体重 H5 路径（含首页及子页面）
    static func isWeightH5Path(_ path: String) -> Bool {
        let normalized = path
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return normalized == "weight" || normalized.hasPrefix("weight/")
    }

    // MARK: - Helpers

    private static func splitPathAndQuery(_ raw: String) -> (path: String, query: [String: String]) {
        guard let qIndex = raw.firstIndex(of: "?") else {
            return (raw, [:])
        }
        let path = String(raw[..<qIndex])
        let queryString = String(raw[raw.index(after: qIndex)...])
        var query: [String: String] = [:]
        for pair in queryString.split(separator: "&") where !pair.isEmpty {
            let kv = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            let key = kv.first.map(String.init)?.removingPercentEncoding
                ?? kv.first.map(String.init)
                ?? ""
            guard !key.isEmpty else { continue }
            let value: String
            if kv.count > 1 {
                let rawValue = String(kv[1])
                value = rawValue.removingPercentEncoding ?? rawValue
            } else {
                value = ""
            }
            query[key] = value
        }
        return (path, query)
    }

    private static func normalizeH5Path(_ raw: String) -> String {
        var path = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if path.hasPrefix("#/") {
            path = String(path.dropFirst(2))
        } else if path.hasPrefix("#") {
            path = String(path.dropFirst())
        }
        while path.hasPrefix("/") {
            path = String(path.dropFirst())
        }
        return path.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizeAppPath(_ raw: String) -> String {
        var path = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if path.hasPrefix("#/") {
            path = String(path.dropFirst(2))
        }
        guard !path.isEmpty else { return "" }
        if !path.hasPrefix("/") {
            path = "/" + path
        }
        return path
    }
}
