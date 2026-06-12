import UIKit
import SnapKit

/// 水平刻度尺控件 — Funde MetricRuler 的 iOS 实现
/// 基于 UIScrollView + 自定义刻度绘制，中心指针定位
final class MetricRulerView: UIView {

    // MARK: - Config

    private let minValue: Double
    private let maxValue: Double
    private let step: Double
    private let labelEvery: Double
    private let unit: String

    private(set) var currentValue: Double
    var onValueChanged: ((Double) -> Void)?

    // MARK: - Constants

    private let tickSpacing: CGFloat = 12   // 每个刻度的像素间距（同 Funde STEP_PX）
    private let smallTickHeight: CGFloat = 10
    private let majorTickHeight: CGFloat = 18

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.decelerationRate = .fast
        return sv
    }()

    private let pointerView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdPrimary
        v.layer.cornerRadius = 1
        return v
    }()

    private let pointerTriangle = CAShapeLayer()
    private let ticksLayer = CAShapeLayer()
    private var tickLabels: [UILabel] = []

    private var totalSteps: Int { Int(round((maxValue - minValue) / step)) }
    private var majorEvery: Int {
        if labelEvery > 0 { return max(1, Int(round(labelEvery / step))) }
        return step < 1 ? max(1, Int(round(1 / step))) : 5
    }

    // MARK: - Init

    init(min: Double, max: Double, step: Double, defaultValue: Double, labelEvery: Double = 0, unit: String = "") {
        self.minValue = min
        self.maxValue = max
        self.step = step
        self.labelEvery = labelEvery
        self.unit = unit
        self.currentValue = defaultValue

        super.init(frame: .zero)
        backgroundColor = .fdSurface
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor(hexString: "#F0F0F0").cgColor

        addSubview(scrollView)
        scrollView.delegate = self
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Center pointer
        addSubview(pointerView)
        pointerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(2)
        }

        // Triangle at bottom
        let triPath = UIBezierPath()
        triPath.move(to: CGPoint(x: 0, y: 0))
        triPath.addLine(to: CGPoint(x: -5, y: 6))
        triPath.addLine(to: CGPoint(x: 5, y: 6))
        triPath.close()
        pointerTriangle.path = triPath.cgPath
        pointerTriangle.fillColor = UIColor.fdPrimary.cgColor
        pointerView.layer.addSublayer(pointerTriangle)
        pointerTriangle.position = CGPoint(x: 1, y: bounds.height) // will be adjusted in layoutSubviews

        self.snp.makeConstraints { $0.height.equalTo(64) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        pointerTriangle.position = CGPoint(x: 1, y: bounds.height - 1)
        buildTicks()
    }

    // MARK: - Build Ticks

    private func buildTicks() {
        ticksLayer.removeFromSuperlayer()
        tickLabels.forEach { $0.removeFromSuperview() }
        tickLabels.removeAll()

        let contentWidth = CGFloat(totalSteps) * tickSpacing
        let pad = bounds.width / 2
        scrollView.contentSize = CGSize(width: contentWidth + pad * 2, height: bounds.height)
        scrollView.contentInset = UIEdgeInsets(top: 0, left: pad, bottom: 0, right: pad)

        // Draw ticks via CAShapeLayer
        let path = UIBezierPath()
        for i in 0...totalSteps {
            let x = pad + CGFloat(i) * tickSpacing
            let isMajor = i % majorEvery == 0
            let tickH = isMajor ? majorTickHeight : smallTickHeight
            let y = bounds.height - 18 - tickH
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x, y: y + tickH))

            // Labels for major ticks
            if isMajor {
                let val = minValue + Double(i) * step
                let text = formatValue(val)
                let label = UILabel()
                label.text = text
                label.font = .systemFont(ofSize: 10)
                label.textColor = .fdSubtext
                label.sizeToFit()
                label.center = CGPoint(x: x, y: y + tickH + 10 + label.bounds.height / 2)
                scrollView.addSubview(label)
                tickLabels.append(label)
            }
        }

        ticksLayer.path = path.cgPath
        ticksLayer.strokeColor = UIColor(hexString: "#DDDDDD").cgColor
        ticksLayer.lineWidth = 1
        scrollView.layer.addSublayer(ticksLayer)

        // Scroll to default value
        scrollToValue(currentValue, animated: false)
    }

    private func formatValue(_ v: Double) -> String {
        let decimals = String(step).components(separatedBy: ".").last?.count ?? 0
        return decimals > 0 ? String(format: "%.\(decimals)f", v) : String(Int(v))
    }

    // MARK: - Scroll to Value

    private func scrollToValue(_ val: Double, animated: Bool = false) {
        let offset = CGFloat((val - minValue) / step) * tickSpacing
        scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: animated)
    }

    func setValue(_ val: Double) {
        currentValue = val
        scrollToValue(val, animated: false)
    }

    // MARK: - Snap Calculation

    private func snapToNearest() {
        let centerX = scrollView.contentOffset.x + scrollView.bounds.width / 2 - scrollView.contentInset.left
        let stepIndex = Int(round(centerX / tickSpacing))
        let clamped = max(0, min(totalSteps, stepIndex))
        let newValue = minValue + Double(clamped) * step
        currentValue = newValue

        let targetOffset = CGFloat(clamped) * tickSpacing
        scrollView.setContentOffset(CGPoint(x: targetOffset, y: 0), animated: true)
        onValueChanged?(newValue)
    }
}

// MARK: - UIScrollViewDelegate

extension MetricRulerView: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { snapToNearest() }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        snapToNearest()
    }
}
