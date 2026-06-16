import UIKit
import SnapKit

/// 用户信息卡片 Cell — 头像 + 姓名 + "本人" tag + 档案完整度进度条 + 六维评测按钮
/// 参考 funde-client: hp-header-card
final class HealthRecordUserInfoCell: UITableViewCell {

    static let reuseIdentifier = "HealthRecordUserInfoCell"

    var onSixDimTap: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(userName: String, avatarText: String, archiveProgress: Int) {
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let card = buildCard()

        // Left: avatar + name + progress
        let leftStack = UIStackView()
        leftStack.axis = .horizontal
        leftStack.spacing = 12
        leftStack.alignment = .center

        // Avatar
        let avatarView = buildAvatar(text: avatarText)
        leftStack.addArrangedSubview(avatarView)
        avatarView.snp.makeConstraints { $0.size.equalTo(48) }

        // Meta (name + tag + progress)
        let metaStack = UIStackView()
        metaStack.axis = .vertical
        metaStack.spacing = 4
        metaStack.alignment = .leading

        let nameRow = buildNameRow(name: userName)
        metaStack.addArrangedSubview(nameRow)

        let progressRow = buildProgressRow(percentage: archiveProgress)
        metaStack.addArrangedSubview(progressRow)

        // Progress bar
        let progressBar = buildProgressBar(percentage: archiveProgress)
        metaStack.addArrangedSubview(progressBar)
        progressBar.snp.makeConstraints { make in
            make.width.equalTo(110)
            make.height.equalTo(8)
        }

        leftStack.addArrangedSubview(metaStack)

        card.addSubview(leftStack)
        leftStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        // Right: 六维评测 button
        let sixDimBtn = buildSixDimButton()
        card.addSubview(sixDimBtn)
        sixDimBtn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        sixDimBtn.addTarget(self, action: #selector(didTapSixDim), for: .touchUpInside)

        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
    }

    // MARK: - Building Methods

    private func buildCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        return card
    }

    private func buildAvatar(text: String) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = 24
        container.clipsToBounds = true

        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(hexString: "#F4ECE3").cgColor, UIColor(hexString: "#E8DAC8").cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = CGRect(x: 0, y: 0, width: 48, height: 48)
        container.layer.insertSublayer(gradient, at: 0)

        container.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        container.layer.borderWidth = 2

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = UIColor(hexString: "#7B5E40")
        label.textAlignment = .center
        container.addSubview(label)
        label.snp.makeConstraints { $0.center.equalToSuperview() }

        return container
    }

    private func buildNameRow(name: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6
        row.alignment = .center

        let nameLbl = UILabel()
        nameLbl.text = name
        nameLbl.font = .systemFont(ofSize: 17, weight: .bold)
        nameLbl.textColor = .fdText
        row.addArrangedSubview(nameLbl)

        // "本人" tag
        let tag = buildTag(text: "本人")
        row.addArrangedSubview(tag)

        return row
    }

    private func buildTag(text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .fdPrimarySoft
        container.layer.cornerRadius = 4

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textColor = .fdPrimary
        container.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6)) }

        return container
    }

    private func buildProgressRow(percentage: Int) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 4
        row.alignment = .firstBaseline

        let label = UILabel()
        label.text = "档案完整度"
        label.font = .systemFont(ofSize: 11)
        label.textColor = .fdSubtext
        row.addArrangedSubview(label)

        let pctLabel = UILabel()
        pctLabel.text = "\(percentage)%"
        pctLabel.font = .monospacedSystemFont(ofSize: 14, weight: .bold)
        pctLabel.textColor = .fdPrimary
        row.addArrangedSubview(pctLabel)

        return row
    }

    private func buildProgressBar(percentage: Int) -> UIView {
        let bg = UIView()
        bg.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.14)
        bg.layer.cornerRadius = 4
        bg.clipsToBounds = true

        let fill = UIView()
        fill.backgroundColor = .fdPrimary
        fill.layer.cornerRadius = 4
        bg.addSubview(fill)
        fill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(CGFloat(percentage) / 100.0)
        }

        return bg
    }

    private func buildSixDimButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("六维评测 ›", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .fdPrimary
        btn.layer.cornerRadius = 20
        btn.contentEdgeInsets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
        return btn
    }

    @objc private func didTapSixDim() {
        onSixDimTap?()
    }
}
