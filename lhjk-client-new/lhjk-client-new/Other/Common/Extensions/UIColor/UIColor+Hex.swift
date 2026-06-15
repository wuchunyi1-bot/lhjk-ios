import UIKit

extension UIColor {
    /// 使用十六进制值初始化颜色
    /// - Parameters:
    ///   - hex: 十六进制颜色值 (e.g. 0xFF5733)
    ///   - alpha: 透明度，默认 1.0
    convenience init(hex: UInt, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// 使用十六进制字符串初始化颜色
    /// - Parameter hexString: e.g. "#FF5733" or "FF5733"
    convenience init(hexString: String) {
        let hex = hexString
            .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(hex: UInt(int))
    }
}
