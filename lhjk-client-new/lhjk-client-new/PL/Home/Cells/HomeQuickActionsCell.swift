import UIKit
import SnapKit

/// 快捷操作区 — 对齐 Figma：白卡 16 圆角 + 统一暖橙圆形图标
final class HomeQuickActionsCell: UITableViewCell {

    static let reuseID = "HomeQuickActionsCell"

    struct Action {
        let icon: String
        let title: String
        let bgColor: UIColor
        let iconColor: UIColor
        let route: String
    }

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = 16
        return v
    }()

    private let stackView: UIStackView = {
        let s = UIStackView()
        s.distribution = .fillEqually
        s.spacing = 0
        return s
    }()

    var onActionTapped: ((String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = false
        contentView.clipsToBounds = false
        contentView.addSubview(cardView)
        cardView.addSubview(stackView)
        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16).priority(750)
            make.bottom.equalToSuperview()
            make.height.equalTo(104)
        }
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(actions: [Action]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for act in actions {
            stackView.addArrangedSubview(makeActionItem(act))
        }
    }

    private func makeActionItem(_ action: Action) -> UIView {
        let item = UIView()

        let iconBg = UIView()
        iconBg.backgroundColor = UIColor(hexString: "#FFF3EE")
        iconBg.layer.cornerRadius = 24

        let icon = UIImageView(image: UIImage(systemName: action.icon))
        icon.tintColor = .fdPrimary
        icon.contentMode = .scaleAspectFit
        iconBg.addSubview(icon)
        icon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(22)
        }

        let lbl = UILabel()
        lbl.text = action.title
        lbl.font = .fdFont(ofSize: 12, weight: .regular)
        lbl.textColor = .fdText
        lbl.textAlignment = .center

        item.addSubview(iconBg)
        item.addSubview(lbl)
        iconBg.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
            $0.size.equalTo(48)
        }
        lbl.snp.makeConstraints {
            $0.top.equalTo(iconBg.snp.bottom).offset(6)
            $0.centerX.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(actionTapped(_:)))
        item.addGestureRecognizer(tap)
        item.accessibilityIdentifier = action.route
        return item
    }

    @objc private func actionTapped(_ gesture: UITapGestureRecognizer) {
        guard let route = gesture.view?.accessibilityIdentifier else { return }
        onActionTapped?(route)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        onActionTapped = nil
    }
}
