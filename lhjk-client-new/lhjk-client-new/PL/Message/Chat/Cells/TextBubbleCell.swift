import UIKit
import SnapKit
import Kingfisher

/// 文本气泡 Cell — staff 左 / user 右
final class TextBubbleCell: UITableViewCell {
    static let reuseID = "TextBubbleCell"

    private let avatarLabel = UILabel()
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 17
        iv.clipsToBounds = true
        iv.isHidden = true
        return iv
    }()
    private let bubbleView = UIView()
    private let msgLabel = UILabel()
    private let metaLabel = UILabel()   // staff: "name · role · time"
    private let timeLabel = UILabel()   // user: time under bubble

    // 引用回复
    private let replyView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#F5F5F5")
        v.layer.cornerRadius = 6
        v.clipsToBounds = true
        return v
    }()
    private let replyNameLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 11)
        l.textColor = .fdPrimary
        return l
    }()
    private let replyContentLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 12)
        l.textColor = .fdSubtext
        l.numberOfLines = 1
        return l
    }()
    private let replyImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 4
        iv.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        return iv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        avatarLabel.font = .fdFont(ofSize: 13, weight: .bold)
        avatarLabel.textColor = .white
        avatarLabel.textAlignment = .center
        avatarLabel.layer.cornerRadius = 10
        avatarLabel.clipsToBounds = true

        bubbleView.layer.cornerRadius = 15

        msgLabel.font = .fdBody
        msgLabel.numberOfLines = 0

        metaLabel.font = .fdFont(ofSize: 11)
        metaLabel.textColor = .fdMuted

        timeLabel.font = .fdFont(ofSize: 10)
        timeLabel.textColor = .fdMuted

        [avatarLabel, avatarImageView, metaLabel, bubbleView, timeLabel, replyView].forEach(contentView.addSubview)
        bubbleView.addSubview(msgLabel)
        [replyNameLabel, replyContentLabel, replyImageView].forEach(replyView.addSubview)

        msgLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 13, bottom: 10, right: 13)) }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        // 显式清理所有 SnapKit 约束，避免 remakeConstraints 在复用时不彻底
        [avatarLabel, avatarImageView, metaLabel, bubbleView, timeLabel, replyView].forEach {
            $0.snp.removeConstraints()
        }
        avatarImageView.image = nil
        replyImageView.image = nil
    }

    func configure(_ msg: ChatMessage, tone: String, convRole: ConversationRole) {
        let isStaff = msg.isStaff

        metaLabel.isHidden = !isStaff
        timeLabel.isHidden = isStaff

        // 头像：优先加载 portraitUrl 图片，fallback 到文字
        if let urlStr = msg.portraitUrl, !urlStr.isEmpty, let url = URL(string: urlStr) {
            avatarImageView.isHidden = false
            avatarLabel.isHidden = true
            avatarImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            avatarImageView.isHidden = true
            avatarLabel.isHidden = false
        }

        if isStaff {
            avatarLabel.text = msg.avatar ?? ""
            avatarLabel.backgroundColor = UIColor(hexString: tone)
            metaLabel.text = [msg.senderName, msg.senderRole, msg.time].compactMap { $0 }.joined(separator: " · ")

            bubbleView.backgroundColor = .fdSurface
            bubbleView.layer.shadowColor = UIColor.black.cgColor
            bubbleView.layer.shadowOffset = CGSize(width: 0, height: 1)
            bubbleView.layer.shadowRadius = 3
            bubbleView.layer.shadowOpacity = 0.06
            bubbleView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            msgLabel.textColor = .fdText
        } else {
            avatarLabel.text = "我"
            avatarLabel.backgroundColor = UIColor(hexString: tone)
            timeLabel.text = msg.time

            bubbleView.backgroundColor = UIColor(hexString: "#FF7A50")
            bubbleView.layer.shadowColor = nil
            bubbleView.layer.shadowOpacity = 0
            bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            msgLabel.textColor = .white
        }

        // 引用回复
        if let reply = msg.reply {
            replyView.isHidden = false
            replyNameLabel.text = "回复 \(reply.senderName)"
            if reply.messageType == "RC:ImgMsg", let url = URL(string: reply.text) {
                replyImageView.isHidden = false
                replyContentLabel.isHidden = true
                replyImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
            } else {
                replyImageView.isHidden = true
                replyContentLabel.isHidden = false
                replyContentLabel.text = reply.text
            }
        } else {
            replyView.isHidden = true
        }

        msgLabel.text = msg.text
        layoutForStaff(isStaff, hasReply: msg.reply != nil)
    }

    /// 统一布局入口：prepareForReuse 已清理旧约束，用 makeConstraints 重建
    private func layoutForStaff(_ isStaff: Bool, hasReply: Bool) {
        avatarLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.size.equalTo(34)
            if isStaff {
                make.leading.equalToSuperview().offset(16)
            } else {
                make.trailing.equalToSuperview().offset(-16)
            }
        }

        avatarImageView.snp.makeConstraints { make in
            make.edges.equalTo(avatarLabel)
        }

        metaLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarLabel)
            if isStaff {
                make.leading.equalTo(avatarLabel.snp.trailing).offset(9)
            }
        }

        bubbleView.snp.makeConstraints { make in
            if isStaff {
                make.top.equalTo(metaLabel.snp.bottom).offset(4)
                make.leading.equalTo(metaLabel)
                make.trailing.lessThanOrEqualToSuperview().offset(-56).priority(750)
                if !hasReply { make.bottom.equalToSuperview().offset(-10) }
            } else {
                make.top.equalTo(avatarLabel)
                make.trailing.equalTo(avatarLabel.snp.leading).offset(-9)
                make.leading.greaterThanOrEqualToSuperview().offset(56).priority(750)
            }
        }

        if hasReply {
            replyView.snp.makeConstraints { make in
                make.top.equalTo(bubbleView.snp.bottom).offset(4)
                make.width.equalTo(200)
                make.height.equalTo(52)
                if isStaff {
                    make.leading.equalTo(bubbleView)
                    make.bottom.equalToSuperview().offset(-10)
                } else {
                    make.trailing.equalTo(bubbleView)
                }
            }

            replyNameLabel.snp.makeConstraints { make in
                make.top.leading.equalToSuperview().inset(8)
                make.trailing.equalToSuperview().offset(-8)
            }

            replyContentLabel.snp.makeConstraints { make in
                make.top.equalTo(replyNameLabel.snp.bottom).offset(2)
                make.leading.trailing.equalToSuperview().inset(8)
            }

            replyImageView.snp.makeConstraints { make in
                make.top.equalTo(replyNameLabel.snp.bottom).offset(2)
                make.leading.equalToSuperview().offset(8)
                make.size.equalTo(32)
            }
        }

        // user: timeLabel 承接底部，有 reply 时挂在 replyView 下面
        timeLabel.snp.makeConstraints { make in
            if !isStaff {
                make.trailing.equalTo(bubbleView)
                make.top.equalTo((hasReply ? replyView : bubbleView).snp.bottom).offset(2)
                make.bottom.equalToSuperview().offset(-10)
            }
        }
    }
}
