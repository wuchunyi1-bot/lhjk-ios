import UIKit
import SnapKit

/// 「常用功能」4 列宫格 Cell — 对齐 MeView.vue common-grid-card
final class MeCommonActionsCell: UITableViewCell {

    static let reuseIdentifier = "MeCommonActionsCell"

    var onActionTap: ((String) -> Void)?

    private let card = UIView()
    private let grid = UIStackView()
    private var actionButtons: [UIButton] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        contentView.addSubview(card)
        card.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }

        grid.axis = .vertical
        grid.spacing = 10
        grid.distribution = .fillEqually
        card.addSubview(grid)
        grid.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 8, bottom: 12, right: 8))
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(actions: [MyViewModel.CommonAction]) {
        grid.arrangedSubviews.forEach {
            grid.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        actionButtons.removeAll()

        let rows = stride(from: 0, to: actions.count, by: 4).map { start in
            Array(actions[start..<min(start + 4, actions.count)])
        }

        for rowActions in rows {
            let row = UIStackView()
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.alignment = .fill

            for action in rowActions {
                let btn = makeActionButton(action)
                actionButtons.append(btn)
                row.addArrangedSubview(btn)
            }
            // Pad incomplete last row
            while row.arrangedSubviews.count < 4 {
                row.addArrangedSubview(UIView())
            }
            grid.addArrangedSubview(row)
            row.snp.makeConstraints { $0.height.greaterThanOrEqualTo(72) }
        }
    }

    private func makeActionButton(_ action: MyViewModel.CommonAction) -> UIButton {
        let btn = UIButton(type: .system)
        btn.tag = actionButtons.count

        let iconWrap = UIView()
        iconWrap.isUserInteractionEnabled = false
        iconWrap.backgroundColor = action.color.withAlphaComponent(0.1)
        iconWrap.layer.cornerRadius = 10

        let icon = UIImageView(image: UIImage(systemName: action.icon))
        icon.tintColor = action.color
        icon.contentMode = .scaleAspectFit
        iconWrap.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(20) }

        let label = UILabel()
        label.text = action.label
        label.font = .fdMicroSemibold
        label.textColor = .fdText2
        label.textAlignment = .center
        label.isUserInteractionEnabled = false

        let stack = UIStackView(arrangedSubviews: [iconWrap, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 7
        stack.isUserInteractionEnabled = false

        btn.addSubview(stack)
        iconWrap.snp.makeConstraints { $0.size.equalTo(34) }
        stack.snp.makeConstraints { $0.center.equalToSuperview(); $0.leading.trailing.equalToSuperview().inset(2) }

        btn.accessibilityLabel = action.label
        btn.addAction(UIAction { [weak self] _ in
            self?.onActionTap?(action.route)
        }, for: .touchUpInside)
        return btn
    }
}
