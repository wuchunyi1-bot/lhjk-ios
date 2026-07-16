import UIKit
import SnapKit

/// 富德优选商城顶部分类 Tab — 对齐 funde `HealthMallView.vue` `.cat-tabs`
final class MallCategoryTabBar: UIView {

    var onTabSelected: ((Int) -> Void)?

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.alwaysBounceHorizontal = true
        return sv
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()

    private var tabButtons: [UIButton] = []
    private(set) var selectedIndex = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        let bottomLine = UIView()
        bottomLine.backgroundColor = .fdBorder

        addSubview(scrollView)
        scrollView.addSubview(stackView)
        addSubview(bottomLine)

        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(52)
        }
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 16, bottom: 8, right: 16))
            $0.height.equalTo(36)
        }
        bottomLine.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
            $0.top.equalTo(scrollView.snp.bottom)
        }
    }

    func configure(titles: [String], selectedIndex: Int) {
        self.selectedIndex = selectedIndex
        tabButtons.forEach { $0.removeFromSuperview() }
        tabButtons.removeAll()

        for (index, title) in titles.enumerated() {
            let button = makeTabButton(title: title, index: index)
            stackView.addArrangedSubview(button)
            tabButtons.append(button)
        }
        updateSelection(animated: false)
    }

    func setSelectedIndex(_ index: Int, animated: Bool = true) {
        guard index != selectedIndex, tabButtons.indices.contains(index) else { return }
        selectedIndex = index
        updateSelection(animated: animated)
    }

    private func makeTabButton(title: String, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = index
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .fdCaptionSemibold
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        button.layer.cornerRadius = 18
        button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }

    @objc private func tabTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index != selectedIndex else { return }
        selectedIndex = index
        updateSelection(animated: true)
        onTabSelected?(index)
    }

    private func updateSelection(animated: Bool) {
        let updates = {
            for (index, button) in self.tabButtons.enumerated() {
                let isActive = index == self.selectedIndex
                button.backgroundColor = isActive ? .fdPrimary : .clear
                button.setTitleColor(isActive ? .white : .fdSubtext, for: .normal)
                button.titleLabel?.font = isActive ? .fdCaptionSemibold : .fdCaption
            }
        }
        if animated {
            UIView.animate(withDuration: 0.15, animations: updates)
        } else {
            updates()
        }
    }
}
