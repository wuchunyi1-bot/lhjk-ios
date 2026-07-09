import UIKit
import SnapKit

/// 权益清单 Cell — 内嵌 6 行 benefit row
final class BenefitListCell: UITableViewCell {

    static let reuseID = "BenefitListCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ benefits: [MbrBenefit]) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let stack = UIStackView()
        stack.axis = .vertical
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)) }
        for (i, b) in benefits.enumerated() {
            stack.addArrangedSubview(buildRow(b))
            if i < benefits.count - 1 {
                let div = UIView()
                div.backgroundColor = .fdBorder
                stack.addArrangedSubview(div)
                div.snp.makeConstraints { $0.height.equalTo(1) }
            }
        }
    }

    private func buildRow(_ b: MbrBenefit) -> UIView {
        let row = UIStackView()
        row.spacing = 12
        row.alignment = .center
        row.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        row.isLayoutMarginsRelativeArrangement = true
        let iconBg = UIView()
        iconBg.layer.cornerRadius = 11
        iconBg.backgroundColor = b.active ? b.color.withAlphaComponent(0.1) : UIColor(hexString: "#F5F5F5")
        let icon = UIImageView(image: UIImage(systemName: b.icon))
        icon.contentMode = .scaleAspectFit
        icon.tintColor = b.active ? b.color : UIColor(hexString: "#BBBBBB")
        iconBg.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(20) }
        iconBg.snp.makeConstraints { $0.size.equalTo(40) }
        row.addArrangedSubview(iconBg)

        let info = UIStackView()
        info.axis = .vertical
        info.spacing = 2
        info.addArrangedSubview(lbl(b.title, size: 14, weight: .semibold, color: b.active ? .fdText : UIColor(hexString: "#BBBBBB")))
        info.addArrangedSubview(lbl(b.desc, size: 12, color: .fdSubtext))
        row.addArrangedSubview(info)

        let tag = UIView()
        tag.layer.cornerRadius = 999
        tag.backgroundColor = b.active ? UIColor(hexString: "#F0FAF4") : UIColor(hexString: "#F5F5F5")
        let tl = lbl(b.active ? "已激活" : "未开通", size: 11, weight: .semibold, color: b.active ? UIColor(hexString: "#52B96A") : UIColor(hexString: "#BBBBBB"))
        tag.addSubview(tl)
        tl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        row.addArrangedSubview(tag)
        return row
    }

    private func lbl(_ t: String, size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor) -> UILabel {
        let l = UILabel()
        l.text = t
        l.font = .fdFont(ofSize: size, weight: weight)
        l.textColor = color
        return l
    }
}
