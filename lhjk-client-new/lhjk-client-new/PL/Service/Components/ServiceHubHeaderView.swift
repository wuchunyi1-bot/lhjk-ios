import UIKit
import SnapKit

/// 服务首页顶栏 — 复用 `TabHubBrandHeaderView` + 右侧购物车
final class ServiceHubHeaderView: UIView {

    var onCartTapped: (() -> Void)?

    private let brandHeader = TabHubBrandHeaderView()
    private let cartButton = ServiceCartBadgeButton(style: .hub)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdBg
        clipsToBounds = false
        addSubview(brandHeader)
        addSubview(cartButton)
        brandHeader.configure(
            title: "健康服务",
            subtitle: "德系健康管理·9大产品线",
            titleColor: .fdText
        )
        brandHeader.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
            $0.trailing.equalTo(cartButton.snp.leading).offset(-8)
        }
        cartButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(brandHeader)
            $0.size.equalTo(ServiceCartBadgeButton.Style.hub.iconSize)
        }
        cartButton.addTarget(self, action: #selector(cartTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    func applyCartCount(_ count: Int) {
        cartButton.apply(count: count)
    }

    @objc private func cartTapped() {
        onCartTapped?()
    }
}

/// 购物车入口：图标 + 数量角标（0 隐藏，>99 显示 99+）
final class ServiceCartBadgeButton: UIControl {

    enum Style {
        case hub
        case nav

        var iconSize: CGFloat {
            switch self {
            case .hub: return 40
            case .nav: return 24
            }
        }

        /// 角标半宽；导航栏 customView 必须把角标算进 bounds，否则 iOS 26 Liquid Glass 会裁掉溢出
        var badgePeek: CGFloat {
            switch self {
            case .hub: return 0
            case .nav: return 9
            }
        }
    }

    private let iconView = UIImageView()
    private let badgeView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdDanger
        v.layer.cornerRadius = 9
        v.clipsToBounds = true
        v.isHidden = true
        v.isUserInteractionEnabled = false
        return v
    }()
    private let badgeLabel = UnreadBadgeCountLabel()
    private let iconSize: CGFloat
    private let badgePeek: CGFloat

    init(style: Style) {
        iconSize = style.iconSize
        badgePeek = style.badgePeek
        super.init(frame: .zero)
        clipsToBounds = false
        isAccessibilityElement = true
        accessibilityLabel = "购物车"

        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false
        switch style {
        case .hub:
            iconView.image = UIImage.fdServiceHubCart(pointSize: iconSize)
        case .nav:
            iconView.image = .fdNavCart
            iconView.tintColor = .fdText
        }

        addSubview(iconView)
        addSubview(badgeView)
        badgeView.addSubview(badgeLabel)

        iconView.snp.makeConstraints {
            $0.leading.bottom.equalToSuperview()
            $0.size.equalTo(iconSize)
        }
        badgeView.snp.makeConstraints {
            $0.centerX.equalTo(iconView.snp.trailing)
            $0.centerY.equalTo(iconView.snp.top)
            $0.height.equalTo(18)
            $0.width.greaterThanOrEqualTo(18)
        }
        badgeLabel.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize {
        CGSize(width: iconSize + badgePeek, height: iconSize + badgePeek)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, badgePeek > 0 else { return }
        // iOS 26 导航栏会给 customView 包一层 clipsToBounds 的 Liquid Glass 容器
        var node: UIView? = superview
        while let current = node {
            current.clipsToBounds = false
            if current is UINavigationBar { break }
            node = current.superview
        }
    }

    func apply(count: Int) {
        if let text = ShoppingCartBadgeStore.displayText(for: count) {
            badgeView.isHidden = false
            badgeLabel.text = text
            badgeLabel.invalidateIntrinsicContentSize()
            accessibilityValue = text
        } else {
            badgeView.isHidden = true
            badgeLabel.text = nil
            accessibilityValue = nil
        }
    }
}
