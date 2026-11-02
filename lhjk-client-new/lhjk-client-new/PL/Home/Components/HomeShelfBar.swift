import SnapKit
import UIKit

/// 首页四个页签：推荐、健康服务、富德优选、健康知识。
final class HomeShelfBar: UIView {

    var onSelect: ((HomeShelf) -> Void)?

    private var buttons: [HomeShelf: ShelfTabButton] = [:]
    private let indicator = UIView()
    private var selectedShelf: HomeShelf = .home

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdBg
        indicator.backgroundColor = .fdPrimary
        indicator.layer.cornerRadius = 1
        addSubview(indicator)

        var previous: UIView?
        for shelf in HomeShelf.allCases {
            let button = ShelfTabButton(type: .system)
            button.setTitle(shelf.title, for: .normal)
            button.tag = HomeShelf.allCases.firstIndex(of: shelf) ?? 0
            button.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
            addSubview(button)
            buttons[shelf] = button
            button.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                if let previous {
                    make.leading.equalTo(previous.snp.trailing).offset(22)
                } else {
                    make.leading.equalToSuperview().offset(16)
                }
            }
            previous = button
        }
        setSelected(.home)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func frameOfButton(for shelf: HomeShelf) -> CGRect? {
        guard let button = buttons[shelf] else { return nil }
        layoutIfNeeded()
        return button.convert(button.bounds, to: self)
    }

    func setSelected(_ shelf: HomeShelf) {
        selectedShelf = shelf
        applyTabFonts()
        guard let button = buttons[shelf] else { return }
        indicator.snp.remakeConstraints { make in
            make.bottom.equalToSuperview()
            make.width.equalTo(24)
            make.height.equalTo(2)
            make.centerX.equalTo(button)
        }
    }

    /// 未选中 15pt；选中大一号，走字号表下一档 18pt（长辈模式 22pt，仍大于未选中的 19pt）。
    private func applyTabFonts() {
        for (item, button) in buttons {
            let selected = item == selectedShelf
            button.setTitleColor(selected ? .fdPrimary : .fdSubtext, for: .normal)
            button.usesSelectedStyle = selected
        }
    }

    @objc private func tapped(_ sender: UIButton) {
        let index = sender.tag
        guard HomeShelf.allCases.indices.contains(index) else { return }
        let shelf = HomeShelf.allCases[index]
        setSelected(shelf)
        onSelect?(shelf)
    }
}

/// 系统按钮会在布局时把 `titleLabel.font` 收回默认字号，这里在布局后再写回。
private final class ShelfTabButton: UIButton {
    var usesSelectedStyle = false {
        didSet { applyShelfFont() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyShelfFont()
    }

    private func applyShelfFont() {
        let font: UIFont = usesSelectedStyle
            ? .fdFont(ofSize: 18, weight: .bold)
            : .fdFont(ofSize: 15, weight: .semibold)
        guard let current = titleLabel?.font else {
            titleLabel?.font = font
            return
        }
        if abs(current.pointSize - font.pointSize) < 0.5,
           current.fontDescriptor.symbolicTraits == font.fontDescriptor.symbolicTraits {
            return
        }
        titleLabel?.font = font
    }
}
