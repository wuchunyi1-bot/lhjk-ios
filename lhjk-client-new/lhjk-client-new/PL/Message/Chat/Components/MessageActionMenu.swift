import UIKit
import SnapKit

/// 消息长按操作菜单 — 横向排列按钮：复制 / 撤回 / 引用
final class MessageActionMenu: UIView {

    enum Action { case copy, recall, quote }

    /// 点击回调
    var onAction: ((Action) -> Void)?

    // MARK: - UI

    private lazy var containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 8
        v.layer.shadowOpacity = 0.12
        return v
    }()

    private lazy var stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 0
        s.distribution = .fillEqually
        return s
    }()

    private var buttons: [(action: Action, button: UIButton)] = []

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(containerView)
        containerView.addSubview(stackView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.trailing.equalToSuperview().inset(4)
        }
        // 点击空白消失
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapBackground))
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(above sourceRect: CGRect, in containerView: UIView, actions: [Action]) {
        // 清除旧按钮
        buttons.forEach { $0.button.removeFromSuperview() }
        buttons.removeAll()

        for action in actions {
            let btn = makeButton(for: action)
            stackView.addArrangedSubview(btn)
            buttons.append((action, btn))
        }

        // 计算菜单位置
        layoutIfNeeded()
        let menuSize = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let spacing: CGFloat = 8

        var menuOrigin = sourceRect.origin
        // 优先显示在气泡上方
        menuOrigin.y = sourceRect.minY - menuSize.height - spacing
        // 如果上方空间不够，显示在下方
        if menuOrigin.y < containerView.safeAreaInsets.top + 20 {
            menuOrigin.y = sourceRect.maxY + spacing
        }
        // 水平居中于 sourceRect
        menuOrigin.x = sourceRect.midX - menuSize.width / 2
        // 确保不超出屏幕
        let minX: CGFloat = 16
        let maxX = containerView.bounds.width - menuSize.width - 16
        menuOrigin.x = max(minX, min(menuOrigin.x, maxX))

        frame = CGRect(origin: menuOrigin, size: menuSize)
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: 0.15) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    func dismiss() {
        UIView.animate(withDuration: 0.12, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.removeFromSuperview()
        }
    }

    // MARK: - Private

    private func makeButton(for action: Action) -> UIButton {
        let btn = UIButton(type: .system)
        let config = Self.buttonConfig(for: action)
        btn.setImage(UIImage(systemName: config.icon), for: .normal)
        btn.setTitle(config.title, for: .normal)
        btn.tintColor = .fdText
        btn.setTitleColor(.fdText, for: .normal)
        btn.titleLabel?.font = .fdFont(ofSize: 11)

        // 垂直布局：图标上、文字下
        btn.snp.makeConstraints { make in
            make.width.equalTo(56)
            make.height.equalTo(56)
        }

        // iOS 15+ 用 configuration，以下兼容低版本手动排布
        if #available(iOS 15.0, *) {
            var cfg = UIButton.Configuration.plain()
            cfg.imagePlacement = .top
            cfg.imagePadding = 4
            cfg.image = UIImage(systemName: config.icon)
            cfg.title = config.title
            cfg.baseForegroundColor = .fdText
            cfg.attributedTitle = AttributedString(
                config.title,
                attributes: AttributeContainer([.font: UIFont.fdFont(ofSize: 11)])
            )
            btn.configuration = cfg
        } else {
            btn.imageEdgeInsets = UIEdgeInsets(top: -8, left: 0, bottom: 0, right: 0)
            btn.titleEdgeInsets = UIEdgeInsets(top: 28, left: -btn.imageView!.frame.width, bottom: 0, right: 0)
        }

        btn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return btn
    }

    @objc private func buttonTapped(_ sender: UIButton) {
        guard let item = buttons.first(where: { $0.button === sender }) else { return }
        onAction?(item.action)
    }

    @objc private func didTapBackground() {
        dismiss()
    }

    // MARK: - Config

    private struct ButtonConfig { let icon: String; let title: String }

    private static func buttonConfig(for action: Action) -> ButtonConfig {
        switch action {
        case .copy:   return ButtonConfig(icon: "doc.on.doc", title: "复制")
        case .recall: return ButtonConfig(icon: "arrow.uturn.backward", title: "撤回")
        case .quote:  return ButtonConfig(icon: "arrowshape.turn.up.left", title: "引用")
        }
    }
}
