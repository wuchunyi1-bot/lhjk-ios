import UIKit
import SnapKit

final class BadgeGridCell: UITableViewCell {

    static let reuseID = "BadgeGridCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ badges: [PtsBadge]) {
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
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 12
        card.addSubview(grid)
        grid.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
        for r in stride(from: 0, to: badges.count, by: 3) {
            let row = UIStackView()
            row.distribution = .fillEqually
            row.spacing = 12
            for c in r..<min(r + 3, badges.count) {
                let b = badges[c]
                let item = UIStackView()
                item.axis = .vertical
                item.alignment = .center
                item.spacing = 6
                let iconBg = UIView()
                iconBg.layer.cornerRadius = 16
                iconBg.backgroundColor = b.color.withAlphaComponent(0.13)
                let icon = UIImageView(image: UIImage(systemName: b.icon))
                icon.tintColor = b.color
                icon.contentMode = .scaleAspectFit
                iconBg.addSubview(icon)
                icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(22) }
                iconBg.snp.makeConstraints { $0.size.equalTo(52) }
                item.addArrangedSubview(iconBg)
                let nm = UILabel()
                nm.text = b.name
                nm.font = .fdMicroSemibold
                nm.textColor = .fdText
                nm.textAlignment = .center
                nm.numberOfLines = 2
                item.addArrangedSubview(nm)
                if let d = b.earnedAt {
                    let dl = UILabel()
                    dl.text = d
                    dl.font = .fdMicro
                    dl.textColor = .fdSubtext
                    dl.textAlignment = .center
                    item.addArrangedSubview(dl)
                }
                row.addArrangedSubview(item)
            }
            for _ in 0..<(3 - (min(r + 3, badges.count) - r)) {
                row.addArrangedSubview(UIView())
            }
            grid.addArrangedSubview(row)
        }
    }
}
