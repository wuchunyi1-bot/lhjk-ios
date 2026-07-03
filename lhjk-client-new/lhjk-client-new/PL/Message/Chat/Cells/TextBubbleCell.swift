import UIKit
import SnapKit
import Kingfisher

/// 文本气泡 Cell — staff 左 / user 右
final class TextBubbleCell: UITableViewCell {
    static let reuseID = "TextBubbleCell"

    weak var delegate: ChatCellDelegate?
    private var currentMessage: ChatMessage?

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
        l.font = .fdMicro
        l.textColor = .fdPrimary
        return l
    }()
    private let replyContentLabel: UILabel = {
        let l = UILabel()
        l.font = .fdCaption
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
    private let replyVoiceIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "waveform"))
        iv.tintColor = .fdSubtext
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    private let replyVoiceDurationLabel: UILabel = {
        let l = UILabel()
        l.font = .fdCaption
        l.textColor = .fdSubtext
        return l
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

        metaLabel.font = .fdMicro
        metaLabel.textColor = .fdMuted

        timeLabel.font = .fdMicro
        timeLabel.textColor = .fdMuted

        [avatarLabel, avatarImageView, metaLabel, bubbleView, timeLabel, replyView].forEach(contentView.addSubview)
        bubbleView.addSubview(msgLabel)
        [replyNameLabel, replyContentLabel, replyImageView, replyVoiceIcon, replyVoiceDurationLabel].forEach(replyView.addSubview)

        // replyView 点击手势
        let replyTap = UITapGestureRecognizer(target: self, action: #selector(handleReplyTap))
        replyView.addGestureRecognizer(replyTap)

        msgLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 13, bottom: 10, right: 13)) }

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        bubbleView.addGestureRecognizer(longPress)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentMessage = nil
        // 显式清理所有 SnapKit 约束，避免 remakeConstraints 在复用时不彻底
        [avatarLabel, avatarImageView, metaLabel, bubbleView, timeLabel, replyView].forEach {
            $0.snp.removeConstraints()
        }
        avatarImageView.image = nil
        replyImageView.image = nil
        replyVoiceIcon.isHidden = true
        replyVoiceDurationLabel.text = nil
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let msg = currentMessage else { return }
        delegate?.cellDidLongPress(self, message: msg)
    }

    @objc private func handleReplyTap() {
        guard let msg = currentMessage else { return }
        delegate?.cellDidTapReply(self, message: msg)
    }

    func configure(_ msg: ChatMessage, tone: String, convRole: ConversationRole) {
        currentMessage = msg
        let isStaff = msg.isStaff

        // 每次配置时重设 token 字体，确保 cell 复用时老年模式字号正确
        metaLabel.font = .fdMicro
        timeLabel.font = .fdMicro
        msgLabel.font = .fdBody

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

        // 引用回复 — 按类型展示不同样式
        if let reply = msg.reply {
            replyView.isHidden = false
            replyNameLabel.text = "回复 \(reply.senderName)"

            // 重置所有子视图可见性
            replyContentLabel.isHidden = true
            replyImageView.isHidden = true
            replyVoiceIcon.isHidden = true
            replyVoiceDurationLabel.isHidden = true

            if reply.isImage {
                // 图片引用：缩略图
                replyImageView.isHidden = false
                if let url = URL(string: reply.text), url.scheme?.hasPrefix("http") == true {
                    replyImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
                }
            } else if reply.isVoice {
                // 语音引用：波形图标 + 时长
                replyVoiceIcon.isHidden = false
                replyVoiceDurationLabel.isHidden = false
                if let dur = reply.duration, dur > 0 {
                    replyVoiceDurationLabel.text = "\(dur)\""
                }
            } else if reply.isVideo {
                // 视频引用：封面缩略图
                replyImageView.isHidden = false
                if let url = URL(string: reply.text) {
                    replyImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
                }
            } else {
                // 文本 / 文件 / 套餐：文字
                replyContentLabel.isHidden = false
                if reply.isFile {
                    replyContentLabel.text = "[文件] \(reply.fileName ?? reply.text)"
                } else {
                    replyContentLabel.text = reply.text
                }
            }
        } else {
            replyView.isHidden = true
        }

        // 限制气泡最大宽度：屏幕宽 - 头像区(16+34+9) - 右边距(56) - 气泡内边距(26)
        msgLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 141
        msgLabel.text = msg.text
        layoutForStaff(isStaff, hasReply: msg.reply != nil)
    }

    /// 统一布局入口：prepareForReuse 已清理旧约束，用 makeConstraints 重建
    private func layoutForStaff(_ isStaff: Bool, hasReply: Bool) {
        avatarLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6).priority(999)
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
                if !hasReply { make.bottom.equalToSuperview().offset(-10).priority(999) }
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
                make.height.equalTo(52).priority(999)
                if isStaff {
                    make.leading.equalTo(bubbleView)
                    make.bottom.equalToSuperview().offset(-10).priority(999)
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

            replyVoiceIcon.snp.makeConstraints { make in
                make.top.equalTo(replyNameLabel.snp.bottom).offset(4)
                make.leading.equalToSuperview().offset(8)
                make.size.equalTo(16)
            }
            replyVoiceDurationLabel.snp.makeConstraints { make in
                make.leading.equalTo(replyVoiceIcon.snp.trailing).offset(4)
                make.centerY.equalTo(replyVoiceIcon)
            }
        }

        // user: timeLabel 承接底部，有 reply 时挂在 replyView 下面
        timeLabel.snp.makeConstraints { make in
            if !isStaff {
                make.trailing.equalTo(bubbleView)
                make.top.equalTo((hasReply ? replyView : bubbleView).snp.bottom).offset(2)
                make.bottom.equalToSuperview().offset(-10).priority(999)
            }
        }
    }
}
