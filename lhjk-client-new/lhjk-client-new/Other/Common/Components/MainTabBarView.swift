import UIKit
import SnapKit

/// 主 Tab 底栏（自绘）。避开 iOS 26 Liquid Glass 对系统 UITabBar 未选中色的强制覆盖。
final class MainTabBarView: UIView {

    struct Item {
        let title: String
        let normalImage: UIImage?
        let selectedImage: UIImage?
    }

    var onSelect: ((Int) -> Void)?

    private let contentHeight: CGFloat = 49
    private let topBorder = UIView()
    private let stack = UIStackView()
    private var buttons: [TabItemButton] = []
    private var selectedIndex: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface

        topBorder.backgroundColor = .fdBorder
        addSubview(topBorder)
        topBorder.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(0.5)
        }

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(contentHeight)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    var barContentHeight: CGFloat { contentHeight }

    func configure(items: [Item], selectedIndex: Int) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        buttons.removeAll()

        for (index, item) in items.enumerated() {
            let button = TabItemButton()
            button.configure(title: item.title, normal: item.normalImage, selected: item.selectedImage)
            button.tag = index
            button.addTarget(self, action: #selector(tapItem(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
            buttons.append(button)
        }
        setSelectedIndex(selectedIndex, notify: false)
    }

    func setSelectedIndex(_ index: Int, notify: Bool) {
        selectedIndex = index
        for (i, button) in buttons.enumerated() {
            button.isItemSelected = (i == index)
        }
        if notify {
            onSelect?(index)
        }
    }

    func setBadgeValue(_ value: String?, at index: Int) {
        guard buttons.indices.contains(index) else { return }
        buttons[index].badgeValue = value
    }

    @objc private func tapItem(_ sender: UIControl) {
        setSelectedIndex(sender.tag, notify: true)
    }
}

// MARK: - Item Button

private final class TabItemButton: UIControl {

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let badgeLabel = UILabel()
    private var normalImage: UIImage?
    private var selectedImage: UIImage?

    var isItemSelected = false {
        didSet { applyStyle() }
    }

    var badgeValue: String? {
        didSet { updateBadge() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false

        titleLabel.font = .fdFont(ofSize: 12, weight: .regular)
        titleLabel.textAlignment = .center
        titleLabel.isUserInteractionEnabled = false

        badgeLabel.font = .fdFont(ofSize: 10, weight: .medium)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeLabel.backgroundColor = .fdDanger
        badgeLabel.layer.cornerRadius = 8
        badgeLabel.clipsToBounds = true
        badgeLabel.isHidden = true
        badgeLabel.isUserInteractionEnabled = false

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(badgeLabel)

        iconView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(6)
            $0.size.equalTo(24)
        }
        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(iconView.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview().inset(2)
        }
        badgeLabel.snp.makeConstraints {
            $0.top.equalTo(iconView).offset(-4)
            $0.leading.equalTo(iconView.snp.trailing).offset(-10)
            $0.height.equalTo(16)
            $0.width.greaterThanOrEqualTo(16)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, normal: UIImage?, selected: UIImage?) {
        titleLabel.text = title
        normalImage = normal?.withRenderingMode(.alwaysOriginal)
        selectedImage = selected?.withRenderingMode(.alwaysOriginal)
        applyStyle()
    }

    private func applyStyle() {
        iconView.image = isItemSelected ? selectedImage : normalImage
        titleLabel.textColor = isItemSelected ? .fdPrimary : .fdTabInactive
        titleLabel.font = .fdFont(ofSize: 12, weight: isItemSelected ? .medium : .regular)
    }

    private func updateBadge() {
        guard let value = badgeValue, !value.isEmpty else {
            badgeLabel.isHidden = true
            return
        }
        badgeLabel.isHidden = false
        badgeLabel.text = value
        let textWidth = (value as NSString)
            .size(withAttributes: [.font: UIFont.fdFont(ofSize: 10, weight: .medium)])
            .width
        let width = max(16, textWidth + 8)
        badgeLabel.snp.remakeConstraints {
            $0.top.equalTo(iconView).offset(-4)
            $0.leading.equalTo(iconView.snp.trailing).offset(-10)
            $0.height.equalTo(16)
            $0.width.equalTo(width)
        }
    }
}
