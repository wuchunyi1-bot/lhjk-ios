import UIKit
import SnapKit

/// 通知卡片 — 对齐 funde-client NotificationsView.vue `.notif-card`
final class NotificationCardCell: UITableViewCell {

    static let reuseID = "NotificationCardCell"

    private let card = UIView()
    private let iconView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 14
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 4
        card.layer.shadowOpacity = 0.03

        iconView.layer.cornerRadius = 12
        iconView.clipsToBounds = true
        iconImageView.contentMode = .scaleAspectFit

        titleLabel.font = .fdFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = .fdText

        bodyLabel.font = .fdFont(ofSize: 15)
        bodyLabel.textColor = .fdSubtext
        bodyLabel.numberOfLines = 2

        timeLabel.font = .fdFont(ofSize: 14)
        timeLabel.textColor = .fdMuted

        contentView.addSubview(card)
        [iconView, titleLabel, bodyLabel, timeLabel].forEach(card.addSubview)
        iconView.addSubview(iconImageView)

        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-2)
        }

        iconView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(14)
            make.size.equalTo(44)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-14)
        }

        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-14)
        }

        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(bodyLabel.snp.bottom).offset(6)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-14)
            make.bottom.equalToSuperview().offset(-14)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ noti: AppNotification) {
        iconView.backgroundColor = UIColor(hexString: noti.iconBg)
        iconImageView.image = UIImage(systemName: noti.icon)
        iconImageView.tintColor = UIColor(hexString: noti.iconColor)
        titleLabel.text = noti.title
        bodyLabel.text = noti.body
        timeLabel.text = noti.time
        card.alpha = noti.unread ? 1 : 0.78
    }
}
