import UIKit
import SnapKit

/// 通知行 Cell — 参考 funde-client MessagesView.vue noti-row
final class NotificationCell: UITableViewCell {

    static let reuseIdentifier = "NotificationCell"

    // MARK: - UI

    private let iconView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        return v
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .bold)
        l.textColor = .fdText
        return l
    }()

    private let unreadDot: UIView = {
        let v = UIView()
        v.backgroundColor = .fdPrimary
        v.layer.cornerRadius = 4
        v.isHidden = true
        return v
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 10)
        l.textColor = .fdMuted
        l.textAlignment = .right
        return l
    }()

    private let bodyLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 12)
        l.textColor = .fdSubtext
        l.numberOfLines = 2
        return l
    }()

    private let tagBadge: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 10)
        l.textColor = .fdSubtext
        l.backgroundColor = .fdBg2
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdSurface

        [iconView, titleLabel, unreadDot, timeLabel, bodyLabel, tagBadge].forEach(contentView.addSubview)
        iconView.addSubview(iconImageView)

        iconView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(14)
            make.size.equalTo(38)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
        }

        unreadDot.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(6)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(8)
        }

        timeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.leading.greaterThanOrEqualTo(unreadDot.snp.trailing).offset(8)
        }

        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(3)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-16)
        }

        tagBadge.snp.makeConstraints { make in
            make.top.equalTo(bodyLabel.snp.bottom).offset(6)
            make.leading.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-14)
            make.height.equalTo(20)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(_ noti: AppNotification) {
        iconView.backgroundColor = UIColor(hexString: noti.iconBg)
        iconImageView.image = UIImage(systemName: noti.icon)
        iconImageView.tintColor = UIColor(hexString: noti.iconColor)

        titleLabel.text = noti.title
        unreadDot.isHidden = !noti.unread
        timeLabel.text = noti.time
        bodyLabel.text = noti.body
        tagBadge.text = " \(noti.tag) "
    }
}
