import UIKit
import SnapKit

/// 升级套餐 Cell
final class UpgradePlanCell: UITableViewCell {

    static let reuseID = "UpgradePlanCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ p: MbrPlan) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let card = UIView()
        card.backgroundColor = p.highlight ? UIColor(hexString: "#FFF7F1") : .fdSurface
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1.5
        card.layer.borderColor = p.highlight ? UIColor.fdPrimary.withAlphaComponent(0.3).cgColor : p.accent.withAlphaComponent(0.25).cgColor
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16); $0.height.equalTo(72) }

        let name = lbl(p.name, size: 16, weight: .bold, color: p.accent)
        let tag = UIView()
        tag.backgroundColor = p.accent.withAlphaComponent(0.1)
        tag.layer.cornerRadius = 999
        let tl = lbl(p.tag, size: 11, weight: .semibold, color: p.accent)
        tag.addSubview(tl)
        tl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        let info = UIStackView(arrangedSubviews: [name, tag])
        info.axis = .vertical
        info.spacing = 6
        card.addSubview(info)
        info.snp.makeConstraints { $0.leading.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }

        let btn = UIButton(type: .system)
        btn.setTitle("了解", for: .normal)
        btn.titleLabel?.font = .fdCaptionSemibold
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = p.accent
        btn.layer.cornerRadius = 999
        btn.snp.makeConstraints { $0.width.equalTo(52); $0.height.equalTo(28) }
        let priceRow = UIStackView(arrangedSubviews: [
            lbl(p.price, size: 18, weight: .bold, color: .fdPrimary, mono: true),
            lbl(p.unit, size: 12, color: .fdSubtext),
            btn,
        ])
        priceRow.spacing = 4
        priceRow.alignment = .center
        card.addSubview(priceRow)
        priceRow.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview() }
    }

    private func lbl(_ t: String, size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor, mono: Bool = false) -> UILabel {
        let l = UILabel()
        l.text = t
        l.textColor = color
        l.font = mono ? .fdMonoFont(ofSize: size, weight: weight) : .fdFont(ofSize: size, weight: weight)
        return l
    }
}
