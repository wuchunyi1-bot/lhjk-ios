import UIKit

/// 占位 ViewController — 用于尚未实现的页面路由
final class PlaceholderViewController: BaseViewController {

    private let pageTitle: String

    init(title: String) {
        self.pageTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupUI() {
        self.title = pageTitle
        view.backgroundColor = .fdBg

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        view.addSubview(stack)
        stack.snp.makeConstraints { $0.center.equalToSuperview() }

        let icon = UILabel()
        icon.text = "🚧"
        icon.font = .fdFont(ofSize: 48) // decorative emoji
        stack.addArrangedSubview(icon)

        let label = UILabel()
        label.text = "\(pageTitle)\n即将上线"
        label.font = .fdBody
        label.textColor = .fdSubtext
        label.textAlignment = .center
        label.numberOfLines = 0
        stack.addArrangedSubview(label)
    }
}
