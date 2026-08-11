import Foundation

/// 从 API 响应 body 识别「登录已失效」类业务结果（HTTP 200 + 业务码）
enum SessionInvalidation {

    struct Hit {
        let code: String
        let message: String?
    }

    /// - Returns: 命中会话失效时的信息；未命中返回 nil
    static func inspect(_ data: Data?) -> Hit? {
        guard let data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        let code: String
        if let s = json["code"] as? String {
            code = s
        } else if let i = json["code"] as? Int {
            code = String(i)
        } else {
            return nil
        }

        let msg = json["msg"] as? String
        guard isSessionInvalid(code: code, message: msg) else { return nil }
        return Hit(code: code, message: msg)
    }

    static func isSessionInvalid(code: String, message: String?) -> Bool {
        if code == "A0230" { return true }
        guard let message, !message.isEmpty else { return false }
        let needles = ["登录已失效", "登录状态已过期", "登录失效", "token失效", "Token失效"]
        return needles.contains { message.contains($0) }
    }
}
