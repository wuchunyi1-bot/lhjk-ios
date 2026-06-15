import UIKit
import SnapKit

/// 健管师团队成员 Cell — 每位成员独立卡片
final class HomeTeamCardCell: UITableViewCell {

    static let reuseID = "HomeTeamCardCell"

    // MARK: - Data types

    struct Member {
        let role: String      // "doctor" / "nutrition" / "manager"
        let initial: String    // 姓
        let name: String
        let title: String
        let tags: String
        let status: String
        let statusType: String // "success" / "primary" / "warning"
    }

    // MARK: - UI

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = 18
        v.addFundeShadow()
        return v
    }()

    private let avatarView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 23
        return v
    }()

    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        return l
    }()

    private let onlineDot: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSuccess
        v.layer.cornerRadius = 5.5
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.white.cgColor
        return v
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = .fdText
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = .fdSubtext
        return l
    }()

    private let tagLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = .fdText2
        l.backgroundColor = .fdBg2
        l.layer.cornerRadius = 6
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()

    private let statusBadge: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 6
        return v
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        return l
    }()

    private let messageButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("发消息", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        btn.setTitleColor(.fdPrimary, for: .normal)
        btn.backgroundColor = .fdPrimarySoft
        btn.layer.cornerRadius = 999
        btn.contentEdgeInsets = UIEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
        return btn
    }()

    // MARK: - Callback

    var onMessageTapped: ((String) -> Void)?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .fdBg
        selectionStyle = .none
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(cardView)

        cardView.addSubview(avatarView)
        avatarView.addSubview(avatarLabel)
        cardView.addSubview(onlineDot)
        cardView.addSubview(nameLabel)
        cardView.addSubview(titleLabel)
        cardView.addSubview(tagLabel)
        statusBadge.addSubview(statusLabel)
        cardView.addSubview(statusBadge)
        cardView.addSubview(messageButton)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }

        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(14)
            make.size.equalTo(46)
        }
        avatarLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        onlineDot.snp.makeConstraints { make in
            make.bottom.equalTo(avatarView).offset(1)
            make.trailing.equalTo(avatarView).offset(1)
            make.size.equalTo(11)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView)
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(nameLabel)
            make.leading.equalTo(nameLabel.snp.trailing).offset(6)
        }

        tagLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.equalTo(nameLabel)
        }

        statusBadge.snp.makeConstraints { make in
            make.centerY.equalTo(tagLabel)
            make.leading.equalTo(tagLabel.snp.trailing).offset(6)
        }
        statusLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 7, bottom: 2, right: 7))
        }

        messageButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-14)
        }

        messageButton.addTarget(self, action: #selector(messageTapped), for: .touchUpInside)

        // 固定行高，确保 cardView 底部有足够间距
        cardView.snp.makeConstraints { make in
            make.height.equalTo(74)
        }
    }

    // MARK: - Configure

    private let roleColors: [String: (bg: UIColor, fg: UIColor)] = [
        "doctor":    (UIColor(hexString: "#EAF3FF"), UIColor(hexString: "#3D6FB8")),
        "nutrition": (UIColor(hexString: "#E6F7EF"), UIColor(hexString: "#1F9A6B")),
        "manager":   (UIColor(hexString: "#FFEFE6"), UIColor(hexString: "#D6602B")),
    ]

    private let statusColors: [String: (bg: UIColor, fg: UIColor)] = [
        "success": (.fdSuccessSoft, .fdSuccess),
        "primary": (.fdPrimarySoft, .fdPrimary),
        "warning": (.fdWarningSoft, UIColor(hexString: "#B47300")),
    ]

    func configure(member: Member) {
        let rc = roleColors[member.role] ?? (.fdBg2, .fdSubtext)
        avatarView.backgroundColor = rc.bg
        avatarLabel.text = member.initial
        avatarLabel.textColor = rc.fg

        nameLabel.text = member.name
        titleLabel.text = member.title
        tagLabel.text = " \(member.tags) "

        let sc = statusColors[member.statusType] ?? (.fdSuccessSoft, .fdSuccess)
        statusBadge.backgroundColor = sc.bg
        statusLabel.text = "● \(member.status)"
        statusLabel.textColor = sc.fg

        messageButton.accessibilityIdentifier = member.name
    }

    @objc private func messageTapped() {
        guard let name = messageButton.accessibilityIdentifier else { return }
        onMessageTapped?(name)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onMessageTapped = nil
    }
}
