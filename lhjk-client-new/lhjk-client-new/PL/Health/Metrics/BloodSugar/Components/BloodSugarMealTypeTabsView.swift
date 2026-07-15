import UIKit
import SnapKit

/// 餐次类型横向 Tab — 对齐源项目 `ADSQTitleView`
final class BloodSugarMealTypeTabsView: UIView {

    var onSelect: ((Int) -> Void)?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private var buttons: [UIButton] = []
    private var selectedIndex = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollView.showsHorizontalScrollIndicator = false
        stack.axis = .horizontal
        stack.spacing = 8
        addSubview(scrollView)
        scrollView.addSubview(stack)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
            make.height.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(titles: [String], selectedIndex: Int = 0) {
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()
        self.selectedIndex = selectedIndex

        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .custom)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .fdCaptionSemibold
            button.layer.cornerRadius = 16
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
            button.tag = index
            button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            applyStyle(button, selected: index == selectedIndex)
            stack.addArrangedSubview(button)
            buttons.append(button)
        }
    }

    @objc private func tabTapped(_ sender: UIButton) {
        guard sender.tag != selectedIndex else { return }
        applyStyle(buttons[selectedIndex], selected: false)
        selectedIndex = sender.tag
        applyStyle(sender, selected: true)
        onSelect?(selectedIndex)
    }

    private func applyStyle(_ button: UIButton, selected: Bool) {
        let accent = UIColor(hexString: "#FF406F")
        button.setTitleColor(selected ? accent : .fdSubtext, for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = (selected ? accent : UIColor.clear).cgColor
        button.backgroundColor = selected ? accent.withAlphaComponent(0.08) : UIColor(hexString: "#F5F2F3")
    }
}
