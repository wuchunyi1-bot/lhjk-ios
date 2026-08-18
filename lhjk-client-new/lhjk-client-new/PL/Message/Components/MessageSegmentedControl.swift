import UIKit
import SnapKit

/// 消息页自定义分段控件 — 对齐 Figma 3444:5583 / 3444:5773
/// 曲线背景由 Tab 背景图承载；本控件负责文字标签、高亮态与未读徽标
final class MessageSegmentedControl: UIControl {

    struct Item {
        let title: String
        let badge: Int
    }

    var items: [Item] = [] {
        didSet { rebuild() }
    }

    var selectedIndex: Int = 0 {
        didSet {
            applySelection()
        }
    }

    var onSelect: ((Int) -> Void)?

    private let stack = UIStackView()
    private var buttons: [UIButton] = []
    private var titleLabels: [UILabel] = []
    private var badgeLabels: [UILabel] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func rebuild() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buttons.removeAll()
        titleLabels.removeAll()
        badgeLabels.removeAll()

        for (idx, item) in items.enumerated() {
            let btn = UIButton(type: .custom)
            btn.tag = idx
            btn.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)

            let title = UILabel()
            title.text = item.title
            title.isUserInteractionEnabled = false

            let badge = UILabel()
            badge.font = .fdFont(ofSize: 10, weight: .medium)
            badge.textColor = .white
            badge.textAlignment = .center
            badge.layer.cornerRadius = 9
            badge.clipsToBounds = true
            badge.isUserInteractionEnabled = false
            badge.snp.makeConstraints {
                $0.width.greaterThanOrEqualTo(18)
                $0.height.equalTo(18)
            }

            let row = UIStackView(arrangedSubviews: [title, badge])
            row.axis = .horizontal
            row.spacing = 2
            row.alignment = .center
            row.isUserInteractionEnabled = false

            btn.addSubview(row)
            row.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                // Figma 中文字在 y=135（tab顶部在 y=109，即偏移 26pt）
                make.top.equalToSuperview().offset(26)
            }

            stack.addArrangedSubview(btn)
            buttons.append(btn)
            titleLabels.append(title)
            badgeLabels.append(badge)
        }
        applySelection()
    }

    private func applySelection() {
        for idx in titleLabels.indices {
            let active = idx == selectedIndex
            titleLabels[idx].font = .fdFont(ofSize: 16, weight: active ? .medium : .regular)
            titleLabels[idx].textColor = active ? UIColor(hexString: "#1F2430") : UIColor(hexString: "#A7ABB3")

            guard idx < badgeLabels.count, idx < items.count else { continue }
            let badge = badgeLabels[idx]
            let count = items[idx].badge
            badge.isHidden = count <= 0
            badge.text = count > 99 ? "99+" : "\(count)"
            badge.backgroundColor = active
                ? UIColor(hexString: "#FF7A50")
                : UIColor(hexString: "#C8CCD4")
        }
    }

    @objc private func tapped(_ sender: UIButton) {
        let idx = sender.tag
        guard idx != selectedIndex else { return }
        selectedIndex = idx
        onSelect?(idx)
    }
}
