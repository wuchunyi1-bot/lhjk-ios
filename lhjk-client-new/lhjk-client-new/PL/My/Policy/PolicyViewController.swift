import UIKit
import SnapKit

/// 我的保单
/// 参考 funde-client: PolicyView.vue
final class PolicyViewController: BaseViewController {

    private let scrollView = UIScrollView()

    override func setupUI() {
        title = "我的保单"
        view.backgroundColor = .fdBg

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 20, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }

        let policies: [(name: String, no: String, date: String, benefits: [String])] = [
            ("富德生命终身寿险", "FUDE202200001234", "2022-01-01",
             ["住院医疗保障", "健康管理权益（德好·慢病逆转）", "年度体检套餐"]),
            ("富德生命健康险", "FUDE202300005678", "2023-06-15",
             ["重大疾病保障", "健康管理基础权益"]),
        ]

        for p in policies {
            let card = buildPolicyCard(name: p.name, no: p.no, date: p.date, benefits: p.benefits)
            stack.addArrangedSubview(card)
        }
    }

    private func buildPolicyCard(name: String, no: String, date: String, benefits: [String]) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03

        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.alignment = .center

        let nameLbl = UILabel()
        nameLbl.text = name
        nameLbl.font = .fdBodyBold
        nameLbl.textColor = .fdText

        let tag = buildTag("有效", bg: .fdSuccessSoft, textColor: .fdSuccess)
        headerStack.addArrangedSubview(nameLbl)
        headerStack.addArrangedSubview(UIView())
        headerStack.addArrangedSubview(tag)

        let noLbl = UILabel()
        noLbl.text = "保单号：\(no)"
        noLbl.font = .fdCaption
        noLbl.textColor = .fdSubtext

        let dateLbl = UILabel()
        dateLbl.text = "生效日期：\(date)"
        dateLbl.font = .fdCaption
        dateLbl.textColor = .fdSubtext

        card.addSubview(headerStack)
        card.addSubview(noLbl)
        card.addSubview(dateLbl)

        headerStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        noLbl.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        dateLbl.snp.makeConstraints { make in
            make.top.equalTo(noLbl.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        let divider = UIView()
        divider.backgroundColor = UIColor(hexString: "#F5EDE8")
        card.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.top.equalTo(dateLbl.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(1)
        }

        let benefitsTitle = UILabel()
        benefitsTitle.text = "关联健康权益"
        benefitsTitle.font = .fdCaptionSemibold
        benefitsTitle.textColor = .fdText
        card.addSubview(benefitsTitle)
        benefitsTitle.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        var prevLabel: UIView = benefitsTitle
        for b in benefits {
            let lbl = buildBenefitRow(b)
            card.addSubview(lbl)
            lbl.snp.makeConstraints { make in
                make.top.equalTo(prevLabel.snp.bottom).offset(4)
                make.leading.trailing.equalToSuperview().inset(16)
            }
            prevLabel = lbl
        }
        prevLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
        }

        return card
    }

    private func buildBenefitRow(_ text: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6
        row.alignment = .center

        let check = UIImageView(image: UIImage(systemName: "checkmark"))
        check.tintColor = .fdPrimary
        check.snp.makeConstraints { $0.size.equalTo(14) }

        let label = UILabel()
        label.text = text
        label.font = .fdCaption
        label.textColor = .fdSubtext

        row.addArrangedSubview(check)
        row.addArrangedSubview(label)
        return row
    }

    private func buildTag(_ text: String, bg: UIColor, textColor: UIColor) -> UIView {
        let v = UIView()
        v.backgroundColor = bg
        v.layer.cornerRadius = 999
        let l = UILabel()
        l.text = text
        l.font = .fdMicroSemibold
        l.textColor = textColor
        v.addSubview(l)
        l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        return v
    }
}
