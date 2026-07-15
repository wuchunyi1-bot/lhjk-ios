import UIKit

/// 血压圆环仪表 — 对齐源项目 `TemperatureMeter`
final class BloodPressureGaugeView: UIView {

    private let progressWidth: CGFloat = 12
    private let trackColor = UIColor(hexString: "#F1EEEF")
    private var progressLayer: CAShapeLayer!

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        guard bounds.width > 0 else { return }

        let diameter = bounds.width
        let center = CGPoint(x: bounds.midX, y: diameter / 2)
        let path = UIBezierPath(
            arcCenter: center,
            radius: (diameter - progressWidth) / 2,
            startAngle: radians(-230),
            endAngle: radians(50),
            clockwise: true
        )

        let trackLayer = CAShapeLayer()
        trackLayer.frame = bounds
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineCap = .round
        trackLayer.lineWidth = progressWidth
        trackLayer.path = path.cgPath
        layer.addSublayer(trackLayer)

        progressLayer = CAShapeLayer()
        progressLayer.frame = bounds
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.black.cgColor
        progressLayer.lineCap = .round
        progressLayer.lineWidth = progressWidth
        progressLayer.path = path.cgPath
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = [
            UIColor(hexString: "#80DD81").cgColor,
            UIColor(hexString: "#FB9935").cgColor,
            UIColor(hexString: "#FE5677").cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.mask = progressLayer
        layer.addSublayer(gradientLayer)
    }

    func setProgress(_ percent: CGFloat, animated: Bool = true) {
        guard progressLayer != nil else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        progressLayer.strokeEnd = min(max(percent / 100, 0), 1)
        CATransaction.commit()
    }

    private func radians(_ degrees: CGFloat) -> CGFloat { .pi * degrees / 180 }
}
