import UIKit
import SnapKit
import Kingfisher

/// 视频气泡 Cell — 封面图 + 时长 + 播放图标
final class VideoBubbleCell: UITableViewCell {
    static let reuseID = "VideoBubbleCell"

    weak var delegate: ChatCellDelegate?
    private var currentMessage: ChatMessage?

    // MARK: - UI

    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 15, weight: .bold)
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

    private let coverView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = ChatBubbleStyle.cornerLarge
        iv.backgroundColor = UIColor.black.withAlphaComponent(0.08)
        return iv
    }()

    private let playIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let durationLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 13, weight: .medium)
        l.textColor = .white
        l.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdBg

        ChatBubbleStyle.configureAvatar(avatarLabel, imageView: avatarImageView)
        metaLabel.font = ChatBubbleStyle.metaFont
        metaLabel.textColor = ChatBubbleStyle.metaColor

        [avatarLabel, avatarImageView, metaLabel, coverView].forEach(contentView.addSubview)
        coverView.addSubview(playIcon)
        coverView.addSubview(durationLabel)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        coverView.addGestureRecognizer(longPress)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(_ msg: ChatMessage, tone: String, convRole: ConversationRole) {
        currentMessage = msg
        let isStaff = msg.isStaff
        let video = msg.videoContent

        metaLabel.font = ChatBubbleStyle.metaFont

        ChatBubbleStyle.applyAvatar(portraitUrl: msg.portraitUrl, label: avatarLabel, imageView: avatarImageView)

        metaLabel.text = isStaff
            ? ChatBubbleStyle.staffMetaText(name: msg.senderName)
            : msg.time
        metaLabel.textAlignment = isStaff ? .left : .right

        // 封面图
        if let cover = video?.videoCoverImg, let url = URL(string: cover) {
            coverView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            coverView.image = nil
            coverView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        }

        // 时长
        let seconds = video?.videoTime ?? 0
        durationLabel.text = formatDuration(seconds)
        durationLabel.isHidden = seconds <= 0

        layoutForStaff(isStaff)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func layoutForStaff(_ isStaff: Bool) {
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

        coverView.snp.remakeConstraints { make in
            make.top.equalTo(isStaff ? metaLabel.snp.bottom : avatarLabel.snp.top)
                .offset(isStaff ? ChatBubbleStyle.nameToBubbleGap : 0)
            make.bottom.equalToSuperview().offset(-8).priority(999)
            make.width.equalTo(200)
            make.height.equalTo(140).priority(750)
            if isStaff {
                make.leading.equalTo(metaLabel)
            } else {
                make.trailing.equalTo(avatarLabel.snp.leading).offset(-ChatBubbleStyle.avatarToContentGap)
            }
        }

        playIcon.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(44)
        }

        durationLabel.snp.remakeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview().offset(-8)
            make.height.equalTo(20)
            durationLabel.snp.makeConstraints { make in
                make.width.greaterThanOrEqualTo(36)
            }
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let msg = currentMessage else { return }
        delegate?.cellDidLongPress(self, message: msg)
    }
}
