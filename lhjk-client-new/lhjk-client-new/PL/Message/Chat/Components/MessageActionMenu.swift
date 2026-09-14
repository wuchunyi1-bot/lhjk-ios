import UIKit
import SnapKit

/// 消息长按操作菜单 — 对齐 Figma `5385:16765`
/// 功能项仍由 `ChatViewModel.availableActions` 决定（复制 / 撤回 / 引用），不展示稿中的「举报」
final class MessageActionMenu: UIView {

    enum Action { case copy, recall, quote }

    var onAction: ((Action) -> Void)?

    private let bubbleView = MenuBubbleView()
    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = Metrics.itemSpacing
        s.distribution = .fill
        return s
    }()

    private var buttons: [(action: Action, control: UIControl)] = []
    private var stackTopConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        addSubview(bubbleView)
        bubbleView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            stackTopConstraint = make.top.equalToSuperview().offset(Metrics.contentInset).constraint
            make.leading.equalToSuperview().offset(Metrics.horizontalInset)
            make.trailing.equalToSuperview().offset(-Metrics.horizontalInset)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapBackground(_:)))
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(above sourceRect: CGRect, in containerView: UIView, actions: [Action]) {
        buttons.forEach { $0.control.removeFromSuperview() }
        buttons.removeAll()

        for action in actions {
            let item = makeItem(for: action)
            stackView.addArrangedSubview(item)
            buttons.append((action, item))
        }

        frame = containerView.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        layoutBubble(above: sourceRect, in: containerView, actionCount: actions.count)

        alpha = 0
        bubbleView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        UIView.animate(withDuration: 0.15) {
            self.alpha = 1
            self.bubbleView.transform = .identity
        }
    }

    func dismiss() {
        UIView.animate(withDuration: 0.12, animations: {
            self.alpha = 0
            self.bubbleView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { _ in
            self.removeFromSuperview()
        }
    }

    // MARK: - Layout

    private func layoutBubble(above sourceRect: CGRect, in containerView: UIView, actionCount: Int) {
        let count = max(actionCount, 1)
        let bubbleWidth = Metrics.horizontalInset * 2
            + CGFloat(count) * Metrics.itemWidth
            + CGFloat(count - 1) * Metrics.itemSpacing
        let bubbleHeight = Metrics.bodyHeight + Metrics.arrowHeight
        let spacing = Metrics.anchorSpacing

        var originY = sourceRect.minY - bubbleHeight - spacing
        var arrowOnTop = false
        if originY < containerView.safeAreaInsets.top + 8 {
            originY = sourceRect.maxY + spacing
            arrowOnTop = true
        }

        var originX = sourceRect.midX - bubbleWidth / 2
        let minX: CGFloat = 16
        let maxX = containerView.bounds.width - bubbleWidth - 16
        originX = max(minX, min(originX, maxX))

        bubbleView.frame = CGRect(x: originX, y: originY, width: bubbleWidth, height: bubbleHeight)

        let minArrowX = Metrics.cornerRadius + Metrics.arrowWidth / 2
        let maxArrowX = bubbleWidth - Metrics.cornerRadius - Metrics.arrowWidth / 2
        let desiredArrowX = sourceRect.midX - originX
        bubbleView.arrowOnTop = arrowOnTop
        bubbleView.arrowCenterX = min(max(desiredArrowX, minArrowX), maxArrowX)
        bubbleView.setNeedsLayout()
        let topInset = arrowOnTop ? Metrics.arrowHeight + Metrics.contentInset : Metrics.contentInset
        stackTopConstraint?.update(offset: topInset)
    }

    // MARK: - Items

    private func makeItem(for action: Action) -> UIControl {
        let control = UIControl()
        control.snp.makeConstraints { make in
            make.width.equalTo(Metrics.itemWidth)
            make.height.equalTo(Metrics.itemHeight)
        }

        let iconView = UIImageView(image: UIImage(named: Self.iconName(for: action)))
        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false

        let titleLabel = UILabel()
        titleLabel.text = Self.title(for: action)
        titleLabel.font = .fdFont(ofSize: 12, weight: .regular)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.isUserInteractionEnabled = false

        let column = UIStackView(arrangedSubviews: [iconView, titleLabel])
        column.axis = .vertical
        column.alignment = .center
        column.spacing = Metrics.iconTitleSpacing
        column.isUserInteractionEnabled = false
        control.addSubview(column)
        column.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }
        iconView.snp.makeConstraints { make in
            make.size.equalTo(Metrics.iconSize)
        }

        control.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
        return control
    }

    @objc private func itemTapped(_ sender: UIControl) {
        guard let item = buttons.first(where: { $0.control === sender }) else { return }
        onAction?(item.action)
    }

    @objc private func didTapBackground(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: bubbleView)
        if bubbleView.bounds.contains(point) { return }
        dismiss()
    }

    private static func title(for action: Action) -> String {
        switch action {
        case .copy: return "复制"
        case .recall: return "撤回"
        case .quote: return "引用"
        }
    }

    private static func iconName(for action: Action) -> String {
        switch action {
        case .copy: return "chat_msg_menu_copy"
        case .recall: return "chat_msg_menu_recall"
        case .quote: return "chat_msg_menu_quote"
        }
    }

    fileprivate enum Metrics {
        static let itemWidth: CGFloat = 44
        static let itemHeight: CGFloat = 44
        static let itemSpacing: CGFloat = 8
        static let iconSize: CGFloat = 22
        static let iconTitleSpacing: CGFloat = 4
        static let horizontalInset: CGFloat = 20
        static let contentInset: CGFloat = 8
        static let bodyHeight: CGFloat = 60
        static let cornerRadius: CGFloat = 12
        static let arrowWidth: CGFloat = 13.6
        static let arrowHeight: CGFloat = 5
        static let anchorSpacing: CGFloat = 6
    }
}

