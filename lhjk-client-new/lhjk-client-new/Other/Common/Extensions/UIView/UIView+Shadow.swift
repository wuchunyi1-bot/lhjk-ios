import UIKit

extension UIView {
    /// Funde 卡片阴影
    func addFundeShadow(radius: CGFloat = 6, opacity: Float = 0.03) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
    }
}
