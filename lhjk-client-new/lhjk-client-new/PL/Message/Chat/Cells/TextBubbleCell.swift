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

    func configure(_ msg: ChatMessage, tone: String, convRole: ConversationRole) {
        let isStaff = msg.isStaff

        avatarLabel.isHidden = !isStaff
        metaLabel.isHidden = !isStaff
        timeLabel.isHidden = false

        if isStaff {
            avatarLabel.text = msg.avatar ?? ""
            avatarLabel.backgroundColor = UIColor(hexString: tone)
            metaLabel.text = [msg.senderName, msg.senderRole].compactMap { $0 }.joined(separator: " · ")

            bubbleView.backgroundColor = .fdSurface
            bubbleView.layer.shadowColor = UIColor.black.cgColor
            bubbleView.layer.shadowOffset = CGSize(width: 0, height: 1)
            bubbleView.layer.shadowRadius = 3
            bubbleView.layer.shadowOpacity = 0.06
            bubbleView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            msgLabel.textColor = .fdText

            avatarLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(6)
                make.leading.equalToSuperview().offset(16)
                make.size.equalTo(34)
            }
            metaLabel.snp.remakeConstraints { make in
                make.top.equalTo(avatarLabel)
                make.leading.equalTo(avatarLabel.snp.trailing).offset(9)
            }
            bubbleView.snp.remakeConstraints { make in
                make.top.equalTo(metaLabel.snp.bottom).offset(4)
                make.leading.equalTo(metaLabel)
                make.trailing.lessThanOrEqualToSuperview().offset(-56)
                make.bottom.equalToSuperview().offset(-10)
            }
            timeLabel.snp.remakeConstraints { make in
                make.leading.equalTo(bubbleView)
                make.top.equalTo(bubbleView.snp.bottom).offset(2)
            }
            timeLabel.text = msg.time
        } else {
            bubbleView.backgroundColor = UIColor(hexString: "#FF7A50")
            bubbleView.layer.shadowColor = nil
            bubbleView.layer.shadowOpacity = 0
            bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            msgLabel.textColor = .white

            avatarLabel.text = "我"
            avatarLabel.backgroundColor = UIColor(hexString: tone)
            avatarLabel.isHidden = false

            bubbleView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(6)
                make.trailing.equalTo(avatarLabel.snp.leading).offset(-9)
                make.leading.greaterThanOrEqualToSuperview().offset(56)
            }
            avatarLabel.snp.remakeConstraints { make in
                make.top.equalTo(bubbleView)
                make.trailing.equalToSuperview().offset(-16)
                make.size.equalTo(34)
            }
            timeLabel.snp.remakeConstraints { make in
                make.trailing.equalTo(bubbleView)
                make.top.equalTo(bubbleView.snp.bottom).offset(2)
                make.bottom.equalToSuperview().offset(-10)
            }
            timeLabel.text = msg.time
        }

        msgLabel.text = msg.text
    }
}
