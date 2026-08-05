import UIKit
import SnapKit

/// 消息页自定义分段控件 — 对齐 Figma 3042:740
/// 曲线背景由 Figma 导出资源承载；控件只负责标签、选中态和未读徽标
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
            setNeedsLayout()
        }
    }

    var onSelect: ((Int) -> Void)?

    private let trackView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    private let activePill: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = 14
        v.isHidden = true
        return v
    }()

    private let stack = UIStackView()
    private var buttons: [UIButton] = []
    private var titleLabels: [UILabel] = []
    private var badgeLabels: [UILabel] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        addSubview(trackView)
        trackView.addSubview(activePill)
        trackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalTo(trackView) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard buttons.count >= 2 else { return }
        let w = trackView.bounds.width / 2
        let h = trackView.bounds.height
        if selectedIndex == 0 {
            activePill.layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner
            ]
            activePill.frame = CGRect(x: 0, y: 0, width: w + 10, height: h)
        } else {
            activePill.layer.maskedCorners = [
                .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner
            ]
            activePill.frame = CGRect(x: w - 10, y: 6, width: w + 10, height: h - 6)
        }
    }

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
            row.snp.makeConstraints { $0.center.equalToSuperview() }

            stack.addArrangedSubview(btn)
            buttons.append(btn)
            titleLabels.append(title)
            badgeLabels.append(badge)
        }
        applySelection()
        setNeedsLayout()
    }

    private func applySelection() {
        for idx in titleLabels.indices {
            let active = idx == selectedIndex
            titleLabels[idx].font = .fdFont(ofSize: 16, weight: active ? .medium : .regular)
            titleLabels[idx].textColor = active ? .fdText : UIColor(hexString: "#A7ABB3")

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