// MARK: - Bubble

private final class MenuBubbleView: UIView {

    var arrowOnTop = false
    var arrowCenterX: CGFloat = 0

    private let fillLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor(hexString: "#1B1B21").withAlphaComponent(0.75).cgColor
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
        layer.insertSublayer(fillLayer, at: 0)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        fillLayer.frame = bounds
        fillLayer.path = makePath().cgPath
    }

    private func makePath() -> UIBezierPath {
        let width = bounds.width
        let radius = MessageActionMenu.Metrics.cornerRadius
        let arrowW = MessageActionMenu.Metrics.arrowWidth
        let arrowH = MessageActionMenu.Metrics.arrowHeight
        let bodyMinY: CGFloat = arrowOnTop ? arrowH : 0
        let bodyMaxY: CGFloat = arrowOnTop ? bounds.height : bounds.height - arrowH
        let arrowX = min(max(arrowCenterX, radius + arrowW / 2), width - radius - arrowW / 2)

        let path = UIBezierPath()
        path.move(to: CGPoint(x: radius, y: bodyMinY))
        if arrowOnTop {
            path.addLine(to: CGPoint(x: arrowX - arrowW / 2, y: bodyMinY))
            path.addLine(to: CGPoint(x: arrowX, y: 0))
            path.addLine(to: CGPoint(x: arrowX + arrowW / 2, y: bodyMinY))
        }
        path.addLine(to: CGPoint(x: width - radius, y: bodyMinY))
        path.addArc(
            withCenter: CGPoint(x: width - radius, y: bodyMinY + radius),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 0,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: width, y: bodyMaxY - radius))
        path.addArc(
            withCenter: CGPoint(x: width - radius, y: bodyMaxY - radius),
            radius: radius,
            startAngle: 0,
            endAngle: .pi / 2,
            clockwise: true
        )
        if !arrowOnTop {
            path.addLine(to: CGPoint(x: arrowX + arrowW / 2, y: bodyMaxY))
            path.addLine(to: CGPoint(x: arrowX, y: bounds.height))
            path.addLine(to: CGPoint(x: arrowX - arrowW / 2, y: bodyMaxY))
        }
        path.addLine(to: CGPoint(x: radius, y: bodyMaxY))
        path.addArc(
            withCenter: CGPoint(x: radius, y: bodyMaxY - radius),
            radius: radius,
            startAngle: .pi / 2,
            endAngle: .pi,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: 0, y: bodyMinY + radius))
        path.addArc(
            withCenter: CGPoint(x: radius, y: bodyMinY + radius),
            radius: radius,
            startAngle: .pi,
            endAngle: -.pi / 2,
            clockwise: true
        )
        path.close()
        return path
    }
}
