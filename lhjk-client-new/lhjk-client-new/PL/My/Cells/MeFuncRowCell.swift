import UIKit
import SnapKit

/// 通用功能行 Cell — icon + label + detail + chevron
final class MeFuncRowCell: UITableViewCell {

    static let reuseIdentifier = "MeFuncRowCell"

    struct RowData {
        let icon: String; let color: UIColor
        let title: String; let detail: String?
        let showDivider: Bool
    }

    var onTap: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(data: RowData) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        backgroundColor = .clear

        let card = UIView()
        card.backgroundColor = .fdSurface
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)) }

        let iconContainer = UIView()
        iconContainer.backgroundColor = data.color.withAlphaComponent(0.10)
        iconContainer.layer.cornerRadius = 10
        let iconImg = UIImageView(image: UIImage(systemName: data.icon))
        iconImg.tintColor = data.color; iconImg.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconImg)

        let titleLbl = UILabel()
        titleLbl.text = data.title; titleLbl.font = .fdBody; titleLbl.textColor = .fdText

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .fdMuted; arrow.contentMode = .scaleAspectFit

        card.addSubview(iconContainer); card.addSubview(titleLbl); card.addSubview(arrow)
        iconContainer.snp.makeConstraints { $0.leading.equalToSuperview().inset(16); $0.centerY.equalToSuperview(); $0.size.equalTo(32) }
        iconImg.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(18) }
        titleLbl.snp.makeConstraints { $0.leading.equalTo(iconContainer.snp.trailing).offset(12); $0.centerY.equalToSuperview() }
        arrow.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview(); $0.size.equalTo(16) }

        if let detail = data.detail {
            let detailLbl = UILabel()
            detailLbl.text = detail; detailLbl.font = .fdCaption; detailLbl.textColor = .fdMuted
            card.addSubview(detailLbl)
            detailLbl.snp.makeConstraints { $0.trailing.equalTo(arrow.snp.leading).offset(-4); $0.centerY.equalToSuperview() }
            titleLbl.snp.remakeConstraints { $0.leading.equalTo(iconContainer.snp.trailing).offset(12); $0.centerY.equalToSuperview(); $0.trailing.lessThanOrEqualTo(detailLbl.snp.leading).offset(-8) }
        }

        if data.showDivider {
            let divider = UIView(); divider.backgroundColor = .fdBorder
            card.addSubview(divider)
            divider.snp.makeConstraints { $0.leading.equalTo(titleLbl); $0.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
        }

        card.snp.makeConstraints { $0.height.equalTo(48) }

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true
    }

    @objc private func didTap() { onTap?() }
}
