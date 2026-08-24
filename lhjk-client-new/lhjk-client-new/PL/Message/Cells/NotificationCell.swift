import UIKit
import SnapKit

/// 通知行 Cell — 对齐 Figma 3444:5773（消息首页-通知中心-优化后）
/// 默认通知图标 40 / 标题 16 Medium / 分类标签 C36E20@8% / 时间右对齐 12 / 摘要单行省略
/// 卡片背景置于 Cell 内部，首尾自动切 16pt 圆角，列表滚动时背景随 item 自然移动
final class NotificationCell: UITableViewCell {

    static let reuseIdentifier = "NotificationCell"

    // MARK: - UI

    /// 单行白色卡片容器（左右 inset 12，首尾行根据位置裁切 16pt 圆角）
    private let cardContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.clipsToBounds = true
        return v
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 20
        iv.clipsToBounds = true
        iv.image = UIImage(named: "msg_noti_default_icon")
        return iv
    }()

    private let unreadDot: UIView = {
        let v = UIView()
        v.backgroundColor = .fdDanger
        v.layer.cornerRadius = 4
        v.layer.borderWidth = 1.5
        v.layer.borderColor = UIColor.white.cgColor
        v.isHidden = true
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 18, weight: .medium)
        l.textColor = UIColor(hexString: "#1F2430")
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return l
    }()

    private let tagBadge: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(hexString: "#C36E20")
        l.backgroundColor = UIColor(hexString: "#C36E20").withAlphaComponent(0.08)
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.textAlignment = .center
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(hexString: "#6D7381").withAlphaComponent(0.6)
        l.textAlignment = .right
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }()

    private let bodyLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(hexString: "#6D7381")
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private let separatorLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#EEEEEE")
        return v
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(cardContainer)
        cardContainer.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(12)
        }

        [iconImageView, unreadDot, titleLabel, tagBadge, timeLabel, bodyLabel, separatorLine]
            .forEach(cardContainer.addSubview)

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }

        unreadDot.snp.makeConstraints { make in
            make.top.equalTo(iconImageView).offset(-1)
            make.trailing.equalTo(iconImageView).offset(1)
            make.size.equalTo(8)
        }

        timeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-12)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView).offset(0)
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(tagBadge.snp.leading).offset(-4)
        }

        tagBadge.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.equalTo(titleLabel.snp.trailing).offset(4)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-8)
            make.height.equalTo(18)
        }

        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-12)
        }

        separatorLine.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(_ noti: AppNotification, isFirst: Bool = false, isLast: Bool = false, isSingle: Bool = false) {
        if let customIcon = UIImage(named: noti.icon) {
            iconImageView.image = customIcon
        } else {
            iconImageView.image = UIImage(named: "msg_noti_default_icon")
        }

        titleLabel.text = noti.title
        unreadDot.isHidden = !noti.unread
        timeLabel.text = noti.time
        bodyLabel.text = noti.body
        tagBadge.text = " \(noti.tag) "
        tagBadge.isHidden = noti.tag.trimmingCharacters(in: .whitespaces).isEmpty
        contentView.alpha = noti.unread ? 1.0 : 0.85

        separatorLine.isHidden = isLast || isSingle

        // 动态圆角：单项全圆角，首行上圆角，尾行下圆角，中间无圆角
        if isSingle {
            cardContainer.layer.cornerRadius = 16
            cardContainer.layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner
            ]
        } else if isFirst {
            cardContainer.layer.cornerRadius = 16
            cardContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if isLast {
            cardContainer.layer.cornerRadius = 16
            cardContainer.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            cardContainer.layer.cornerRadius = 0
        }
    }
}
