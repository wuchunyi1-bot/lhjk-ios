import UIKit

/// 当前前台窗口的宽和像素倍率。布局不要直接读 `UIScreen.main`：
/// iPhone Duo 折叠、展开或旋转时，窗口宽度会变，整机屏幕不一定是当前窗口。
enum FDWindowMetrics {
    static var layoutWidth: CGFloat {
        if let width = foregroundWindow?.bounds.width, width > 1 { return width }
        if let width = foregroundScene?.screen.bounds.width, width > 1 { return width }
        return UIScreen.main.bounds.width
    }

    static var displayScale: CGFloat {
        if let scale = foregroundWindow?.traitCollection.displayScale, scale > 0 { return scale }
        if let scale = foregroundWindow?.screen.scale, scale > 0 { return scale }
        if let scale = foregroundScene?.screen.scale, scale > 0 { return scale }
        let current = UITraitCollection.current.displayScale
        if current > 0 { return current }
        return max(UIScreen.main.scale, 1)
    }

    static var hairline: CGFloat { 1 / displayScale }

    private static var foregroundScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }

    private static var foregroundWindow: UIWindow? {
        guard let scene = foregroundScene else { return nil }
        return scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first
    }
}

/// 运营 Banner 画幅：宽度由容器决定，高度按图片宽高比计算。
enum BannerImageAspectLayout {
    static func height(width: CGFloat, imageSize: CGSize?, fallbackRatio: CGFloat) -> CGFloat {
        guard width > 0, fallbackRatio > 0 else { return 0 }
        let ratio: CGFloat
        if let imageSize, imageSize.width > 1, imageSize.height > 1 {
            ratio = imageSize.height / imageSize.width
        } else {
            ratio = fallbackRatio
        }
        return (width * ratio).rounded()
    }
}

extension UIView {
    /// 布局宽度：自身 bounds → 所在表格 → 所在窗口 → 前台窗口。
    var fdContainerWidth: CGFloat {
        if bounds.width > 1 { return bounds.width }
        if let table = fdEnclosingTableView, table.bounds.width > 1 { return table.bounds.width }
        if let window, window.bounds.width > 1 { return window.bounds.width }
        return FDWindowMetrics.layoutWidth
    }

    /// 1 物理像素。优先用当前 trait 的倍率，避免画到另一块屏幕上。
    var fdHairline: CGFloat {
        let scale = traitCollection.displayScale
        if scale > 0 { return 1 / scale }
        return FDWindowMetrics.hairline
    }

    var fdDisplayScale: CGFloat {
        let scale = traitCollection.displayScale
        if scale > 0 { return scale }
        return FDWindowMetrics.displayScale
    }

    private var fdEnclosingTableView: UITableView? {
        var view: UIView? = superview
        while let current = view {
            if let table = current as? UITableView { return table }
            view = current.superview
        }
        return nil
    }

    /// 添加子视图并禁用 translatesAutoresizingMaskIntoConstraints
    func addAutoLayoutSubview(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
    }

    /// 填充父视图边缘（需已添加至父视图）
    func fillSuperview(insets: UIEdgeInsets = .zero) {
        guard let superview = superview else { return }
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -insets.bottom)
        ])
    }

    /// 设置固定尺寸
    func setSize(_ size: CGSize) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size.width),
            heightAnchor.constraint(equalToConstant: size.height)
        ])
    }

    /// 为 tableHeaderView 预计算正确宽度的 frame，避免 _UITemporaryLayoutWidth/Height == 0 导致约束冲突
    func sizedForTableHeader(in view: UIView) -> Self {
        let fitWidth = view.bounds.width > 1 ? view.bounds.width : view.fdContainerWidth
        // 先给非零 frame，避免 Auto Layout 在 width/height == 0 时产生 unsatisfiable 警告
        frame = CGRect(x: 0, y: 0, width: fitWidth, height: 1)
        setNeedsLayout()
        layoutIfNeeded()
        let height = systemLayoutSizeFitting(
            CGSize(width: fitWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        frame = CGRect(x: 0, y: 0, width: fitWidth, height: ceil(height))
        return self
    }

    /// 为 tableFooterView 预计算正确宽度的 frame
    func sizedForTableFooter(width: CGFloat, height: CGFloat) -> Self {
        let fitWidth = width > 0 ? width : FDWindowMetrics.layoutWidth
        bounds.size = CGSize(width: fitWidth, height: height)
        setNeedsLayout()
        layoutIfNeeded()
        frame = CGRect(x: 0, y: 0, width: fitWidth, height: height)
        return self
    }
}
