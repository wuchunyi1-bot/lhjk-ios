import UIKit
import SnapKit
import Kingfisher

/// 文本气泡 Cell — staff 左 / user 右（Figma 3876:35332）
final class TextBubbleCell: UITableViewCell {
    static let reuseID = "TextBubbleCell"

    weak var delegate: ChatCellDelegate?
    private var currentMessage: ChatMessage?

    private let avatarLabel = UILabel()
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isHidden = true
        return iv
    }()
    private let bubbleBackground = ChatBubbleBackgroundView()
    private let bubbleView = UIView()
    private let msgLabel = UILabel()
    private let metaLabel = UILabel()
    private let timeLabel = UILabel()

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

        avatarLabel.font = .fdFont(ofSize: 15, weight: .bold)
        avatarLabel.textColor = .white
        avatarLabel.textAlignment = .center
        avatarLabel.clipsToBounds = true
        ChatBubbleStyle.configureAvatar(avatarLabel, imageView: avatarImageView)

        msgLabel.font = ChatBubbleStyle.textFont
        msgLabel.numberOfLines = 0

        metaLabel.font = ChatBubbleStyle.metaFont
        metaLabel.textColor = ChatBubbleStyle.metaColor

        timeLabel.font = ChatBubbleStyle.metaFont
        timeLabel.textColor = ChatBubbleStyle.metaColor

        [avatarLabel, avatarImageView, metaLabel, bubbleBackground, bubbleView, timeLabel, replyView].forEach(contentView.addSubview)
        bubbleView.addSubview(msgLabel)
        [replyNameLabel, replyContentLabel, replyImageView, replyVoiceIcon, replyVoiceDurationLabel].forEach(replyView.addSubview)

        let replyTap = UITapGestureRecognizer(target: self, action: #selector(handleReplyTap))
        replyView.addGestureRecognizer(replyTap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        bubbleView.addGestureRecognizer(longPress)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentMessage = nil
        [avatarLabel, avatarImageView, metaLabel, bubbleBackground, bubbleView, timeLabel, replyView].forEach {
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

        metaLabel.font = ChatBubbleStyle.metaFont
        timeLabel.font = ChatBubbleStyle.metaFont
        msgLabel.font = ChatBubbleStyle.textFont

        metaLabel.isHidden = !isStaff
        timeLabel.isHidden = isStaff

        ChatBubbleStyle.applyAvatar(portraitUrl: msg.portraitUrl, label: avatarLabel, imageView: avatarImageView)

        if isStaff {
            metaLabel.text = ChatBubbleStyle.staffMetaText(name: msg.senderName)

            bubbleBackground.tail = .left
            bubbleBackground.fill = .staffGradient
            msgLabel.textColor = ChatBubbleStyle.primaryText
        } else {
            timeLabel.text = msg.time

            bubbleBackground.tail = .right
            bubbleBackground.fill = .userSolid
            msgLabel.textColor = .white
        }

        configureReply(msg.reply)
        msgLabel.preferredMaxLayoutWidth = ChatBubbleStyle.textPreferredMaxWidth()
        let text = RongEmoji.symbolToEmoji(msg.text ?? "")
        msgLabel.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: ChatBubbleStyle.textFont,
                .foregroundColor: msgLabel.textColor ?? ChatBubbleStyle.primaryText,
                .paragraphStyle: ChatBubbleStyle.textParagraphStyle,
            ]
        )
        layoutForStaff(isStaff, hasReply: msg.reply != nil)
    }

    private func configureReply(_ reply: ReplyMessage?) {
        guard let reply else {
            replyView.isHidden = true
            return
        }
        replyView.isHidden = false
        replyNameLabel.text = "回复 \(reply.senderName)"
        replyContentLabel.isHidden = true
        replyImageView.isHidden = true
        replyVoiceIcon.isHidden = true
        replyVoiceDurationLabel.isHidden = true

        if reply.isImage {
            replyImageView.isHidden = false
            if let url = URL(string: reply.text), url.scheme?.hasPrefix("http") == true {
                replyImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
            }
        } else if reply.isVoice {
            replyVoiceIcon.isHidden = false
            replyVoiceDurationLabel.isHidden = false
            if let dur = reply.duration, dur > 0 {
                replyVoiceDurationLabel.text = "\(dur)\""
            }
        } else if reply.isVideo {
            replyImageView.isHidden = false
            if let url = URL(string: reply.text) {
                replyImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
            }
        } else {
            replyContentLabel.isHidden = false
            if reply.isFile {
                replyContentLabel.text = "[文件] \(reply.fileName ?? reply.text)"
            } else {
                replyContentLabel.text = RongEmoji.symbolToEmoji(reply.text)
            }
        }
    }

    private func layoutForStaff(_ isStaff: Bool, hasReply: Bool) {
        let inset = UIEdgeInsets(
            top: ChatBubbleStyle.bubbleInset,
            left: isStaff ? ChatBubbleStyle.bubbleInsetStaff : ChatBubbleStyle.bubbleInset,
            bottom: ChatBubbleStyle.bubbleInset,
            right: ChatBubbleStyle.bubbleInset
        )

        avatarLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6).priority(999)
            make.size.equalTo(ChatBubbleStyle.avatarSize)
            if isStaff {
                make.leading.equalToSuperview().offset(ChatBubbleStyle.horizontalInset)
            } else {
                make.trailing.equalToSuperview().offset(-ChatBubbleStyle.horizontalInset)
            }
        }

        avatarImageView.snp.makeConstraints { make in
            make.edges.equalTo(avatarLabel)
        }

        metaLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarLabel)
            if isStaff {
                make.leading.equalTo(avatarLabel.snp.trailing).offset(ChatBubbleStyle.avatarToContentGap)
            }
        }

        bubbleBackground.snp.makeConstraints { make in
            make.edges.equalTo(bubbleView)
        }

        bubbleView.snp.makeConstraints { make in
            if isStaff {
                make.top.equalTo(metaLabel.snp.bottom).offset(ChatBubbleStyle.nameToBubbleGap)
                make.leading.equalTo(metaLabel)
                make.trailing.lessThanOrEqualToSuperview().offset(-ChatBubbleStyle.oppositeReserve).priority(750)
                if !hasReply { make.bottom.equalToSuperview().offset(-10).priority(999) }
            } else {
                make.top.equalTo(avatarLabel)
                make.trailing.equalTo(avatarLabel.snp.leading).offset(-ChatBubbleStyle.avatarToContentGap)
                make.leading.greaterThanOrEqualToSuperview().offset(ChatBubbleStyle.oppositeReserve).priority(750)
            }
        }

        msgLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(inset)
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

        timeLabel.snp.makeConstraints { make in
            if !isStaff {
                make.trailing.equalTo(bubbleView)
                make.top.equalTo((hasReply ? replyView : bubbleView).snp.bottom).offset(2)
                make.bottom.equalToSuperview().offset(-10).priority(999)
            }
        }
    }
}
