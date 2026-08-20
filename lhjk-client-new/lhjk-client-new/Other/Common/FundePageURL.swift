import UIKit

// MARK: - Funde pageUrl 约定

/// `getByCode` / `getCmsConfig` 等返回的 `pageUrl` 统一前缀解析。
///
/// - `FundeH5:` → 后缀为 H5 路由，经 `H5Config` 鉴权后打开 `WebViewController`
/// - `FundeApp:` → 后缀为本地路由，经 `Router.push`
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

    /// 按解析结果打开 H5 或本地路由；无法解析则 no-op
    @MainActor
    static func open(
        _ pageUrl: String?,
        title: String? = nil,
        from viewController: UIViewController? = nil
    ) {
        switch parse(pageUrl) {
        case .h5(let path, let query):
            let url = H5Config.authenticatedPageURL(path: path, extraQuery: query)
            let enablesWeightBle = Self.isWeightH5Path(path)
            let webVC = WebViewController(
                urlString: url.absoluteString,
                title: title,
                enablesWeightBle: enablesWeightBle
            )
            guard let source = viewController else { return }
            if let nav = source.navigationController {
                nav.pushViewController(webVC, animated: true)
            } else {
                source.present(webVC, animated: true)
            }
        case .app(let path, let params):
            guard Router.shared.contains(path) else {
                print("[FundePageURL] skip unregistered app route path=\(path)")
                return
            }
            Router.shared.push(path, params: params, from: viewController)
        case .none:
            break
        }
    }

    /// 是否已按前缀规则解析成功
    static func canOpen(_ pageUrl: String?) -> Bool {
        parse(pageUrl) != .none
    }

    /// `#/weight` 及其子路径需展示体脂秤蓝牙横条
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
