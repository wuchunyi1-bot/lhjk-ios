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

    private let avatarPlaceholder: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 18, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        l.backgroundColor = .clear
        l.isHidden = true
        return l
    }()

    /// 未读徽标：红底容器 + 居中数字（避免 UILabel 固定高度时字形视觉偏上）
    private let badgeView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdDanger
        v.layer.cornerRadius = 9
        v.clipsToBounds = true
        v.isHidden = true
        return v
    }()

    private let badgeLabel = UnreadBadgeCountLabel()

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

        [avatarView, badgeView, nameLabel, roleTag, previewLabel, timeLabel, separatorLine]
            .forEach(cardContainer.addSubview)
        badgeView.addSubview(badgeLabel)
        avatarView.addSubview(avatarPlaceholder)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
        }
        avatarPlaceholder.snp.makeConstraints { $0.edges.equalToSuperview() }

        badgeView.snp.makeConstraints { make in
            make.top.equalTo(avatarView).offset(-2)
            make.trailing.equalTo(avatarView).offset(2)
            make.height.equalTo(18)
            make.width.greaterThanOrEqualTo(18)
        }
        badgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
            badgeView.isHidden = false
            badgeLabel.text = badge
        } else {
            badgeView.isHidden = true
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

    /// 仅保留仍在使用的本地图标；人物/群拼接头像走字母占位
    private static func fallbackAvatar(for conv: Conversation) -> UIImage? {
        switch conv.role {
        case .ai: return UIImage(named: "msg_avatar_ai")
        case .service: return UIImage(named: "msg_avatar_family")
        default: return nil
        }
    }
}

/// 未读数字徽标：在固定高度内按字形边界垂直居中绘制
final class UnreadBadgeCountLabel: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
        font = .fdFont(ofSize: 11, weight: .medium)
        textColor = .white
        textAlignment = .center
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        // 左右各 5pt，保证单数字仍为正圆（≥18）
        return CGSize(width: max(18, ceil(size.width) + 10), height: 18)
    }

    override func drawText(in rect: CGRect) {
        guard let text, let font else {
            super.drawText(in: rect)
            return
        }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor ?? .white,
            .paragraphStyle: paragraph,
        ]
        let size = (text as NSString).boundingRect(
            with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs,
            context: nil
        ).size
        // 光学居中：自定义字体数字常略偏上，整体下移 0.5pt
        let y = rect.midY - size.height / 2 + 0.5
        let drawRect = CGRect(x: rect.minX, y: y, width: rect.width, height: size.height)
        (text as NSString).draw(in: drawRect, withAttributes: attrs)
    }
}
