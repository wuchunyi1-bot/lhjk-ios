import Foundation

/// 微信开放平台移动应用配置（上线前由开发者填入真实值）
///
/// - AppID / Universal Link 须与开放平台、苹果 Associated Domains 一致
/// - `miniProgramUserName` 为关联小程序原始 id（`gh_` 开头），权益卡等分享可复用
enum WeChatConfig {

    /// 开放平台移动应用 AppID（同时作为 URL Scheme）
    static var appId: String = "wx019459b820b44c38"

    /// Universal Link，须以 `/` 结尾，例如 `https://example.com/app/`
    static var universalLink: String = "https://gateway-dev.lianhaojiankang.com/"

    /// 默认分享用小程序原始 id；单次分享可在 payload 覆盖
    static var miniProgramUserName: String = "gh_2b2bf2033426"

    /// 权益卡领取页 path 模板；`{operationNo}` 替换为转赠凭证号
    static var benefitClaimPathTemplate: String = "pages/benefit-card/receive/index?operationNo={operationNo}"

    /// 低版本微信兜底网页（分享小程序必填）
    static var benefitClaimWebpageURL: String = "https://gateway-dev.lianhaojiankang.com/h5/benefit-claim"

    /// 分享小程序版本：开发环境体验版，生产正式版
    static var benefitClaimMiniProgramType: WeChatMiniProgramType {
        switch APIManager.shared.environment {
        case .production: return .release
        case .staging, .development: return .test
        }
    }

    static var isConfigured: Bool {
        let id = appId.trimmingCharacters(in: .whitespacesAndNewlines)
        let link = universalLink.trimmingCharacters(in: .whitespacesAndNewlines)
        return !id.isEmpty && !link.isEmpty
    }

    static func benefitClaimPath(operationNo: String) -> String {
        let no = operationNo.trimmingCharacters(in: .whitespacesAndNewlines)
        let encoded = no.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? no
        return benefitClaimPathTemplate.replacingOccurrences(of: "{operationNo}", with: encoded)
    }
}
