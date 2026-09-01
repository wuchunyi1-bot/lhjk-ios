import UIKit
import SnapKit

/// 协议与说明 — 对齐 Figma 4540:7681
final class AgreementCenterViewController: BaseViewController {

    private struct DocItem {
        let label: String
        let desc: String
        let docType: String
    }

    private let docs: [DocItem] = [
        .init(label: "用户协议", desc: "查看平台账号、服务使用与责任说明", docType: "user"),
        .init(label: "隐私政策", desc: "查看个人信息收集、使用与保护说明", docType: "privacy"),
        .init(label: "健康管理服务知情同意书", desc: "查看健康管理服务告知与授权内容", docType: "consent"),
        .init(label: "个人信息收集清单", desc: "查看我们收集的信息类型、使用目的与方式", docType: "personal-info"),
        .init(label: "第三方信息收集清单", desc: "查看第三方服务，共享信息与使用目的", docType: "third-party-sharing"),
        .init(label: "权益卡使用规则", desc: "查看权益卡领取、抵扣、有效期与退款规则", docType: "benefit-card"),
    ]

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = "协议与说明"
        view.backgroundColor = .fdBg

        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        view.addSubview(scroll)
        scroll.snp.makeConstraints { $0.edges.equalToSuperview() }

        let content = UIView()
        scroll.addSubview(content)
        content.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        let card = SettingsDetailSectionCard(sectionTitle: "协议与说明", iconImageName: "settings_files")
        content.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(SettingsStyle.horizontalInset)
            $0.bottom.equalToSuperview().offset(-24)
        }

        let rows = docs.enumerated().map { idx, doc in
            SettingsDocumentRow(
                title: doc.label,
                subtitle: doc.desc,
                showDivider: idx < docs.count - 1
            ) { [weak self] in
                Router.shared.push("/auth/agreement/\(doc.docType)")
            }
        }
        card.setBodyViews(rows)
    }
}
