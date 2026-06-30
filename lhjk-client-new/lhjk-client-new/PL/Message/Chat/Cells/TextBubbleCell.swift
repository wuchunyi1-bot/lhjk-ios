import UIKit
import SnapKit

/// 文本气泡 Cell — staff 左 / user 右
final class TextBubbleCell: UITableViewCell {
    static let reuseID = "TextBubbleCell"

    private let avatarLabel = UILabel()
    private let bubbleView = UIView()
    private let msgLabel = UILabel()
    private let metaLabel = UILabel()   // staff: "name · role · time"
    private let timeLabel = UILabel()   // user: time under bubble

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

        [avatarLabel, metaLabel, bubbleView, timeLabel].forEach(contentView.addSubview)
        bubbleView.addSubview(msgLabel)

        msgLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 13, bottom: 10, right: 13)) }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        // 显式清理所有 SnapKit 约束，避免 remakeConstraints 在复用时不彻底
        [avatarLabel, metaLabel, bubbleView, timeLabel].forEach {
            $0.snp.removeConstraints()
        }
    }

    func configure(_ msg: ChatMessage, tone: String, convRole: ConversationRole) {
        let isStaff = msg.isStaff

        metaLabel.isHidden = !isStaff
        timeLabel.isHidden = isStaff

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

        msgLabel.text = msg.text
        layoutForStaff(isStaff)
    }

    /// 统一布局入口：prepareForReuse 已清理旧约束，用 makeConstraints 重建
    private func layoutForStaff(_ isStaff: Bool) {
        avatarLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.size.equalTo(34)
            if isStaff {
                make.leading.equalToSuperview().offset(16)
            } else {
                make.trailing.equalToSuperview().offset(-16)
            }
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
                make.bottom.equalToSuperview().offset(-10)
            } else {
                make.top.equalTo(avatarLabel)
                make.trailing.equalTo(avatarLabel.snp.leading).offset(-9)
                make.leading.greaterThanOrEqualToSuperview().offset(56).priority(750)
            }
        }

        timeLabel.snp.makeConstraints { make in
            if !isStaff {
                make.trailing.equalTo(bubbleView)
                make.top.equalTo(bubbleView.snp.bottom).offset(2)
                make.bottom.equalToSuperview().offset(-10)
            }
        }
    }
}
