import UIKit
import SnapKit
import Kingfisher

/// 套餐 / 系统通知 Cell
final class SysNotifyCell: UITableViewCell {
    static let reuseID = "SysNotifyCell"

    weak var delegate: ChatCellDelegate?
    private var currentMessage: ChatMessage?

    // MARK: - UI

    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 13, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.layer.cornerRadius = 17
        l.clipsToBounds = true
        return l
    }()
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 17
        iv.clipsToBounds = true
        iv.isHidden = true
        return iv
    }()

    private let metaLabel: UILabel = {
        let l = UILabel()
        l.font = .fdMicro
        l.textColor = .fdMuted
        return l
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.fdBorder.cgColor
        return v
    }()

    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = UIColor(hexString: "#FFF8F5")
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 15, weight: .semibold)
        l.textColor = .fdText
        l.numberOfLines = 2
        return l
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.font = .fdBody
        l.textColor = .fdSubtext
        l.numberOfLines = 3
        return l
    }()

    private let actionHint: UILabel = {
        let l = UILabel()
        l.text = "查看详情"
        l.font = .fdFont(ofSize: 12, weight: .medium)
        l.textColor = .fdPrimary
        return l
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdBg

        [avatarLabel, avatarImageView, metaLabel, cardView].forEach(contentView.addSubview)
        [coverImageView, titleLabel, descLabel, actionHint].forEach(cardView.addSubview)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        cardView.addGestureRecognizer(longPress)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(_ msg: ChatMessage, tone: String, convRole: ConversationRole) {
        currentMessage = msg
        let isStaff = msg.isStaff
        let notify = msg.sysNotifyContent

        metaLabel.font = .fdMicro

        let showUser = notify?.isShowUser ?? true

        if showUser {
            if let urlStr = msg.portraitUrl, !urlStr.isEmpty, let url = URL(string: urlStr) {
                avatarImageView.isHidden = false
                avatarLabel.isHidden = true
                avatarImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
            } else {
                avatarImageView.isHidden = true
                avatarLabel.isHidden = false
                avatarLabel.text = isStaff ? (msg.avatar ?? msg.senderName?.prefix(1).description ?? "?") : "我"
                avatarLabel.backgroundColor = isStaff
                    ? UIColor(hexString: tone)
                    : UIColor(hexString: "#FF7A50")
            }
            metaLabel.isHidden = false
            metaLabel.text = isStaff
                ? [msg.senderName, msg.senderRole, msg.time].compactMap { $0 }.joined(separator: " · ")
                : msg.time
            metaLabel.textAlignment = isStaff ? .left : .right
        } else {
            avatarLabel.isHidden = true
            avatarImageView.isHidden = true
            metaLabel.isHidden = true
        }

        titleLabel.text = notify?.title ?? ""
        descLabel.text = notify?.content ?? ""

        if let imgUrl = notify?.imageUrl, let url = URL(string: imgUrl) {
            coverImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
            coverImageView.isHidden = false
        } else {
            coverImageView.isHidden = true
        }

        layoutForStaff(isStaff, hasCover: !coverImageView.isHidden, showUser: showUser)
    }

    private func layoutForStaff(_ isStaff: Bool, hasCover: Bool, showUser: Bool) {
        let metaOffset: ConstraintOffsetTarget = showUser ? 4 : 8

        if showUser {
            avatarLabel.snp.remakeConstraints { make in
                if isStaff {
                    make.leading.equalToSuperview().offset(16)
                } else {
                    make.trailing.equalToSuperview().offset(-16)
                }
                make.top.equalToSuperview().offset(8).priority(999)
                make.size.equalTo(34)
            }
            avatarImageView.snp.remakeConstraints { make in
                make.edges.equalTo(avatarLabel)
            }

            metaLabel.snp.remakeConstraints { make in
                make.top.equalTo(avatarLabel)
                if isStaff {
                    make.leading.equalTo(avatarLabel.snp.trailing).offset(8)
                } else {
                    make.trailing.equalTo(avatarLabel.snp.leading).offset(-8)
                }
            }
        }

        cardView.snp.remakeConstraints { make in
            if showUser {
                make.top.equalTo(metaLabel.snp.bottom).offset(metaOffset)
            } else {
                make.top.equalToSuperview().offset(8).priority(999)
            }
            make.bottom.equalToSuperview().offset(-8).priority(999)
            make.width.equalTo(260)
            if isStaff {
                make.leading.equalToSuperview().offset(showUser ? 58 : 16)
            } else {
                make.trailing.equalToSuperview().offset(showUser ? -58 : -16)
            }
        }

        if hasCover {
            coverImageView.snp.remakeConstraints { make in
                make.top.leading.trailing.equalToSuperview().inset(12)
                make.height.equalTo(120)
            }

            titleLabel.snp.remakeConstraints { make in
                make.top.equalTo(coverImageView.snp.bottom).offset(10)
                make.leading.trailing.equalToSuperview().inset(12)
            }
        } else {
            titleLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(14)
                make.leading.trailing.equalToSuperview().inset(12)
            }
        }

        descLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(12)
        }

        actionHint.snp.remakeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let msg = currentMessage else { return }
        delegate?.cellDidLongPress(self, message: msg)
    }
}
