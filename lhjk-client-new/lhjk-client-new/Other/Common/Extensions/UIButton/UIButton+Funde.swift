import UIKit

extension UIButton {
    /// Funde 主色按钮样式（浅橙底橙字）
    func styleFundeSoft() {
        titleLabel?.font = .fdBodySemibold
        setTitleColor(.fdPrimary, for: .normal)
        backgroundColor = .fdPrimarySoft
        layer.cornerRadius = 12
    }
}
