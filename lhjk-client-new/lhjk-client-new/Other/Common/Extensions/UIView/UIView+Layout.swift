import UIKit

/// 运营 Banner 画幅：宽度由屏幕（或设计边距）决定，高度按图片宽高比计算。
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
        let fitWidth = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
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
        let fitWidth = width > 0 ? width : UIScreen.main.bounds.width
        bounds.size = CGSize(width: fitWidth, height: height)
        setNeedsLayout()
        layoutIfNeeded()
        frame = CGRect(x: 0, y: 0, width: fitWidth, height: height)
        return self
    }
}
