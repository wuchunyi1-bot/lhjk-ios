import UIKit
import SnapKit

/// 简化人形轮廓自定义绘制
/// 参考 funde-client: HealthProfileView.vue 的 body-svg
final class BodyFigureView: UIView {

    // MARK: - Colors

    private let fillColor = UIColor(hexString: "#DAEEFF")
    private let strokeColor = UIColor(hexString: "#8EC5F5")
    private let strokeWidth: CGFloat = 1.5

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let w = rect.width
        let h = rect.height

        // Scale factor: original viewBox is 88×180
        let sx = w / 88.0
        let sy = h / 180.0
        let s = min(sx, sy)

        ctx.saveGState()
        ctx.translateBy(x: (w - 88 * s) / 2, y: (h - 180 * s) / 2)
        ctx.scaleBy(x: s, y: s)

        fillColor.setFill()
        strokeColor.setStroke()
        ctx.setLineWidth(strokeWidth)

        // Head (ellipse)
        let headPath = UIBezierPath(ovalIn: CGRect(x: 31, y: 2, width: 26, height: 28))
        headPath.fill()
        headPath.stroke()

        // Neck (rounded rect)
        let neckPath = UIBezierPath(roundedRect: CGRect(x: 38, y: 28, width: 12, height: 9), cornerRadius: 3)
        neckPath.fill()
        neckPath.stroke()

        // Torso (custom path)
        let torsoPath = UIBezierPath()
        torsoPath.move(to: CGPoint(x: 12, y: 44))
        torsoPath.addCurve(to: CGPoint(x: 14, y: 108), controlPoint1: CGPoint(x: 10, y: 58), controlPoint2: CGPoint(x: 12, y: 88))
        torsoPath.addLine(to: CGPoint(x: 18, y: 118))
        torsoPath.addQuadCurve(to: CGPoint(x: 44, y: 123), controlPoint: CGPoint(x: 31, y: 124))
        torsoPath.addQuadCurve(to: CGPoint(x: 70, y: 118), controlPoint: CGPoint(x: 57, y: 124))
        torsoPath.addLine(to: CGPoint(x: 74, y: 108))
        torsoPath.addCurve(to: CGPoint(x: 76, y: 44), controlPoint1: CGPoint(x: 76, y: 88), controlPoint2: CGPoint(x: 78, y: 58))
        torsoPath.addCurve(to: CGPoint(x: 12, y: 44), controlPoint1: CGPoint(x: 44, y: 37), controlPoint2: CGPoint(x: 24, y: 38))
        torsoPath.close()
        torsoPath.fill()
        torsoPath.stroke()

        // Left arm
        let leftArmPath = UIBezierPath()
        leftArmPath.move(to: CGPoint(x: 13, y: 47))
        leftArmPath.addCurve(to: CGPoint(x: 6, y: 110), controlPoint1: CGPoint(x: 2, y: 63), controlPoint2: CGPoint(x: 4, y: 98))
        leftArmPath.addLine(to: CGPoint(x: 12, y: 109))
        leftArmPath.addCurve(to: CGPoint(x: 20, y: 54), controlPoint1: CGPoint(x: 11, y: 98), controlPoint2: CGPoint(x: 9, y: 66))
        leftArmPath.close()
        leftArmPath.fill()
        leftArmPath.stroke()

        // Right arm
        let rightArmPath = UIBezierPath()
        rightArmPath.move(to: CGPoint(x: 75, y: 47))
        rightArmPath.addCurve(to: CGPoint(x: 82, y: 110), controlPoint1: CGPoint(x: 86, y: 63), controlPoint2: CGPoint(x: 84, y: 98))
        rightArmPath.addLine(to: CGPoint(x: 76, y: 109))
        rightArmPath.addCurve(to: CGPoint(x: 68, y: 54), controlPoint1: CGPoint(x: 77, y: 98), controlPoint2: CGPoint(x: 79, y: 66))
        rightArmPath.close()
        rightArmPath.fill()
        rightArmPath.stroke()

        // Left leg
        let leftLegPath = UIBezierPath()
        leftLegPath.move(to: CGPoint(x: 23, y: 120))
        leftLegPath.addCurve(to: CGPoint(x: 23, y: 176), controlPoint1: CGPoint(x: 21, y: 146), controlPoint2: CGPoint(x: 22, y: 164))
        leftLegPath.addLine(to: CGPoint(x: 34, y: 176))
        leftLegPath.addCurve(to: CGPoint(x: 35, y: 120), controlPoint1: CGPoint(x: 34, y: 164), controlPoint2: CGPoint(x: 35, y: 146))
        leftLegPath.close()
        leftLegPath.fill()
        leftLegPath.stroke()

        // Right leg
        let rightLegPath = UIBezierPath()
        rightLegPath.move(to: CGPoint(x: 53, y: 120))
        rightLegPath.addCurve(to: CGPoint(x: 54, y: 176), controlPoint1: CGPoint(x: 53, y: 146), controlPoint2: CGPoint(x: 54, y: 164))
        rightLegPath.addLine(to: CGPoint(x: 65, y: 176))
        rightLegPath.addCurve(to: CGPoint(x: 65, y: 120), controlPoint1: CGPoint(x: 67, y: 164), controlPoint2: CGPoint(x: 67, y: 146))
        rightLegPath.close()
        rightLegPath.fill()
        rightLegPath.stroke()

        ctx.restoreGState()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 88, height: 180)
    }
}
