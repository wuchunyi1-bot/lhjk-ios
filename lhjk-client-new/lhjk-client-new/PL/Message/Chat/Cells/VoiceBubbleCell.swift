import UIKit
import SnapKit

/// 语音气泡 Cell — 波形图标 + 时长，宽度随 duration 变化
final class VoiceBubbleCell: UITableViewCell {
    static let reuseID = "VoiceBubbleCell"

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

    private let metaLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 10)
        l.textColor = .fdMuted
        return l
    }()

    private let bubbleView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 15
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "waveform"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let durationLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14)
        return l
    }()

    private let unreadDot: UIView = {
        let v = UIView()
        v.backgroundColor = .red
        v.layer.cornerRadius = 4
        v.isHidden = true
        return v
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdBg

        [avatarLabel, metaLabel, bubbleView].forEach(contentView.addSubview)
        [iconView, durationLabel, unreadDot].forEach(bubbleView.addSubview)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(_ msg: ChatMessage, tone: String, convRole: ConversationRole) {
        let isStaff = msg.isStaff
        let seconds = msg.thumbHeight ?? 0

        avatarLabel.text = isStaff ? (msg.avatar ?? msg.senderName?.prefix(1).description ?? "?") : "我"
        avatarLabel.backgroundColor = isStaff
            ? UIColor(hexString: tone)
            : UIColor(hexString: "#FF7A50")

        metaLabel.text = isStaff
            ? [msg.senderName, msg.senderRole, msg.time].compactMap { $0 }.joined(separator: " · ")
            : msg.time
        metaLabel.textAlignment = isStaff ? .left : .right

        durationLabel.text = "\(seconds)\""
        iconView.tintColor = isStaff ? .fdText : .white
        durationLabel.textColor = isStaff ? .fdText : .white
        bubbleView.backgroundColor = isStaff ? .fdSurface : UIColor(hexString: "#FF7A50")

        // staff 图标朝右，user 图标朝左（镜像）
        iconView.transform = isStaff ? .identity : CGAffineTransform(scaleX: -1, y: 1)

        layoutForStaff(isStaff, seconds: seconds)
    }

    private func layoutForStaff(_ isStaff: Bool, seconds: Int) {
        let bubbleWidth = voiceBubbleWidth(seconds: seconds)

        avatarLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.size.equalTo(34)
            if isStaff {
                make.leading.equalToSuperview().offset(16)
            } else {
                make.trailing.equalToSuperview().offset(-16)
            }
        }

        metaLabel.snp.remakeConstraints { make in
            make.top.equalTo(avatarLabel)
            if isStaff {
                make.leading.equalTo(avatarLabel.snp.trailing).offset(8)
            } else {
                make.trailing.equalTo(avatarLabel.snp.leading).offset(-8)
            }
        }

        bubbleView.snp.remakeConstraints { make in
            make.top.equalTo(metaLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(-8)
            make.width.equalTo(bubbleWidth)
            make.height.equalTo(40)
            if isStaff {
                make.leading.equalTo(metaLabel)
            } else {
                make.trailing.equalTo(metaLabel)
            }
        }

        if isStaff {
            iconView.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(12)
                make.centerY.equalToSuperview()
                make.size.equalTo(20)
            }
            durationLabel.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-10)
                make.centerY.equalToSuperview()
            }
            unreadDot.snp.remakeConstraints { make in
                make.leading.equalTo(durationLabel.snp.trailing).offset(4)
                make.centerY.equalTo(durationLabel)
                make.size.equalTo(8)
            }
        } else {
            durationLabel.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(10)
                make.centerY.equalToSuperview()
            }
            iconView.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-12)
                make.centerY.equalToSuperview()
                make.size.equalTo(20)
            }
        }
    }

    /// 气泡宽度随秒数变化：1s=60pt, 60s=160pt
    private func voiceBubbleWidth(seconds: Int) -> CGFloat {
        let minWidth: CGFloat = 60
        let maxWidth: CGFloat = 160
        let width = minWidth + CGFloat(min(seconds, 60)) * (maxWidth - minWidth) / 60.0
        return width
    }
}
