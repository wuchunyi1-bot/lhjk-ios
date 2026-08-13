import UIKit
import SnapKit

/// 通知行 Cell — 对齐 funde-client MessagesView.vue `.noti-row`
final class NotificationCell: UITableViewCell {

    static let reuseIdentifier = "NotificationCell"

    // MARK: - UI

    private let iconView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 12
        v.clipsToBounds = false
        return v
    }()

    private let iconClipView: UIView = {
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

    private let unreadDot: UIView = {
        let v = UIView()
        v.backgroundColor = .fdPrimary
        v.layer.cornerRadius = 5
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.fdSurface.cgColor
        v.isHidden = true
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .semibold)
        l.textColor = .fdText
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return l
    }()

    private let tagBadge: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 10, weight: .medium)
        l.textColor = .fdSubtext
        l.backgroundColor = .fdBg2
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        l.textAlignment = .center
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 10)
        l.textColor = .fdMuted
        l.textAlignment = .right
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }()

    private let bodyLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 12)
        l.textColor = .fdSubtext
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private let separator: UIView = {
        let v = UIView()
        v.backgroundColor = .fdBorder
        return v
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdSurface

        [iconView, titleLabel, tagBadge, timeLabel, bodyLabel, separator].forEach(contentView.addSubview)
        iconView.addSubview(iconClipView)
        iconClipView.addSubview(iconImageView)
        iconView.addSubview(unreadDot)

        iconView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(14)
            make.size.equalTo(38)
            make.bottom.lessThanOrEqualToSuperview().offset(-14)
        }

        iconClipView.snp.makeConstraints { $0.edges.equalToSuperview() }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(18)
        }

        unreadDot.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-3)
            make.trailing.equalToSuperview().offset(3)
            make.size.equalTo(10)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
        }

        tagBadge.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.equalTo(titleLabel.snp.trailing).offset(6)
            make.height.equalTo(16)
        }

        timeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.leading.greaterThanOrEqualTo(tagBadge.snp.trailing).offset(8)
            make.width.equalTo(44)
        }

        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(3)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-14)
        }

        separator.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(_ noti: AppNotification) {
        iconClipView.backgroundColor = UIColor(hexString: noti.iconBg)
        iconImageView.image = UIImage(systemName: noti.icon)
        iconImageView.tintColor = UIColor(hexString: noti.iconColor)

        titleLabel.text = noti.title
        unreadDot.isHidden = !noti.unread
        timeLabel.text = noti.time
        bodyLabel.text = noti.body
        tagBadge.text = " \(noti.tag) "
        contentView.alpha = noti.unread ? 1 : 0.78
    }
}
