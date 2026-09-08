import UIKit
import SnapKit
import Kingfisher

/// 群成员行 — 对齐 Figma 4565:9708：独立白卡 + 48 头像 + 姓名 + 角色标签
final class GroupMemberCell: UITableViewCell {

    static let reuseID = "GroupMemberCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        return v
    }()

    private let avatarBackground: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        v.layer.cornerRadius = 24
        return v
    }()

    private let avatarGradient: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor(hexString: "#FFE2D6").cgColor,
            UIColor(hexString: "#FFEFE8").cgColor,
        ]
        g.startPoint = CGPoint(x: 0.5, y: 0)
        g.endPoint = CGPoint(x: 0.5, y: 1)
        return g
    }()

    private let avatarView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 24
        iv.image = ChatBubbleStyle.defaultAvatarImage
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 16, weight: .medium)
        l.textColor = UIColor(hexString: "#1F2430")
        return l
    }()

    private let selfRoleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 12, weight: .regular)
        l.textColor = UIColor(hexString: "#535D72")
        l.text = "我"
        return l
    }()

    private let roleBadge = GroupMemberRoleBadgeView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        avatarBackground.layer.insertSublayer(avatarGradient, at: 0)

        contentView.addSubview(cardView)
        cardView.addSubview(avatarBackground)
        avatarBackground.addSubview(avatarView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(selfRoleLabel)
        cardView.addSubview(roleBadge)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(72)
            make.bottom.equalToSuperview().offset(-12)
        }

        avatarBackground.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(12)
            make.size.equalTo(48)
        }
        avatarView.snp.makeConstraints { $0.edges.equalToSuperview() }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarBackground.snp.trailing).offset(14)
            make.top.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(12)
        }

        selfRoleLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.trailing.lessThanOrEqualToSuperview().inset(12)
        }

        roleBadge.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.trailing.lessThanOrEqualToSuperview().inset(12)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarGradient.frame = avatarBackground.bounds
    }

    func configure(_ member: ImSessionDetails, isSelf: Bool) {
        nameLabel.text = member.displayName
        ChatBubbleStyle.applyAvatar(
            portraitUrl: member.portraitURL,
            label: UILabel(),
            imageView: avatarView
        )

        if isSelf {
            selfRoleLabel.isHidden = false
            roleBadge.isHidden = true
        } else {
            let role = member.displayRole
            selfRoleLabel.isHidden = true
            roleBadge.isHidden = role.isEmpty
            roleBadge.configure(title: role)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.kf.cancelDownloadTask()
        avatarView.image = ChatBubbleStyle.defaultAvatarImage
        nameLabel.text = nil
        roleBadge.configure(title: "")
        roleBadge.isHidden = true
        selfRoleLabel.isHidden = true
    }
}

/// 医护角色标签 — Figma 4565:9818：奶油渐变 + 票券圆角 + `#862804` 字
private final class GroupMemberRoleBadgeView: UIView {

    private let fillGradient: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor(hexString: "#FFECC9").cgColor,
            UIColor(hexString: "#FFF7E3").cgColor,
        ]
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint = CGPoint(x: 1, y: 0.5)
        return g
    }()

    private let maskLayer = CAShapeLayer()

    private let label: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 12, weight: .medium)
        l.textColor = UIColor(hexString: "#862804")
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.insertSublayer(fillGradient, at: 0)
        layer.mask = maskLayer
        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6))
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String) {
        label.text = title
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        fillGradient.frame = bounds
        maskLayer.frame = bounds
        maskLayer.path = Self.ticketPath(in: bounds).cgPath
    }

    /// 左上 / 右下约 8pt，右上 / 左下约 1pt
    private static func ticketPath(in rect: CGRect) -> UIBezierPath {
        let large: CGFloat = 8
        let small: CGFloat = 1
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + large, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - small, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + small),
            controlPoint: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - large))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - large, y: rect.maxY),
            controlPoint: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + small, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - small),
            controlPoint: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + large))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + large, y: rect.minY),
            controlPoint: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.close()
        return path
    }
}
