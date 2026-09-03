import Foundation

/// 支付宝开放平台移动应用配置
///
/// - `appId`：开放平台应用 AppID
/// - `urlScheme`：与 Info.plist `CFBundleURLSchemes`、开放平台「iOS 应用 URL Scheme」一致
enum AlipayConfig {

    /// 支付宝应用 AppID
    static var appId: String = "2021006196675244"

    /// 支付完成回调 URL Scheme（默认 `ap` + AppID，须与开放平台及 Info.plist 一致）
    static var urlScheme: String = "ap2021006196675244"

    static var isConfigured: Bool {
        let id = appId.trimmingCharacters(in: .whitespacesAndNewlines)
        let scheme = urlScheme.trimmingCharacters(in: .whitespacesAndNewlines)
        return !id.isEmpty && !scheme.isEmpty
    }
}
