import UIKit
import SnapKit
import Kingfisher

/// 健管团队整卡 — 对齐 Figma：标题 + 多成员行 + 分割线 + 描边「发消息」
final class HomeTeamCardCell: UITableViewCell {

    static let reuseID = "HomeTeamCardCell"

    struct Member {
        let role: String
        let initial: String
        let name: String
        let title: String
        let tags: String
        let status: String
        let statusType: String
        let groupId: String?
        let imageUrl: String?
        let userId: String?
        /// 本地占位头像（Figma 资源名），API 有 imageUrl 时优先网络图
        let placeholderImageName: String?

        init(
            role: String,
            initial: String,
            name: String,
            title: String,
            tags: String,
            status: String = "",
            statusType: String = "",
            groupId: String? = nil,
            imageUrl: String? = nil,
            userId: String? = nil,
            placeholderImageName: String? = nil
        ) {
            self.role = role
            self.initial = initial
            self.name = name
            self.title = title
            self.tags = tags
            self.status = status
            self.statusType = statusType
            self.groupId = groupId
            self.imageUrl = imageUrl
            self.userId = userId
            self.placeholderImageName = placeholderImageName
        }
    }

    var onMessageTapped: ((Member) -> Void)?
    var onMoreTapped: (() -> Void)?

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = 16
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "我的富德联好健康管家团队"
        l.font = .fdFont(ofSize: 18, weight: .medium)
        l.textColor = .fdText
        return l
    }()

    private let moreButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = .fdFont(ofSize: 14, weight: .regular)
        b.setTitleColor(.fdSubtext, for: .normal)
        return b
    }()

    private let membersStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 0
        return s
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        preservesSuperviewLayoutMargins = false
        contentView.preservesSuperviewLayoutMargins = false
        if #available(iOS 11.0, *) {
            contentView.directionalLayoutMargins = .zero
        }

        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(moreButton)
        cardView.addSubview(membersStack)

        cardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(15)
            $0.trailing.lessThanOrEqualTo(moreButton.snp.leading).offset(-8)
        }
        moreButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(8)
        }
        membersStack.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(8)
        }

        moreButton.addTarget(self, action: #selector(moreTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(members: [Member], serviceDaysLeft: Int? = nil) {
        if let days = serviceDaysLeft, days > 0 {
            moreButton.isHidden = false
            moreButton.setTitle("服务剩余 \(days) 天 ›", for: .normal)
        } else {
            moreButton.isHidden = true
        }
        membersStack.arrangedSubviews.forEach {
            membersStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for (idx, member) in members.enumerated() {
            let row = makeMemberRow(member)
            membersStack.addArrangedSubview(row)
            if idx < members.count - 1 {
                let divWrap = UIView()
                let div = UIView()
                div.backgroundColor = UIColor.fdBorder.withAlphaComponent(0.8)
                divWrap.addSubview(div)
                div.snp.makeConstraints {
                    $0.leading.trailing.equalToSuperview().inset(11)
                    $0.top.bottom.equalToSuperview()
                    $0.height.equalTo(0.5)
                }
                membersStack.addArrangedSubview(divWrap)
            }
        }
    }

    private func makeMemberRow(_ member: Member) -> UIView {
        let row = UIView()

        let avatarBg = UIView()
        avatarBg.backgroundColor = UIColor(hexString: "#EAF3FF")
        avatarBg.layer.cornerRadius = 24
        avatarBg.clipsToBounds = true

        let avatarImage = UIImageView()
        avatarImage.contentMode = .scaleAspectFill
        avatarImage.clipsToBounds = true
        avatarImage.layer.cornerRadius = 24

        let avatarLabel = UILabel()
        avatarLabel.text = member.initial
        avatarLabel.font = .fdH3
        avatarLabel.textColor = UIColor(hexString: "#3D6FB8")
        avatarLabel.textAlignment = .center

        avatarBg.addSubview(avatarLabel)
        avatarBg.addSubview(avatarImage)
        avatarLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        avatarImage.snp.makeConstraints { $0.edges.equalToSuperview() }

        if let urlString = member.imageUrl, let url = URL(string: urlString), !urlString.isEmpty {
            avatarLabel.isHidden = true
            avatarImage.isHidden = false
            let placeholder = UIImage(named: "chat_im_avatar")
            avatarImage.kf.setImage(with: url, placeholder: placeholder, options: [.transition(.fade(0.2))]) { result in
                if case .failure = result {
                    avatarImage.image = placeholder
                    avatarLabel.isHidden = placeholder != nil
                }
            }
        } else {
            avatarImage.isHidden = false
            avatarImage.image = UIImage(named: "chat_im_avatar")
            avatarLabel.isHidden = avatarImage.image != nil
        }

        let nameLabel = UILabel()
        nameLabel.text = member.name
        nameLabel.font = .fdFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .fdText

        let titleBadge = makeTitleBadge(member.title)
        titleBadge.isHidden = member.title.isEmpty

        let tagsRow = UIStackView()
        tagsRow.axis = .horizontal
        tagsRow.spacing = 4
        tagsRow.alignment = .center
        for tag in splitTags(member.tags) {
            tagsRow.addArrangedSubview(makeOutlineTag(tag))
        }
        if !member.status.isEmpty {
            tagsRow.addArrangedSubview(makeStatusBadge(member.status, type: member.statusType))
        }
        tagsRow.isHidden = tagsRow.arrangedSubviews.isEmpty

        let messageBtn = UIButton(type: .system)
        messageBtn.setTitle("发消息", for: .normal)
        messageBtn.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        messageBtn.setTitleColor(.fdPrimary, for: .normal)
        messageBtn.layer.cornerRadius = 14
        messageBtn.layer.borderWidth = 0.5
        messageBtn.layer.borderColor = UIColor.fdPrimary.cgColor
        messageBtn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        messageBtn.addAction(UIAction { [weak self] _ in
            self?.onMessageTapped?(member)
        }, for: .touchUpInside)

        row.addSubview(avatarBg)
        row.addSubview(nameLabel)
        row.addSubview(titleBadge)
        row.addSubview(tagsRow)
        row.addSubview(messageBtn)

        avatarBg.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(11)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().offset(-12)
            $0.size.equalTo(48)
        }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(avatarBg.snp.trailing).offset(14)
            $0.top.equalTo(avatarBg).offset(2)
            if member.title.isEmpty {
                $0.trailing.lessThanOrEqualTo(messageBtn.snp.leading).offset(-8)
            }
        }
        titleBadge.snp.makeConstraints {
            $0.leading.equalTo(nameLabel.snp.trailing).offset(4)
            $0.centerY.equalTo(nameLabel)
            $0.trailing.lessThanOrEqualTo(messageBtn.snp.leading).offset(-8)
        }
        tagsRow.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(6)
            $0.trailing.lessThanOrEqualTo(messageBtn.snp.leading).offset(-8)
        }
        messageBtn.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(13)
            $0.centerY.equalTo(avatarBg)
            $0.width.equalTo(70)
            $0.height.equalTo(28)
        }

        return row
    }

    private func makeTitleBadge(_ title: String) -> UIView {
        let wrap = TitleBadgeView()
        wrap.configure(title: title)
        return wrap
    }

    private func makeOutlineTag(_ text: String) -> UIView {
        let wrap = UIView()
        wrap.layer.cornerRadius = 4
        wrap.layer.borderWidth = 0.5
        wrap.layer.borderColor = UIColor(hexString: "#2B73FF").withAlphaComponent(0.5).cgColor
        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(hexString: "#2B73FF")
        wrap.addSubview(label)
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6))
        }
        return wrap
    }

    private func makeStatusBadge(_ text: String, type: String) -> UIView {
        let wrap = UIView()
        wrap.layer.cornerRadius = 4
        let colors: (UIColor, UIColor) = {
            switch type {
            case "warning": return (UIColor(hexString: "#FFF4EE"), UIColor(hexString: "#FF7802"))
            case "primary": return (UIColor(hexString: "#FFF4EE"), UIColor(hexString: "#FF7802"))
            default: return (UIColor(hexString: "#E6F8F0"), UIColor(hexString: "#2EBA83"))
            }
        }()
        wrap.backgroundColor = colors.0

        let dot = UIView()
        dot.backgroundColor = colors.1
        dot.layer.cornerRadius = 2

        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 12, weight: .medium)
        label.textColor = colors.1

        wrap.addSubview(dot)
        wrap.addSubview(label)
        dot.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(6)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(4)
        }
        label.snp.makeConstraints {
            $0.leading.equalTo(dot.snp.trailing).offset(4)
            $0.trailing.equalToSuperview().inset(6)
            $0.top.bottom.equalToSuperview().inset(2)
        }
        return wrap
    }

    private func splitTags(_ raw: String) -> [String] {
        let separators = CharacterSet(charactersIn: "·|｜,，、")
        return raw
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    @objc private func moreTap() { onMoreTapped?() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onMessageTapped = nil
        onMoreTapped = nil
        membersStack.arrangedSubviews.forEach {
            membersStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

}

// MARK: - Title badge

private final class TitleBadgeView: UIView {
    private let gradient = CAGradientLayer()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradient.colors = [
            UIColor(hexString: "#FFEC90").cgColor,
            UIColor(hexString: "#FFF7E3").cgColor,
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradient, at: 0)
        layer.cornerRadius = 4
        clipsToBounds = true

        label.font = .fdFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(hexString: "#862804")
        addSubview(label)
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6))
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String) {
        label.text = title
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }
}
