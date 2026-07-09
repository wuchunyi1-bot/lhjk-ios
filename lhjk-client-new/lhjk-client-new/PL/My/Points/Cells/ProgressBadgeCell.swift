import UIKit
import SnapKit

final class ProgressBadgeCell: UITableViewCell {

    static let reuseID = "ProgressBadgeCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ b: PtsBadge, isLast: Bool) {
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

        let row = UIStackView()
        row.spacing = 12
        row.alignment = .center
        row.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        row.isLayoutMarginsRelativeArrangement = true
        card.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview() }

        let iconBg = UIView()
        iconBg.layer.cornerRadius = 10
        iconBg.backgroundColor = b.color.withAlphaComponent(0.13)
        iconBg.snp.makeConstraints { $0.size.equalTo(38) }
        let icon = UIImageView(image: UIImage(systemName: b.icon))
        icon.tintColor = b.color
        icon.contentMode = .scaleAspectFit
        iconBg.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(18) }
        row.addArrangedSubview(iconBg)

        let info = UIStackView()
        info.axis = .vertical
        info.spacing = 6
        info.addArrangedSubview({
            let l = UILabel()
            l.text = b.name
            l.font = .fdBodySemibold
            l.textColor = .fdText
            return l
        }())
        let barWrap = UIStackView()
        barWrap.spacing = 8
        barWrap.alignment = .center
        let barBg = UIView()
        barBg.backgroundColor = UIColor(hexString: "#F0ECE8")
        barBg.layer.cornerRadius = 3
        barBg.clipsToBounds = true
        let barFill = UIView()
        barFill.backgroundColor = b.color
        barFill.layer.cornerRadius = 3
        barBg.addSubview(barFill)
        let pct = CGFloat(b.progress ?? 0) / CGFloat(b.target ?? 1)
        barFill.snp.makeConstraints { $0.leading.top.bottom.equalToSuperview(); $0.width.equalToSuperview().multipliedBy(pct) }
        barBg.snp.makeConstraints { $0.height.equalTo(6) }
        barWrap.addArrangedSubview(barBg)
        let cnt = UILabel()
        cnt.text = "\(b.progress ?? 0) / \(b.target ?? 1)"
        cnt.font = .fdMicro
        cnt.textColor = .fdSubtext
        cnt.setContentHuggingPriority(.required, for: .horizontal)
        barWrap.addArrangedSubview(cnt)
        info.addArrangedSubview(barWrap)
        row.addArrangedSubview(info)
    }
}
