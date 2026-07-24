import UIKit

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

    /// 为 tableHeaderView 预计算正确宽度的 frame，避免 _UITemporaryLayoutWidth == 0 导致约束冲突
    func sizedForTableHeader(in view: UIView) -> Self {
        let fitWidth = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        bounds.size.width = fitWidth
        setNeedsLayout()
        layoutIfNeeded()
        let size = systemLayoutSizeFitting(
            CGSize(width: fitWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        frame = CGRect(x: 0, y: 0, width: fitWidth, height: size.height)
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
