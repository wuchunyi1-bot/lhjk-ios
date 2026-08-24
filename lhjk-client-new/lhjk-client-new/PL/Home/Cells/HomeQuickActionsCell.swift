import UIKit
import SnapKit
import Kingfisher

/// 快捷操作区 — 白卡 16 圆角；图标直接使用栏位 `imageUrl`，不加圆形底
final class HomeQuickActionsCell: UITableViewCell {

    static let reuseID = "HomeQuickActionsCell"

    struct Action: Hashable {
        let id: String
        let title: String
        let imageUrl: String?
        /// 栏位 `pageUrl`（`FundeH5:` / `FundeApp:`，见 `FundePageURL`）
        let pageUrl: String?
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

    var onActionTapped: ((Action) -> Void)?
    private var actionsByTag: [Int: Action] = [:]

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
        actionsByTag.removeAll()
        for (index, act) in actions.enumerated() {
            let item = makeActionItem(act, tag: index)
            actionsByTag[index] = act
            stackView.addArrangedSubview(item)
        }
    }

    private func makeActionItem(_ action: Action, tag: Int) -> UIView {
        let item = UIView()
        item.tag = tag

        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.clipsToBounds = true
        if let urlString = action.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            icon.kf.setImage(with: url)
        }

        let lbl = UILabel()
        lbl.text = action.title
        lbl.font = .fdFont(ofSize: 14, weight: .regular)
        lbl.textColor = .fdText
        lbl.textAlignment = .center

        item.addSubview(icon)
        item.addSubview(lbl)
        icon.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
            $0.size.equalTo(48)
        }
        lbl.snp.makeConstraints {
            $0.top.equalTo(icon.snp.bottom).offset(6)
            $0.centerX.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(actionTapped(_:)))
        item.addGestureRecognizer(tap)
        return item
    }

    @objc private func actionTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view, let action = actionsByTag[view.tag] else { return }
        onActionTapped?(action)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        actionsByTag.removeAll()
        onActionTapped = nil
    }
}
