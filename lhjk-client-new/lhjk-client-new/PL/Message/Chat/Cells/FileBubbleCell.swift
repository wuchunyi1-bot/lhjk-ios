import UIKit
import SnapKit
import Kingfisher

/// 文件气泡 Cell — 对齐 Figma 3941:42353
final class FileBubbleCell: UITableViewCell {
    static let reuseID = "FileBubbleCell"

    weak var delegate: ChatCellDelegate?
    private var currentMessage: ChatMessage?
    var onTapFile: ((ChatMessage) -> Void)?

    private enum Metrics {
        static let bubbleWidth: CGFloat = 251
        static let bubbleHeight: CGFloat = 84
        static let iconSize = CGSize(width: 31, height: 38)
        static let inset: CGFloat = 12
        static let nameIconGap: CGFloat = 12
    }

    private let avatarLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 15, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.clipsToBounds = true
        return label
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isHidden = true
        return imageView
    }()

    private let metaLabel = UILabel()

    private let bubbleBackground = ChatBubbleBackgroundView()
    private let bubbleView = UIView()

    private let fileIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "chat_im_file"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 16, weight: .medium)
        label.textColor = ChatBubbleStyle.primaryText
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingMiddle
        label.textAlignment = .left
        return label
    }()

    private let sizeLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 14)
        label.textColor = ChatBubbleStyle.secondaryText
        label.textAlignment = .left
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdBg

        ChatBubbleStyle.configureAvatar(avatarLabel, imageView: avatarImageView)
        metaLabel.font = ChatBubbleStyle.metaFont
        metaLabel.textColor = ChatBubbleStyle.metaColor

        [avatarLabel, avatarImageView, metaLabel, bubbleBackground, bubbleView].forEach(contentView.addSubview)
        [fileIconView, nameLabel, sizeLabel].forEach(bubbleView.addSubview)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        bubbleView.addGestureRecognizer(longPress)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        bubbleView.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ msg: ChatMessage, tone: String, convRole: ConversationRole) {
        currentMessage = msg
        let isStaff = msg.isStaff
        let file = msg.fileContent

        ChatBubbleStyle.applyAvatar(portraitUrl: msg.portraitUrl, label: avatarLabel, imageView: avatarImageView)

        if isStaff {
            metaLabel.text = ChatBubbleStyle.staffMetaText(name: msg.senderName)
            metaLabel.textAlignment = .left
            bubbleBackground.tail = .left
        } else {
            metaLabel.text = msg.time
            metaLabel.textAlignment = .right
            bubbleBackground.tail = .right
        }
        bubbleBackground.fill = .staffGradient

        nameLabel.text = file?.fileName ?? "[文件]"
        sizeLabel.text = ChatBubbleStyle.displayFileSize(file?.fileSize)

        layoutBubble(isStaff: isStaff)
    }

    private func layoutBubble(isStaff: Bool) {
        avatarLabel.snp.remakeConstraints { make in
            if isStaff {
                make.leading.equalToSuperview().offset(ChatBubbleStyle.horizontalInset)
            } else {
                make.trailing.equalToSuperview().offset(-ChatBubbleStyle.horizontalInset)
            }
            make.top.equalToSuperview().offset(8).priority(999)
            make.size.equalTo(ChatBubbleStyle.avatarSize)
        }
        avatarImageView.snp.remakeConstraints { make in
            make.edges.equalTo(avatarLabel)
        }

        metaLabel.snp.remakeConstraints { make in
            make.top.equalTo(avatarLabel)
            if isStaff {
                make.leading.equalTo(avatarLabel.snp.trailing).offset(ChatBubbleStyle.avatarToContentGap)
            } else {
                make.trailing.equalTo(avatarLabel.snp.leading).offset(-ChatBubbleStyle.avatarToContentGap)
            }
        }

        bubbleBackground.snp.remakeConstraints { make in
            make.edges.equalTo(bubbleView)
        }

        bubbleView.snp.remakeConstraints { make in
            make.top.equalTo(isStaff ? metaLabel.snp.bottom : avatarLabel.snp.top)
                .offset(isStaff ? ChatBubbleStyle.nameToBubbleGap : 0)
            make.bottom.equalToSuperview().offset(-8).priority(999)
            make.width.equalTo(Metrics.bubbleWidth)
            make.height.equalTo(Metrics.bubbleHeight)
            if isStaff {
                make.leading.equalTo(metaLabel)
            } else {
                make.trailing.equalTo(metaLabel)
            }
        }

        // 图标在左，文字在右，均左对齐
        fileIconView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(Metrics.inset)
            make.top.equalToSuperview().offset(Metrics.inset)
            make.size.equalTo(Metrics.iconSize)
        }
        nameLabel.snp.remakeConstraints { make in
            make.leading.equalTo(fileIconView.snp.trailing).offset(Metrics.nameIconGap)
            make.trailing.equalToSuperview().inset(Metrics.inset)
            make.top.equalToSuperview().offset(Metrics.inset)
            make.bottom.lessThanOrEqualTo(sizeLabel.snp.top).offset(-4)
        }
        sizeLabel.snp.remakeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.equalTo(nameLabel)
            make.bottom.equalToSuperview().inset(Metrics.inset)
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let msg = currentMessage else { return }
        delegate?.cellDidLongPress(self, message: msg)
    }

    @objc private func handleTap() {
        guard let msg = currentMessage else { return }
        onTapFile?(msg)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTapFile = nil
        currentMessage = nil
    }
}
