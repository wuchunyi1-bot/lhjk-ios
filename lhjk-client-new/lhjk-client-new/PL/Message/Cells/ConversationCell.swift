import UIKit
import SnapKit

/// 会话行 Cell — 对齐 Figma 3444:5583（消息首页-优化后）
/// 头像 48 / 名称 16 Medium / 角色胶囊 C36E20@8% / 时间右对齐 12 / 预览单行省略
/// 卡片背景置于 Cell 内部，首尾自动切 16pt 圆角，列表滚动时背景随 item 自然移动
final class ConversationCell: UITableViewCell {

    static let reuseIdentifier = "ConversationCell"

    // MARK: - UI

    /// 单行白色卡片容器（左右 inset 12，首尾行根据位置裁切 16pt 圆角）
    private let cardContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.clipsToBounds = true
        return v
    }()

    private let avatarView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 24
        iv.backgroundColor = UIColor(hexString: "#CCDBFF")
        return iv
    }()

    /// 群聊 2×2 拼接头像
    private let collageView: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        v.layer.cornerRadius = 24
        v.backgroundColor = UIColor(hexString: "#CCDBFF")
        v.isHidden = true
        return v
    }()

    private let collageImages: [UIImageView] = (0..<4).map { _ in
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }

    private let avatarPlaceholder: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 18, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        l.backgroundColor = .clear
        l.isHidden = true
        return l
    }()

    private let badgeLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 12, weight: .medium)
        l.textColor = .white
        l.backgroundColor = .fdDanger
        l.textAlignment = .center
        l.layer.cornerRadius = 9
        l.clipsToBounds = true
        l.isHidden = true
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 18, weight: .medium)
        l.textColor = UIColor(hexString: "#1F2430")
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return l
    }()

    private let roleTag: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(hexString: "#C36E20")
        l.backgroundColor = UIColor(hexString: "#C36E20").withAlphaComponent(0.08)
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.textAlignment = .center
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }()

    private let previewLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(hexString: "#6D7381")
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(hexString: "#6D7381").withAlphaComponent(0.6)
        l.textAlignment = .right
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }()

    private let separatorLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#EEEEEE")
        return v
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(cardContainer)
        cardContainer.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(12)
        }

        [avatarView, collageView, badgeLabel, nameLabel, roleTag, previewLabel, timeLabel, separatorLine]
            .forEach(cardContainer.addSubview)
        avatarView.addSubview(avatarPlaceholder)

        // 2×2 collage
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 0.5
        grid.distribution = .fillEqually
        let top = UIStackView(arrangedSubviews: [collageImages[0], collageImages[1]])
        let bottom = UIStackView(arrangedSubviews: [collageImages[2], collageImages[3]])
        [top, bottom].forEach {
            $0.axis = .horizontal
            $0.spacing = 0.5
            $0.distribution = .fillEqually
            grid.addArrangedSubview($0)
        }
        collageView.addSubview(grid)
        grid.snp.makeConstraints { $0.edges.equalToSuperview() }

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
        }
        collageView.snp.makeConstraints { $0.edges.equalTo(avatarView) }
        avatarPlaceholder.snp.makeConstraints { $0.edges.equalToSuperview() }

        badgeLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView).offset(-2)
            make.trailing.equalTo(avatarView).offset(2)
            make.height.equalTo(18)
            make.width.greaterThanOrEqualTo(18)
        }

        timeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-12)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView).offset(2)
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(roleTag.snp.leading).offset(-4)
        }

        roleTag.snp.makeConstraints { make in
            make.centerY.equalTo(nameLabel)
            make.leading.equalTo(nameLabel.snp.trailing).offset(4)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-8)
            make.height.equalTo(18)
        }

        previewLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-12)
        }

        separatorLine.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(_ conv: Conversation, isFirst: Bool = false, isLast: Bool = false, isSingle: Bool = false) {
        applyAvatar(for: conv)

        nameLabel.text = conv.name
        let roleText = Self.displayRoleLabel(conv.roleLabel)
        roleTag.text = " \(roleText) "
        roleTag.isHidden = roleText.trimmingCharacters(in: .whitespaces).isEmpty
        previewLabel.text = conv.lastMessage
        timeLabel.text = conv.lastTime

        if let badge = conv.unreadBadge {
            badgeLabel.isHidden = false
            badgeLabel.text = " \(badge) "
        } else {
            badgeLabel.isHidden = true
        }

        separatorLine.isHidden = isLast || isSingle

        // 动态圆角：单项全圆角，首行上圆角，尾行下圆角，中间无圆角
        if isSingle {
            cardContainer.layer.cornerRadius = 16
            cardContainer.layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner
            ]
        } else if isFirst {
            cardContainer.layer.cornerRadius = 16
            cardContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if isLast {
            cardContainer.layer.cornerRadius = 16
            cardContainer.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            cardContainer.layer.cornerRadius = 0
        }
    }

    // MARK: - Avatar

    private func applyAvatar(for conv: Conversation) {
        if conv.role == .team {
            avatarView.isHidden = true
            collageView.isHidden = false
            avatarPlaceholder.isHidden = true
            let names = ["msg_av_grp_1", "msg_av_grp_2", "msg_av_grp_3", "msg_av_grp_4"]
            for (i, iv) in collageImages.enumerated() {
                iv.image = UIImage(named: names[i])
            }
            return
        }

        collageView.isHidden = true
        avatarView.isHidden = false

        if let img = Self.fallbackAvatar(for: conv) {
            avatarView.image = img
            avatarView.backgroundColor = conv.role == .service
                ? UIColor(hexString: "#FFF2E6")
                : .clear
            avatarView.contentMode = conv.role == .service ? .scaleAspectFit : .scaleAspectFill
            avatarPlaceholder.isHidden = true
        } else {
            avatarView.image = nil
            avatarView.backgroundColor = UIColor(hexString: conv.role.toneHex)
            avatarPlaceholder.text = conv.avatar
            avatarPlaceholder.isHidden = false
        }
    }

    /// Figma 用全角竖线「｜」；本地元数据多为「·」
    private static func displayRoleLabel(_ raw: String) -> String {
        raw.replacingOccurrences(of: " · ", with: "｜")
            .replacingOccurrences(of: "·", with: "｜")
    }

    /// 按 role 回退到 Figma 导出头像 / 图标
    private static func fallbackAvatar(for conv: Conversation) -> UIImage? {
        let name: String?
        switch conv.role {
        case .ai: name = "msg_avatar_ai"
        case .team: name = nil
        case .manager: name = "msg_avatar_wang"
        case .doctor: name = "msg_avatar_zhang"
        case .nutrition: name = "msg_avatar_chen"
        case .service: name = "msg_avatar_family"
        case .caseManager: name = "msg_avatar_liu"
        case .psychology: name = "msg_avatar_lin"
        }
        guard let name else { return nil }
        return UIImage(named: name)
    }
}
