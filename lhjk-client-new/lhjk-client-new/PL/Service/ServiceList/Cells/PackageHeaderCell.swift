import UIKit
import SnapKit

final class PackageHeaderCell: UITableViewCell {
    static let reuseID = "PackageHeaderCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(categoryTitle: String, description: String?) {
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let name = lbl(categoryTitle, size: 15, weight: .bold)
        let descText = (description?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
            ?? "精选健康管理套餐"
        let desc = lbl(descText, size: 11, color: .fdSubtext)
        let info = UIStackView(arrangedSubviews: [name, desc])
        info.axis = .vertical
        info.spacing = 4
        contentView.addSubview(info)
        info.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 12, bottom: 14, right: 12)) }

        let div = UIView()
        div.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.27)
        contentView.addSubview(div)
        div.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
    }

    func configure(_ m: SvcMatrix) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let icon = UIView()
        icon.layer.cornerRadius = 12
        icon.layer.borderWidth = 1
        icon.backgroundColor = m.accent.withAlphaComponent(0.09)
        icon.layer.borderColor = m.accent.withAlphaComponent(0.2).cgColor
        let il = UILabel()
        il.text = m.code
        il.font = .fdBodyBold
        il.textColor = m.accent
        il.textAlignment = .center
        icon.addSubview(il)
        il.snp.makeConstraints { $0.center.equalToSuperview() }
        icon.snp.makeConstraints { $0.size.equalTo(44) }

        let name = lbl(m.name, size: 15, weight: .bold)
        let desc = lbl(m.desc, size: 11, color: .fdSubtext)
        let tier = lbl(m.tier, size: 10, weight: .semibold, color: m.accent)
        let info = UIStackView(arrangedSubviews: [name, desc, tier])
        info.axis = .vertical
        info.spacing = 2
        let row = UIStackView(arrangedSubviews: [icon, info])
        row.spacing = 12
        row.alignment = .center
        contentView.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 12, bottom: 14, right: 12)) }

        let div = UIView()
        div.backgroundColor = m.accent.withAlphaComponent(0.27)
        contentView.addSubview(div)
        div.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
    }

    private func lbl(_ t: String, size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor = .fdText) -> UILabel {
        let l = UILabel()
        l.text = t
        l.font = .fdFont(ofSize: size, weight: weight)
        l.textColor = color
        return l
    }
}
