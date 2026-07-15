import UIKit

final class DashedBorderView: UIView {
    var borderColor: UIColor = .fdBorder
    var dashed = false
    var solidBorder = true

    private let shape = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        shape.fillColor = nil
        shape.lineWidth = 1.5
        layer.addSublayer(shape)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        shape.frame = bounds
        let inset = bounds.insetBy(dx: 0.75, dy: 0.75)
        shape.path = UIBezierPath(roundedRect: inset, cornerRadius: 11.25).cgPath
        shape.strokeColor = borderColor.cgColor
        shape.lineDashPattern = dashed ? [6, 4] : nil
        shape.isHidden = !dashed
        layer.borderWidth = solidBorder ? 1.5 : 0
        layer.borderColor = solidBorder ? borderColor.cgColor : nil
    }
}
