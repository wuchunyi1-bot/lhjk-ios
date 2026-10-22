import SnapKit
import UIKit

/// 首页四个页签：首页、健康服务、富德优选、健康知识。
final class HomeShelfBar: UIView {

    var onSelect: ((HomeShelf) -> Void)?

    private var buttons: [HomeShelf: UIButton] = [:]
    private let indicator = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdBg
        indicator.backgroundColor = .fdPrimary
        indicator.layer.cornerRadius = 1
        addSubview(indicator)

        var previous: UIView?
        for shelf in HomeShelf.allCases {
            let button = UIButton(type: .system)
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
        for (item, button) in buttons {
            let selected = item == shelf
            button.setTitleColor(selected ? .fdPrimary : .fdSubtext, for: .normal)
            button.titleLabel?.font = selected
                ? .fdFont(ofSize: 16, weight: .bold)
                : .fdFont(ofSize: 15, weight: .semibold)
        }
        guard let button = buttons[shelf] else { return }
        indicator.snp.remakeConstraints { make in
            make.bottom.equalToSuperview()
            make.width.equalTo(24)
            make.height.equalTo(2)
            make.centerX.equalTo(button)
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
