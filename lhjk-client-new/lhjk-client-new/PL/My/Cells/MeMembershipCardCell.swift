import UIKit
import SnapKit

/// 会员卡入口 Cell
final class MeMembershipCardCell: UITableViewCell {

    static let reuseIdentifier = "MeMembershipCardCell"

    var onTap: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(level: String) {
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let card = UIView()
        card.backgroundColor = UIColor(hexString: "#FFF7F1")
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.2).cgColor
        card.isUserInteractionEnabled = true
        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let titleLbl = label("会员中心", size: 12, weight: .medium, color: .fdSubtext)
        let levelLbl = label(level, size: 13, weight: .bold, color: .fdPrimary)
        let moreLbl = label("查看更多 ›", size: 12, weight: .regular, color: .fdSubtext)

        [titleLbl, levelLbl, moreLbl].forEach(card.addSubview)
        titleLbl.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }
        levelLbl.snp.makeConstraints { $0.top.equalTo(titleLbl.snp.bottom).offset(4); $0.leading.equalToSuperview().inset(16); $0.bottom.equalToSuperview().offset(-16) }
        moreLbl.snp.makeConstraints { $0.centerY.equalToSuperview(); $0.trailing.equalToSuperview().offset(-16) }
    }

    @objc private func didTap() { onTap?() }

    private func label(_ t: String, size: CGFloat, weight: UIFont.Weight, color: UIColor) -> UILabel {
        let l = UILabel(); l.text = t; l.font = .systemFont(ofSize: size, weight: weight); l.textColor = color
        return l
    }
}
