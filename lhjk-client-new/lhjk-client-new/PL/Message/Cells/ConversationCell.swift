import UIKit
import SnapKit

/// 会话行 Cell — 参考 funde-client MessagesView.vue chat-row
final class ConversationCell: UITableViewCell {

    static let reuseIdentifier = "ConversationCell"

    // MARK: - UI

    private let accentBar: UIView = {
        let v = UIView()
        v.backgroundColor = .fdPrimary
        v.layer.cornerRadius = 1.5
        v.isHidden = true
        return v
    }()

    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 17, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        l.layer.cornerRadius = 10
        l.clipsToBounds = true
        return l
    }()

    private let badgeLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 10, weight: .bold)
        l.textColor = .white
        l.backgroundColor = .fdDanger
        l.textAlignment = .center
        l.layer.cornerRadius = 9
        l.clipsToBounds = true
        l.isHidden = true
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 15, weight: .bold)
        l.textColor = .fdText
        return l
    }()

    private let roleTag: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 10)
        l.textColor = .fdSubtext
        l.backgroundColor = .fdBg2
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()

    private let previewLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 12)
        l.textColor = .fdSubtext
        l.numberOfLines = 1
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 10)
        l.textColor = .fdMuted
        l.textAlignment = .right
        return l
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdSurface

        [accentBar, avatarLabel, badgeLabel, nameLabel, roleTag, previewLabel, timeLabel].forEach(contentView.addSubview)

        accentBar.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 0, bottom: 14, right: 0))
            make.width.equalTo(3)
        }

        avatarLabel.snp.makeConstraints { make in
            make.leading.equalTo(accentBar.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(46)
        }

        badgeLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarLabel).offset(-2)
            make.trailing.equalTo(avatarLabel).offset(2)
            make.height.equalTo(18)
            make.width.greaterThanOrEqualTo(18)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarLabel)
            make.leading.equalTo(avatarLabel.snp.trailing).offset(12)
        }

        roleTag.snp.makeConstraints { make in
            make.centerY.equalTo(nameLabel)
            make.leading.equalTo(nameLabel.snp.trailing).offset(6)
            make.height.equalTo(18)
        }

        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.leading.greaterThanOrEqualTo(roleTag.snp.trailing).offset(8)
        }

        previewLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(3)
            make.leading.equalTo(nameLabel)
            make.trailing.lessThanOrEqualTo(timeLabel)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(_ conv: Conversation) {
        avatarLabel.text = conv.avatar
        avatarLabel.backgroundColor = UIColor(hexString: conv.role.toneHex)

        nameLabel.text = conv.name
        roleTag.text = " \(conv.roleLabel) "
        previewLabel.text = conv.lastMessage
        timeLabel.text = conv.lastTime

        accentBar.isHidden = !conv.important

        if let badge = conv.unreadBadge {
            badgeLabel.isHidden = false
            badgeLabel.text = badge
        } else {
            badgeLabel.isHidden = true
        }
    }
}
