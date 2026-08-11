import Foundation
import UIKit

/// 权益卡转赠 → 微信小程序卡片分享参数组装（BLL）
enum BenefitGiftShareBuilder {

    /// 优先使用 `giftBenefit` 返回的 `cards` / `path` / `giftMessage`
    static func miniProgramPayload(
        issue: BenefitsIssueVO,
        fallbackCard: BenefitCard,
        hdImage: UIImage? = nil
    ) -> WeChatMiniProgramSharePayload {
        let operationNo = issue.operationNo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let primary = issue.primaryCard

        let name = nonEmpty(primary?.benefitsName) ?? fallbackCard.name
        let price = primary?.price ?? fallbackCard.amount
        let amountText: String = {
            if price == floor(price) { return "¥\(Int(price))" }
            return String(format: "¥%.2f", price)
        }()

        let title = "赠送你一张权益卡"
        var description = "\(name) · 面值 \(amountText)"
        if let giver = nonEmpty(issue.giverName) {
            description = "\(giver)赠送 · \(description)"
        }
        let msg = nonEmpty(issue.giftMessage) ?? ""
        if !msg.isEmpty {
            description += "\n\(msg)"
        }

        return WeChatMiniProgramSharePayload(
            webpageURL: WeChatConfig.benefitClaimWebpageURL,
            path: resolveSharePath(issue: issue),
            title: title,
            description: description,
            hdImage: hdImage ?? defaultThumbImage(),
            miniProgramType: WeChatConfig.benefitClaimMiniProgramType
        )
    }

    /// 优先服务端 `path`；为空则用本地模板 + `operationNo`
    static func resolveSharePath(issue: BenefitsIssueVO) -> String {
        let serverPath = issue.path?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let no = issue.operationNo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !serverPath.isEmpty {
            if no.isEmpty || serverPath.contains(no) || serverPath.contains("operationNo=") {
                return serverPath
            }
            let sep = serverPath.contains("?") ? "&" : "?"
            let encoded = no.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? no
            return "\(serverPath)\(sep)operationNo=\(encoded)"
        }
        return WeChatConfig.benefitClaimPath(operationNo: no)
    }

    private static func nonEmpty(_ value: String?) -> String? {
        let t = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return t.isEmpty ? nil : t
    }

    private static func defaultThumbImage() -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 64, weight: .medium)
        return UIImage(systemName: "giftcard.fill", withConfiguration: config)?
            .withTintColor(.fdPrimary, renderingMode: .alwaysOriginal)
    }
}
