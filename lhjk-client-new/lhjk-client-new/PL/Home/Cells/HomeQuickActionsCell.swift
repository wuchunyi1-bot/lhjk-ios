import UIKit
import SnapKit

/// 快捷操作区 Cell — 4 个操作按钮横向排列
final class HomeQuickActionsCell: UITableViewCell {

    static let reuseID = "HomeQuickActionsCell"

    // MARK: - Data types

    struct Action {
        let icon: String
        let title: String
        let bgColor: UIColor
        let iconColor: UIColor
        let route: String
    }

    // MARK: - UI

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = 18
        v.addFundeShadow()
        return v
    }()

    private let stackView: UIStackView = {
        let s = UIStackView()
        s.distribution = .fillEqually
        return s
    }()

    // MARK: - Callback

    var onActionTapped: ((String) -> Void)?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .fdBg
        selectionStyle = .none
        contentView.clipsToBounds = false
        clipsToBounds = false
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(cardView)
        cardView.addSubview(stackView)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 18, left: 8, bottom: 18, right: 8))
        }
    }

    // MARK: - Configure

    func configure(actions: [Action]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for act in actions {
            let item = makeActionItem(act)
            stackView.addArrangedSubview(item)
        }
    }

    private func makeActionItem(_ action: Action) -> UIView {
        let item = UIView()

        let iconBg = UIView()
        iconBg.backgroundColor = action.bgColor
        iconBg.layer.cornerRadius = 16

        let icon = UIImageView(image: UIImage(systemName: action.icon))
        icon.tintColor = action.iconColor
        icon.contentMode = .scaleAspectFit
        iconBg.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(24)
        }

        let lbl = UILabel()
        lbl.text = action.title
        lbl.font = .systemFont(ofSize: 12, weight: .medium)
        lbl.textColor = .fdText2
        lbl.textAlignment = .center

        item.addSubview(iconBg)
        item.addSubview(lbl)
        iconBg.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(48)
        }
        lbl.snp.makeConstraints { make in
            make.top.equalTo(iconBg.snp.bottom).offset(7)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
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
