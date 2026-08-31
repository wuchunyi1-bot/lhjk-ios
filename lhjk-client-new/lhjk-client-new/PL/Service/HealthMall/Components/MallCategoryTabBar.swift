import UIKit
import SnapKit

/// 富德优选商城顶部分类 Tab — 对齐 Figma 4054:2991
final class MallCategoryTabBar: UIView {

    var onTabSelected: ((Int) -> Void)?

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.alwaysBounceHorizontal = true
        sv.backgroundColor = .clear
        return sv
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 24
        stack.alignment = .center
        return stack
    }()

    private var tabViews: [TabItemView] = []
    private(set) var selectedIndex = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        addSubview(scrollView)
        scrollView.addSubview(stackView)

        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24))
            $0.height.equalTo(36)
        }
    }

    func configure(titles: [String], selectedIndex: Int) {
        self.selectedIndex = selectedIndex
        tabViews.forEach { $0.removeFromSuperview() }
        tabViews.removeAll()

        for (index, title) in titles.enumerated() {
            let itemView = TabItemView(title: title, index: index)
            itemView.onTap = { [weak self] idx in
                self?.handleTabTapped(idx)
            }
            stackView.addArrangedSubview(itemView)
            tabViews.append(itemView)
        }
        updateSelection(animated: false)
    }

    func setSelectedIndex(_ index: Int, animated: Bool = true) {
        guard index != selectedIndex, tabViews.indices.contains(index) else { return }
        selectedIndex = index
        updateSelection(animated: animated)
        scrollToSelectedTab(animated: animated)
    }

    private func handleTabTapped(_ index: Int) {
        guard index != selectedIndex, tabViews.indices.contains(index) else { return }
        selectedIndex = index
        updateSelection(animated: true)
        scrollToSelectedTab(animated: true)
        onTabSelected?(index)
    }

    private func updateSelection(animated: Bool) {
        for (index, tabView) in tabViews.enumerated() {
            tabView.setSelected(index == selectedIndex, animated: animated)
        }
    }

    private func scrollToSelectedTab(animated: Bool) {
        guard tabViews.indices.contains(selectedIndex) else { return }
        let targetView = tabViews[selectedIndex]
        let frameInScroll = targetView.convert(targetView.bounds, to: scrollView)
        let visibleWidth = scrollView.bounds.width
        guard visibleWidth > 0 else { return }

        let targetOffsetX = frameInScroll.midX - (visibleWidth / 2)
        let maxOffsetX = max(0, scrollView.contentSize.width - visibleWidth)
        let clampedOffsetX = max(0, min(targetOffsetX, maxOffsetX))

        scrollView.setContentOffset(CGPoint(x: clampedOffsetX, y: 0), animated: animated)
    }
}

// MARK: - Tab Item View

private final class TabItemView: UIView {
    var onTap: ((Int) -> Void)?
    private let index: Int

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 16, weight: .regular)
        l.textColor = UIColor(hexString: "#535D72")
        l.textAlignment = .center
        return l
    }()

    private let indicatorView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#FF7A50")
        v.layer.cornerRadius = 2
        v.clipsToBounds = true
        v.alpha = 0
        return v
    }()

    init(title: String, index: Int) {
        self.index = index
        super.init(frame: .zero)
        titleLabel.text = title
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(indicatorView)

        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(24)
        }
        indicatorView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(18)
            $0.height.equalTo(4)
            $0.bottom.equalToSuperview()
        }

        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    func setSelected(_ isSelected: Bool, animated: Bool) {
        let updates = {
            self.titleLabel.font = .fdFont(ofSize: 16, weight: isSelected ? .medium : .regular)
            self.titleLabel.textColor = isSelected ? UIColor(hexString: "#1F2942") : UIColor(hexString: "#535D72")
            self.indicatorView.alpha = isSelected ? 1 : 0
        }
        if animated {
            UIView.animate(withDuration: 0.15, animations: updates)
        } else {
            updates()
        }
    }

    @objc private func handleTap() {
        onTap?(index)
    }
}
