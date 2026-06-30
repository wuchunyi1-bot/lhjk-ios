import UIKit
import SnapKit

/// 文件 / 音频 / 团队知识 气泡 Cell
final class FileBubbleCell: UITableViewCell {
    static let reuseID = "FileBubbleCell"

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

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.fdBorder.cgColor
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .fdPrimary
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .medium)
        l.textColor = .fdText
        l.numberOfLines = 1
        return l
    }()

    private let sizeLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 12)
        l.textColor = .fdMuted
        return l
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdBg

        [avatarLabel, metaLabel, cardView].forEach(contentView.addSubview)
        [iconView, nameLabel, sizeLabel].forEach(cardView.addSubview)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(_ msg: ChatMessage, tone: String, convRole: ConversationRole) {
        let isStaff = msg.isStaff
        let file = msg.fileContent

        avatarLabel.text = isStaff ? (msg.avatar ?? msg.senderName?.prefix(1).description ?? "?") : "我"
        avatarLabel.backgroundColor = isStaff
            ? UIColor(hexString: tone)
            : UIColor(hexString: "#FF7A50")

        metaLabel.text = isStaff
            ? [msg.senderName, msg.senderRole, msg.time].compactMap { $0 }.joined(separator: " · ")
            : msg.time
        metaLabel.textAlignment = isStaff ? .left : .right

        // 根据文件类型展示不同图标
        let suffix = file?.fileSuffix ?? ""
        switch suffix {
        case "mp3":
            iconView.image = UIImage(systemName: "waveform")
            nameLabel.text = file?.fileName ?? "[音频]"
        case "richText":
            iconView.image = UIImage(systemName: "doc.richtext")
            nameLabel.text = file?.fileName ?? "[团队知识]"
        default:
            iconView.image = UIImage(systemName: "doc.fill")
            nameLabel.text = file?.fileName ?? "[文件]"
        }
        sizeLabel.text = (file?.fileSize).flatMap { $0.isEmpty ? nil : $0 } ?? ""

        layoutForStaff(isStaff)
    }

    private func layoutForStaff(_ isStaff: Bool) {
        avatarLabel.snp.remakeConstraints { make in
            if isStaff {
                make.leading.equalToSuperview().offset(16)
            } else {
                make.trailing.equalToSuperview().offset(-16)
            }
            make.top.equalToSuperview().offset(8)
            make.size.equalTo(34)
        }

        metaLabel.snp.remakeConstraints { make in
            make.top.equalTo(avatarLabel)
            if isStaff {
                make.leading.equalTo(avatarLabel.snp.trailing).offset(8)
            } else {
                make.trailing.equalTo(avatarLabel.snp.leading).offset(-8)
            }
        }

        cardView.snp.remakeConstraints { make in
            make.top.equalTo(metaLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(-8)
            make.width.equalTo(240)
            if isStaff {
                make.leading.equalTo(metaLabel)
            } else {
                make.trailing.equalTo(metaLabel)
            }
        }

        iconView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(36)
        }

        nameLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(iconView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-12)
        }

        sizeLabel.snp.remakeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-12)
        }
    }
}
