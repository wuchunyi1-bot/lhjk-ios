import UIKit
import SnapKit

/// 绑定权益卡入口 — 对齐 funde `.bind-card-entry`
final class VoucherBindEntryCell: UITableViewCell {
    static let reuseID = "VoucherBindEntryCell"

    var onTap: (() -> Void)?

    private let card = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .fdBg

        card.backgroundColor = .fdPrimarySoft
        card.layer.cornerRadius = 14
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdPrimaryEdge.cgColor
        card.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        let iconBox = UIView()
        iconBox.isUserInteractionEnabled = false
        iconBox.backgroundColor = .fdPrimary
        iconBox.layer.cornerRadius = 10
        let icon = UIImageView(image: UIImage(systemName: "link"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        iconBox.addSubview(icon)

        let title = UILabel()
        title.text = "绑定权益卡"
        title.font = .fdBodyBold
        title.textColor = .fdText
        title.isUserInteractionEnabled = false

        let subtitle = UILabel()
        subtitle.text = "输入卡密或扫码绑定"
        subtitle.font = .fdCaption
        subtitle.textColor = .fdSubtext
        subtitle.isUserInteractionEnabled = false

        let textStack = UIStackView(arrangedSubviews: [title, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.isUserInteractionEnabled = false

        let action = UILabel()
        action.text = "去绑定"
        action.font = .fdCaptionSemibold
        action.textColor = .white
        action.textAlignment = .center
        action.backgroundColor = .fdPrimary
        action.layer.cornerRadius = 16
        action.clipsToBounds = true
        action.isUserInteractionEnabled = false

        contentView.addSubview(card)
        card.addSubview(iconBox)
        card.addSubview(textStack)
        card.addSubview(action)

        card.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(64)
        }
        iconBox.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconBox.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(action.snp.leading).offset(-8)
        }
        action.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
            make.width.greaterThanOrEqualTo(58)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func tapped() { onTap?() }
}
