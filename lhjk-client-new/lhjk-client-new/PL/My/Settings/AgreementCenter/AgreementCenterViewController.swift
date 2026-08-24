import UIKit
import SnapKit

/// 协议与说明 — 对齐 AgreementCenterView.vue / me-settings-agreement-center.page.yaml
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
        .init(label: "第三方信息共享清单", desc: "查看第三方服务、共享信息与使用目的", docType: "third-party-sharing"),
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

        let sectionTitle = UILabel()
        sectionTitle.text = "协议与说明"
        sectionTitle.font = .fdMyCaptionSemibold
        sectionTitle.textColor = .fdSubtext
        content.addSubview(sectionTitle)
        sectionTitle.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        content.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalTo(sectionTitle.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-24)
        }

        let stack = UIStackView()
        stack.axis = .vertical
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        for (idx, doc) in docs.enumerated() {
            stack.addArrangedSubview(makeRow(doc, showDivider: idx < docs.count - 1))
        }
    }

    private func makeRow(_ doc: DocItem, showDivider: Bool) -> UIView {
        let row = UIControl()
        row.addAction(UIAction { [weak self] _ in
            Router.shared.push("/auth/agreement/\(doc.docType)")
        }, for: .touchUpInside)

        let title = UILabel()
        title.text = doc.label
        title.font = .fdMyBodySemibold
        title.textColor = .fdText
        title.numberOfLines = 0
        title.isUserInteractionEnabled = false

        let desc = UILabel()
        desc.text = doc.desc
        desc.font = .fdFont(ofSize: 13, weight: .regular)
        desc.textColor = .fdSubtext
        desc.numberOfLines = 2
        desc.isUserInteractionEnabled = false

        let textStack = UIStackView(arrangedSubviews: [title, desc])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.isUserInteractionEnabled = false

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .fdMuted
        arrow.contentMode = .scaleAspectFit
        arrow.isUserInteractionEnabled = false

        row.addSubview(textStack)
        row.addSubview(arrow)
        textStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalTo(arrow.snp.leading).offset(-12)
            $0.top.equalToSuperview().offset(14)
            $0.bottom.equalToSuperview().offset(-14)
        }
        arrow.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(14)
        }

        if showDivider {
            let divider = UIView()
            divider.backgroundColor = .fdBorder
            row.addSubview(divider)
            divider.snp.makeConstraints {
                $0.leading.equalTo(textStack)
                $0.trailing.bottom.equalToSuperview()
                $0.height.equalTo(1)
            }
        }

        row.snp.makeConstraints { $0.height.greaterThanOrEqualTo(56) }
        return row
    }
}
