import Foundation

// MARK: - Debug Logger

/// 统一调试日志工具 — 格式化打印请求参数与返回结果，便于运行时排查
enum DebugLogger {

    #if DEBUG
    static var isEnabled = true
    #else
    static var isEnabled = false
    #endif

    private static let maxLogLength = 4_000

    private static let sensitiveKeys: Set<String> = [
        "password", "pwd", "oldpwd", "newpwd", "checkcode", "check_code",
        "code", "secret", "client_secret", "authorization",
        "access_token", "refresh_token", "accesstoken", "refreshtoken", "token",
    ]

    // MARK: - API

    /// 记录 API 请求入参
    static func logAPIRequest(
        method: String,
        url: String,
        parameters: [String: Any]? = nil
    ) {
        guard isEnabled else { return }
        print("[API] → \(method) \(url)")
        let params = formatParameters(parameters)
        if params != "—" {
            print("[API]   Params: \(params)")
        }
    }

    /// 记录 API 响应（原始 JSON + 解析后对象）
    static func logAPIResponse(
        url: String,
        statusCode: Int? = nil,
        rawData: Data? = nil,
        decoded: Any? = nil,
        error: Error? = nil
    ) {
        guard isEnabled else { return }
        let label = URL(string: url)?.lastPathComponent ?? url
        let status = statusCode.map { "HTTP \($0)" } ?? "—"
        print("[API] ← \(status) \(label)")

        if let data = rawData, !data.isEmpty {
            if let raw = String(data: data, encoding: .utf8), !raw.isEmpty {
                print("[API]   Response: \(truncate(raw))")
            } else {
                print("[API]   Response: \(data.count) bytes (binary)")
            }
        }

        if let decoded {
            print("[API]   Decoded: \(formatValue(decoded))")
        }

        if let error {
            print("[API]   Error: \(error.localizedDescription)")
        }
    }

    /// 记录非 APIManager 的 HTTP 请求（如 OSS 直传）
    static func logHTTPRequest(method: String, url: String, bodySize: Int? = nil) {
        guard isEnabled else { return }
        var line = "[HTTP] → \(method) \(url)"
        if let bodySize { line += " | body: \(bodySize) bytes" }
        print(line)
    }

    /// 记录非 APIManager 的 HTTP 响应
    static func logHTTPResponse(url: String, statusCode: Int, body: String? = nil) {
        guard isEnabled else { return }
        let label = URL(string: url)?.lastPathComponent ?? url
        print("[HTTP] ← HTTP \(statusCode) \(label)")
        if let body, !body.isEmpty {
            print("[HTTP]   Response: \(truncate(body))")
        }
    }

    // MARK: - BLL / 通用

    /// 记录方法调用入参
    static func logCall(module: String, function: String, params: [String: Any?] = [:]) {
        guard isEnabled else { return }
        let formatted = params
            .compactMap { key, value -> String? in
                guard let value else { return nil }
                return "\(key)=\(maskIfSensitive(key: key, value: value))"
            }
            .joined(separator: ", ")
        let suffix = formatted.isEmpty ? "" : "(\(formatted))"
        print("[\(module)] \(function)\(suffix)")
    }

    /// 记录方法返回值
    static func logReturn(module: String, function: String, value: Any?) {
        guard isEnabled else { return }
        let result = value.map { formatValue($0) } ?? "nil"
        print("[\(module)] \(function) → \(result)")
    }

    // MARK: - Formatting

    static func formatParameters(_ parameters: [String: Any]?) -> String {
        guard let parameters, !parameters.isEmpty else { return "—" }
        let masked = maskSensitive(in: parameters)
        if let data = try? JSONSerialization.data(
            withJSONObject: masked,
            options: [.prettyPrinted, .sortedKeys]
        ), let str = String(data: data, encoding: .utf8) {
            return str
        }
        return String(describing: masked)
    }

    static func formatValue(_ value: Any) -> String {
        if let dict = value as? [String: Any] {
            return formatParameters(dict)
        }
        if let array = value as? [Any] {
            return truncate(array.map { formatValue($0) }.joined(separator: ", "))
        }
        return truncate(String(describing: value))
    }

    // MARK: - Private

    private static func truncate(_ text: String) -> String {
        guard text.count > maxLogLength else { return text }
        return String(text.prefix(maxLogLength)) + "…(\(text.count) chars)"
    }

    private static func maskIfSensitive(key: String, value: Any) -> String {
        if isSensitiveKey(key) {
            return "****"
        }
        if let str = value as? String, str.count > 8, key.lowercased().contains("token") {
            return "\(str.prefix(8))…"
        }
        return String(describing: value)
    }

    private static func isSensitiveKey(_ key: String) -> Bool {
        let lowered = key.lowercased()
        return sensitiveKeys.contains(lowered)
            || lowered.hasSuffix("password")
            || lowered.hasSuffix("pwd")
            || lowered.contains("token")
            || lowered.contains("secret")
    }

    private static func maskSensitive(in object: Any) -> Any {
        if let dict = object as? [String: Any] {
            var result: [String: Any] = [:]
            for (key, value) in dict {
                if isSensitiveKey(key) {
                    result[key] = "****"
                } else if let nested = value as? [String: Any] {
                    result[key] = maskSensitive(in: nested)
                } else if let array = value as? [Any] {
                    result[key] = array.map { maskSensitive(in: $0) }
                } else if let str = value as? String, str.count > 8, key.lowercased().contains("token") {
                    result[key] = "\(str.prefix(8))…"
                } else {
                    result[key] = value
                }
            }
            return result
        }
        if let array = object as? [Any] {
            return array.map { maskSensitive(in: $0) }
        }
        return object
    }
}
