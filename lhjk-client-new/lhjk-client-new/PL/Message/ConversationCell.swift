import UIKit
import SnapKit

/// 会话列表 Cell — 参考 funde-im ConvoItem.vue
final class ConversationCell: UITableViewCell {

    static let reuseIdentifier = "ConversationCell"

    private let avatarView: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .medium)
        l.textColor = .white
        l.textAlignment = .center
        l.layer.cornerRadius = 22
        l.clipsToBounds = true
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 16, weight: .bold); l.textColor = .fdText
        return l
    }()

    private let teamLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 12); l.textColor = .fdSubtext
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 12); l.textColor = .fdMuted; l.textAlignment = .right
        return l
    }()

    private let previewLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 14); l.textColor = .fdSubtext; l.numberOfLines = 1
        return l
    }()

    private let badgeView: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .bold); l.textColor = .white
        l.backgroundColor = .fdDanger; l.textAlignment = .center
        l.layer.cornerRadius = 10; l.clipsToBounds = true
        l.isHidden = true
        return l
    }()

    private let priorityBar: UIView = {
        let v = UIView(); v.layer.cornerRadius = 1.5; v.isHidden = true
        return v
    }()

    private let tagStack: UIStackView = {
        let s = UIStackView(); s.axis = .horizontal; s.spacing = 4; s.alignment = .center
        return s
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        [priorityBar, avatarView, nameLabel, teamLabel, timeLabel, previewLabel, badgeView, tagStack].forEach(contentView.addSubview)

        priorityBar.snp.makeConstraints { $0.leading.equalToSuperview(); $0.top.bottom.equalToSuperview().inset(12); $0.width.equalTo(3) }
        avatarView.snp.makeConstraints { $0.leading.equalTo(priorityBar.snp.trailing).offset(16); $0.centerY.equalToSuperview(); $0.size.equalTo(44) }
        nameLabel.snp.makeConstraints { $0.top.equalTo(avatarView); $0.leading.equalTo(avatarView.snp.trailing).offset(12) }
        teamLabel.snp.makeConstraints { $0.centerY.equalTo(nameLabel); $0.leading.equalTo(nameLabel.snp.trailing).offset(6) }
        timeLabel.snp.makeConstraints { $0.top.equalTo(avatarView); $0.trailing.equalToSuperview().offset(-16) }
        previewLabel.snp.makeConstraints { $0.top.equalTo(nameLabel.snp.bottom).offset(4); $0.leading.equalTo(nameLabel); $0.trailing.lessThanOrEqualTo(badgeView.snp.leading).offset(-8) }
        badgeView.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.bottom.equalTo(previewLabel); $0.size.equalTo(20) }
        tagStack.snp.makeConstraints { $0.top.equalTo(previewLabel.snp.bottom).offset(6); $0.leading.equalTo(nameLabel); $0.bottom.lessThanOrEqualToSuperview().offset(-12) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ c: Conversation) {
        avatarView.text = c.avatarChar
        avatarView.backgroundColor = avatarColor(for: c.name)
        nameLabel.text = c.name
        teamLabel.text = c.doctorTeam
        timeLabel.text = timeFormat(c.lastMessageAt)
        previewLabel.text = c.preview
        badgeView.isHidden = c.unreadCount == 0
        badgeView.text = c.unreadCount > 99 ? "99+" : "\(c.unreadCount)"
        priorityBar.isHidden = c.priority != .high
        priorityBar.backgroundColor = c.priority == .high ? .fdPrimary : .clear

        tagStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for tag in c.tags {
            tagStack.addArrangedSubview(makeTagPill(tag))
        }
    }

    private func makeTagPill(_ tag: ConversationTag) -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: tag.bgColor); v.layer.cornerRadius = 999
        let l = UILabel(); l.text = tag.label; l.font = .systemFont(ofSize: 10, weight: .semibold); l.textColor = UIColor(hexString: tag.textColor)
        v.addSubview(l)
        l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        return v
    }

    private func timeFormat(_ date: Date) -> String {
        let fmt = DateFormatter()
        if Calendar.current.isDateInToday(date) { fmt.dateFormat = "HH:mm" }
        else if Calendar.current.isDate(date, equalTo: .init(), toGranularity: .weekOfYear) { fmt.dateFormat = "EEE" }
        else { fmt.dateFormat = "MM/dd" }
        return fmt.string(from: date)
    }

    private func avatarColor(for name: String) -> UIColor {
        let colors: [UIColor] = [UIColor(hexString: "#FF7A50"), UIColor(hexString: "#5C8DC9"), UIColor(hexString: "#2DB983"), UIColor(hexString: "#F5A524"), UIColor(hexString: "#7B5E9F"), UIColor(hexString: "#E5564B"), UIColor(hexString: "#3D6FB8")]
        return colors[abs(name.hashValue) % colors.count]
    }
}
