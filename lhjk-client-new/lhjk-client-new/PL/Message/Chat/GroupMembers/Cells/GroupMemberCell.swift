import UIKit
import SnapKit

/// 群成员行 — 头像 + 姓名 + 角色
final class GroupMemberCell: UITableViewCell {

    static let reuseID = "GroupMemberCell"

    private let avatarView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        iv.image = ChatBubbleStyle.defaultAvatarImage
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 16, weight: .medium)
        l.textColor = ChatBubbleStyle.primaryText
        return l
    }()

    private let roleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 12, weight: .regular)
        l.textColor = ChatBubbleStyle.secondaryText
        return l
    }()

    private let textStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 4
        s.alignment = .leading
        return s
    }()

    private let separatorLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#EEEEEE")
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white

        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(roleLabel)

        contentView.addSubview(avatarView)
        contentView.addSubview(textStack)
        contentView.addSubview(separatorLine)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        separatorLine.snp.makeConstraints { make in
            make.leading.equalTo(textStack)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ member: ImSessionDetails, isLast: Bool) {
        nameLabel.text = member.displayName
        let role = member.displayRole
        roleLabel.text = role
        roleLabel.isHidden = role.isEmpty

        ChatBubbleStyle.applyAvatar(
            portraitUrl: member.portraitURL,
            label: UILabel(),
            imageView: avatarView
        )
        separatorLine.isHidden = isLast
    }
}
