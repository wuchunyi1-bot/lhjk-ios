import UIKit
import SnapKit

/// 体征监测指标卡片 Cell — 含装饰背景
/// 参考 funde-client: metric-card + MetricCardVisual
final class MetricCardCell: UICollectionViewCell {

    static let reuseIdentifier = "MetricCardCell"

    // MARK: - UI

    /// 装饰背景层（右下角，渐变遮罩从左淡入）
    private let visualBg: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14
        v.clipsToBounds = true
        return v
    }()

    private let iconBg: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 10
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let badgeView = UIView()
    private let badgeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .semibold)
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .fdSubtext
        return l
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.textColor = .fdText
        return l
    }()

    private let unitLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = .fdSubtext
        return l
    }()

    private let trendIcon: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = UIColor(hexString: "#1a1a1a")
        l.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        l.layer.cornerRadius = 6
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .fdSurface
        contentView.layer.cornerRadius = 18
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 1)
        contentView.layer.shadowRadius = 6
        contentView.layer.shadowOpacity = 0.03
        contentView.clipsToBounds = true

        badgeView.layer.cornerRadius = 999
        badgeView.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }

        iconBg.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(18)
        }

        // 装饰背景 (最底层)
        contentView.addSubview(visualBg)
        // 前景层
        contentView.addSubview(iconBg)
        contentView.addSubview(badgeView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(unitLabel)
        contentView.addSubview(trendIcon)
        contentView.addSubview(timeLabel)

        // 装饰背景：右下角，左侧渐隐
        visualBg.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.62)
            make.height.equalTo(visualBg.snp.width).multipliedBy(86.0 / 180.0)
            make.height.lessThanOrEqualToSuperview().multipliedBy(0.58)
        }

        iconBg.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(14)
            make.size.equalTo(30)
        }
        badgeView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(14)
            make.trailing.equalToSuperview().offset(-14)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconBg.snp.bottom).offset(10)
            make.leading.equalToSuperview().inset(14)
        }
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.equalToSuperview().inset(14)
        }
        unitLabel.snp.makeConstraints { make in
            make.lastBaseline.equalTo(valueLabel)
            make.leading.equalTo(valueLabel.snp.trailing).offset(4)
        }
        trendIcon.snp.makeConstraints { make in
            make.centerY.equalTo(valueLabel)
            make.trailing.equalToSuperview().offset(-14)
            make.size.equalTo(14)
        }
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(6)
            make.leading.equalToSuperview().inset(14)
            make.bottom.lessThanOrEqualToSuperview().offset(-14)
        }

        // 左侧渐变遮罩（在视觉背景上叠加一个 mask view）
        applyLeftFadeMask()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Left fade mask

    private var fadeMaskApplied = false

    private func applyLeftFadeMask() {
        guard !fadeMaskApplied else { return }
        fadeMaskApplied = true

        let mask = CAGradientLayer()
        mask.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        mask.startPoint = CGPoint(x: 0, y: 0.5)
        mask.endPoint = CGPoint(x: 0.42, y: 0.5)
        mask.frame = bounds

        // 在 layoutSubviews 中更新 frame
        visualBg.layer.mask = mask
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        visualBg.layer.mask?.frame = visualBg.bounds
    }

    // MARK: - Metric background colors

    private let metricBgColors: [String: UIColor] = [
        "blood-pressure": UIColor(hexString: "#FFE9DF"),
        "blood-sugar":    UIColor(hexString: "#FFE1DF"),
        "weight":         UIColor(hexString: "#DDF7F0"),
        "heart-rate":     UIColor(hexString: "#FFE5ED"),
        "ecg":            UIColor(hexString: "#FFE5ED"),
        "sleep":          UIColor(hexString: "#ECE7FF"),
        "spo2":           UIColor(hexString: "#E7F8F0"),
        "exercise":       UIColor(hexString: "#FFF3EE"),
        "fundus":         UIColor(hexString: "#EAF3FF"),
        "digestive":      UIColor(hexString: "#FFF3EE"),
    ]

    private let metricDecorColors: [String: UIColor] = [
        "blood-pressure": UIColor(hexString: "#FFB48A"),
        "blood-sugar":    UIColor(hexString: "#FFB7B2"),
        "weight":         UIColor(hexString: "#80DCC9"),
        "heart-rate":     UIColor(hexString: "#F4A3B7"),
        "ecg":            UIColor(hexString: "#F4A3B7"),
        "sleep":          UIColor(hexString: "#9D8BE8"),
        "spo2":           UIColor(hexString: "#79D8A4"),
        "exercise":       UIColor(hexString: "#FFC66B"),
        "fundus":         UIColor(hexString: "#8DB6E8"),
        "digestive":      UIColor(hexString: "#FFB48A"),
    ]

    // MARK: - Configure

    func configure(
        metricKey: String = "",
        icon: String,
        status: String,
        statusType: String,
        label: String,
        value: String,
        unit: String,
        trend: String,
        time: String
    ) {
        let isWarning = statusType == "warning"

        // 装饰背景
        let bgColor = metricBgColors[metricKey] ?? UIColor(hexString: "#FFF3EE")
        let decorColor = metricDecorColors[metricKey] ?? UIColor(hexString: "#FFB48A")
        visualBg.backgroundColor = bgColor

        // 清除旧的装饰子图层，添加新的
        visualBg.layer.sublayers?.removeAll(where: { $0 is CAShapeLayer })
        let decorLayer = makeDecorLayer(for: metricKey, color: decorColor)
        if let decor = decorLayer {
            visualBg.layer.addSublayer(decor)
        }

        iconBg.backgroundColor = isWarning ? .fdWarningSoft : .fdSuccessSoft
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = isWarning ? UIColor(hexString: "#B47300") : .fdSuccess

        badgeView.backgroundColor = isWarning ? .fdWarningSoft : .fdSuccessSoft
        badgeLabel.text = status
        badgeLabel.textColor = isWarning ? UIColor(hexString: "#B47300") : .fdSuccess

        titleLabel.text = label
        valueLabel.text = value
        unitLabel.text = unit

        switch trend {
        case "up":
            trendIcon.image = UIImage(systemName: "arrow.up.right")
            trendIcon.tintColor = .fdDanger
        case "down":
            trendIcon.image = UIImage(systemName: "arrow.down.right")
            trendIcon.tintColor = .fdSuccess
        default:
            trendIcon.image = UIImage(systemName: "minus")
            trendIcon.tintColor = .fdMuted
        }

        timeLabel.text = " \(time) "

        if isWarning {
            contentView.layer.borderWidth = 1
            contentView.layer.borderColor = UIColor.fdPrimaryEdge.cgColor
        } else {
            contentView.layer.borderWidth = 0
        }
    }

    // MARK: - Decor layers

    private func makeDecorLayer(for key: String, color: UIColor) -> CAShapeLayer? {
        switch key {
        case "blood-pressure":
            return makeBpDecor(color: color)
        case "blood-sugar":
            return makeBsDecor(color: color)
        case "weight":
            return makeWeightDecor(color: color)
        case "heart-rate", "ecg":
            return makeEcgDecor(color: color)
        case "sleep":
            return makeSleepDecor(color: color)
        case "spo2":
            return makeSpo2Decor(color: color)
        case "exercise":
            return makeExerciseDecor(color: color)
        case "fundus":
            return makeFundusDecor(color: color)
        case "digestive":
            return makeDigestiveDecor(color: color)
        default:
            return makeDefaultDecor(color: color)
        }
    }

    private func decorPath(in bounds: CGRect, draw: (CGRect) -> UIBezierPath) -> CAShapeLayer {
        let shape = CAShapeLayer()
        shape.frame = bounds
        shape.path = draw(bounds).cgPath
        shape.fillColor = nil
        return shape
    }

    /// 血压 — 底部渐变色条 + 弧线
    private func makeBpDecor(color: UIColor) -> CAShapeLayer? {
        let layer = CAShapeLayer()
        let w = visualBg.bounds.width
        let h = visualBg.bounds.height
        guard w > 0, h > 0 else { return nil }

        // 底部色条
        let bar = UIBezierPath(roundedRect: CGRect(x: w * 0.1, y: h * 0.63, width: w * 0.78, height: h * 0.09), cornerRadius: 4)
        let barLayer = CAShapeLayer()
        barLayer.path = bar.cgPath
        barLayer.fillColor = color.withAlphaComponent(0.18).cgColor
        layer.addSublayer(barLayer)

        // 弧线
        let arc = UIBezierPath()
        arc.move(to: CGPoint(x: w * 0.08, y: h * 0.93))
        arc.addCurve(to: CGPoint(x: w * 0.98, y: h * 0.37), controlPoint1: CGPoint(x: w * 0.28, y: h * 0.72), controlPoint2: CGPoint(x: w * 0.64, y: h * 0.72))
        arc.lineWidth = w * 0.08
        let arcLayer = CAShapeLayer()
        arcLayer.path = arc.cgPath
        arcLayer.strokeColor = color.withAlphaComponent(0.3).cgColor
        arcLayer.fillColor = nil
        arcLayer.lineCap = .round
        layer.addSublayer(arcLayer)

        return layer
    }

    /// 血糖 — 粉色波浪
    private func makeBsDecor(color: UIColor) -> CAShapeLayer? {
        let w = visualBg.bounds.width
        let h = visualBg.bounds.height
        guard w > 0, h > 0 else { return nil }
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: h * 0.91))
        path.addCurve(to: CGPoint(x: w * 0.21, y: h * 0.63), controlPoint1: CGPoint(x: w * 0.1, y: h * 0.78), controlPoint2: CGPoint(x: w * 0.11, y: h * 0.63))
        path.addCurve(to: CGPoint(x: w * 0.42, y: h * 0.63), controlPoint1: CGPoint(x: w * 0.31, y: h * 0.63), controlPoint2: CGPoint(x: w * 0.31, y: h * 0.23))
        path.addCurve(to: CGPoint(x: w * 0.63, y: h * 0.23), controlPoint1: CGPoint(x: w * 0.54, y: h * 0.23), controlPoint2: CGPoint(x: w * 0.51, y: h * 0.72))
        path.addCurve(to: CGPoint(x: w * 0.86, y: h * 0.72), controlPoint1: CGPoint(x: w * 0.74, y: h * 0.72), controlPoint2: CGPoint(x: w * 0.74, y: h * 0.32))
        path.addCurve(to: CGPoint(x: w, y: h * 0.67), controlPoint1: CGPoint(x: w * 0.94, y: h * 0.67), controlPoint2: CGPoint(x: w * 0.92, y: h * 0.55))
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.strokeColor = color.withAlphaComponent(0.45).cgColor
        shape.fillColor = nil
        shape.lineWidth = w * 0.035
        shape.lineCap = .round
        return shape
    }

    /// 体重 — 绿色山形区域
    private func makeWeightDecor(color: UIColor) -> CAShapeLayer? {
        let w = visualBg.bounds.width
        let h = visualBg.bounds.height
        guard w > 0, h > 0 else { return nil }
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: h * 0.74))
        path.addCurve(to: CGPoint(x: w * 0.22, y: h * 0.67), controlPoint1: CGPoint(x: w * 0.1, y: h * 0.65), controlPoint2: CGPoint(x: w * 0.14, y: h * 0.58))
        path.addCurve(to: CGPoint(x: w * 0.46, y: h * 0.35), controlPoint1: CGPoint(x: w * 0.32, y: h * 0.58), controlPoint2: CGPoint(x: w * 0.34, y: h * 0.14))
        path.addCurve(to: CGPoint(x: w * 0.66, y: h * 0.23), controlPoint1: CGPoint(x: w * 0.56, y: h * 0.23), controlPoint2: CGPoint(x: w * 0.54, y: h * 0.14))
        path.addCurve(to: CGPoint(x: w * 0.87, y: h * 0.54), controlPoint1: CGPoint(x: w * 0.76, y: h * 0.32), controlPoint2: CGPoint(x: w * 0.76, y: h * 0.58))
        path.addCurve(to: CGPoint(x: w, y: h * 0.77), controlPoint1: CGPoint(x: w * 0.94, y: h * 0.51), controlPoint2: CGPoint(x: w * 0.97, y: h * 0.65))
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.strokeColor = color.withAlphaComponent(0.5).cgColor
        shape.fillColor = nil
        shape.lineWidth = w * 0.035
        shape.lineCap = .round
        return shape
    }

    /// 心率 / 心电 — 心电图线
    private func makeEcgDecor(color: UIColor) -> CAShapeLayer? {
        let w = visualBg.bounds.width
        let h = visualBg.bounds.height
        guard w > 0, h > 0 else { return nil }
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: h * 0.77))
        path.addLine(to: CGPoint(x: w * 0.08, y: h * 0.77))
        path.addLine(to: CGPoint(x: w * 0.14, y: h * 0.58))
        path.addLine(to: CGPoint(x: w * 0.20, y: h * 0.86))
        path.addLine(to: CGPoint(x: w * 0.27, y: h * 0.44))
        path.addLine(to: CGPoint(x: w * 0.34, y: h * 0.77))
        path.addLine(to: CGPoint(x: w * 0.43, y: h * 0.77))
        path.addLine(to: CGPoint(x: w * 0.49, y: h * 0.67))
        path.addLine(to: CGPoint(x: w * 0.53, y: h * 0.77))
        path.addLine(to: CGPoint(x: w * 0.63, y: h * 0.77))
        path.addLine(to: CGPoint(x: w * 0.70, y: h * 0.32))
        path.addLine(to: CGPoint(x: w * 0.78, y: h * 0.77))
        path.addLine(to: CGPoint(x: w * 0.86, y: h * 0.77))
        path.addLine(to: CGPoint(x: w * 0.90, y: h * 0.63))
        path.addLine(to: CGPoint(x: w * 0.94, y: h * 0.77))
        path.addLine(to: CGPoint(x: w, y: h * 0.77))
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.strokeColor = color.withAlphaComponent(0.5).cgColor
        shape.fillColor = nil
        shape.lineWidth = w * 0.025
        shape.lineCap = .round
        shape.lineJoin = .round
        return shape
    }

    /// 睡眠 — 紫色山形 + 星星
    private func makeSleepDecor(color: UIColor) -> CAShapeLayer? {
        let w = visualBg.bounds.width
        let h = visualBg.bounds.height
        guard w > 0, h > 0 else { return nil }
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: h * 0.72))
        path.addCurve(to: CGPoint(x: w * 0.18, y: h * 0.56), controlPoint1: CGPoint(x: w * 0.09, y: h * 0.56), controlPoint2: CGPoint(x: w * 0.13, y: h * 0.72))
        path.addCurve(to: CGPoint(x: w * 0.37, y: h * 0.65), controlPoint1: CGPoint(x: w * 0.25, y: h * 0.72), controlPoint2: CGPoint(x: w * 0.29, y: h * 0.49))
        path.addCurve(to: CGPoint(x: w * 0.54, y: h * 0.58), controlPoint1: CGPoint(x: w * 0.45, y: h * 0.72), controlPoint2: CGPoint(x: w * 0.48, y: h * 0.42))
        path.addCurve(to: CGPoint(x: w * 0.70, y: h * 0.52), controlPoint1: CGPoint(x: w * 0.62, y: h * 0.67), controlPoint2: CGPoint(x: w * 0.65, y: h * 0.44))
        path.addCurve(to: CGPoint(x: w, y: h * 0.53), controlPoint1: CGPoint(x: w * 0.81, y: h * 0.44), controlPoint2: CGPoint(x: w * 0.87, y: h * 0.67))
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.strokeColor = color.withAlphaComponent(0.35).cgColor
        shape.fillColor = nil
        shape.lineWidth = w * 0.035
        shape.lineCap = .round
        return shape
    }

    /// 血氧 — 绿色波浪
    private func makeSpo2Decor(color: UIColor) -> CAShapeLayer? {
        let w = visualBg.bounds.width
        let h = visualBg.bounds.height
        guard w > 0, h > 0 else { return nil }
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: h * 0.79))
        path.addCurve(to: CGPoint(x: w * 0.21, y: h * 0.72), controlPoint1: CGPoint(x: w * 0.09, y: h * 0.72), controlPoint2: CGPoint(x: w * 0.13, y: h * 0.81))
        path.addCurve(to: CGPoint(x: w * 0.42, y: h * 0.72), controlPoint1: CGPoint(x: w * 0.30, y: h * 0.81), controlPoint2: CGPoint(x: w * 0.33, y: h * 0.60))
        path.addCurve(to: CGPoint(x: w * 0.67, y: h * 0.67), controlPoint1: CGPoint(x: w * 0.52, y: h * 0.81), controlPoint2: CGPoint(x: w * 0.57, y: h * 0.58))
        path.addCurve(to: CGPoint(x: w, y: h * 0.58), controlPoint1: CGPoint(x: w * 0.78, y: h * 0.51), controlPoint2: CGPoint(x: w * 0.84, y: h * 0.72))
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.strokeColor = color.withAlphaComponent(0.42).cgColor
        shape.fillColor = nil
        shape.lineWidth = w * 0.035
        shape.lineCap = .round
        return shape
    }

    /// 饮食运动 — 弧线
    private func makeExerciseDecor(color: UIColor) -> CAShapeLayer? {
        let w = visualBg.bounds.width
        let h = visualBg.bounds.height
        guard w > 0, h > 0 else { return nil }
        let path = UIBezierPath()
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.81))
        path.addCurve(to: CGPoint(x: w * 0.33, y: h * 0.56), controlPoint1: CGPoint(x: w * 0.25, y: h * 0.67), controlPoint2: CGPoint(x: w * 0.2, y: h * 0.63))
        path.addCurve(to: CGPoint(x: w * 0.54, y: h * 0.52), controlPoint1: CGPoint(x: w * 0.49, y: h * 0.47), controlPoint2: CGPoint(x: w * 0.4, y: h * 0.63))
        path.addCurve(to: CGPoint(x: w * 0.69, y: h * 0.32), controlPoint1: CGPoint(x: w * 0.64, y: h * 0.44), controlPoint2: CGPoint(x: w * 0.58, y: h * 0.35))
        path.addCurve(to: CGPoint(x: w * 0.89, y: h * 0.42), controlPoint1: CGPoint(x: w * 0.79, y: h * 0.35), controlPoint2: CGPoint(x: w * 0.83, y: h * 0.49))
        path.addCurve(to: CGPoint(x: w, y: h * 0.35), controlPoint1: CGPoint(x: w * 0.97, y: h * 0.35), controlPoint2: CGPoint(x: w * 0.92, y: h * 0.44))
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.strokeColor = color.withAlphaComponent(0.30).cgColor
        shape.fillColor = nil
        shape.lineWidth = w * 0.035
        shape.lineCap = .round
        return shape
    }

    /// 鹰瞳眼底 — 椭圆 + 圆
    private func makeFundusDecor(color: UIColor) -> CAShapeLayer? {
        let w = visualBg.bounds.width
        let h = visualBg.bounds.height
        guard w > 0, h > 0 else { return nil }
        let layer = CAShapeLayer()

        // 大椭圆
        let ellipse = UIBezierPath(ovalIn: CGRect(x: w * 0.25, y: h * 0.1, width: w * 0.53, height: h * 0.58))
        let eLayer = CAShapeLayer()
        eLayer.path = ellipse.cgPath
        eLayer.fillColor = color.withAlphaComponent(0.15).cgColor
        layer.addSublayer(eLayer)

        // 小圆
        let circle = UIBezierPath(ovalIn: CGRect(x: w * 0.38, y: h * 0.2, width: w * 0.28, height: h * 0.42))
        let cLayer = CAShapeLayer()
        cLayer.path = circle.cgPath
        cLayer.strokeColor = color.withAlphaComponent(0.24).cgColor
        cLayer.fillColor = nil
        cLayer.lineWidth = w * 0.03
        layer.addSublayer(cLayer)

        return layer
    }

    /// 消化道 — 曲线
    private func makeDigestiveDecor(color: UIColor) -> CAShapeLayer? {
        let w = visualBg.bounds.width
        let h = visualBg.bounds.height
        guard w > 0, h > 0 else { return nil }
        let path = UIBezierPath()
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.21))
        path.addCurve(to: CGPoint(x: w * 0.44, y: h * 0.57), controlPoint1: CGPoint(x: w * 0.5, y: h * 0.39), controlPoint2: CGPoint(x: w * 0.39, y: h * 0.39))
        path.addCurve(to: CGPoint(x: w * 0.57, y: h * 0.56), controlPoint1: CGPoint(x: w * 0.5, y: h * 0.65), controlPoint2: CGPoint(x: w * 0.53, y: h * 0.51))
        path.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.70), controlPoint1: CGPoint(x: w * 0.60, y: h * 0.60), controlPoint2: CGPoint(x: w * 0.50, y: h * 0.68))
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.strokeColor = color.withAlphaComponent(0.25).cgColor
        shape.fillColor = nil
        shape.lineWidth = w * 0.04
        shape.lineCap = .round
        return shape
    }

    /// 默认 — 简单色彩底
    private func makeDefaultDecor(color: UIColor) -> CAShapeLayer? {
        let w = visualBg.bounds.width
        let h = visualBg.bounds.height
        guard w > 0, h > 0 else { return nil }
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: h * 0.81))
        path.addCurve(to: CGPoint(x: w * 0.22, y: h * 0.63), controlPoint1: CGPoint(x: w * 0.09, y: h * 0.63), controlPoint2: CGPoint(x: w * 0.14, y: h * 0.84))
        path.addCurve(to: CGPoint(x: w * 0.46, y: h * 0.56), controlPoint1: CGPoint(x: w * 0.31, y: h * 0.72), controlPoint2: CGPoint(x: w * 0.36, y: h * 0.47))
        path.addCurve(to: CGPoint(x: w * 0.71, y: h * 0.56), controlPoint1: CGPoint(x: w * 0.56, y: h * 0.65), controlPoint2: CGPoint(x: w * 0.62, y: h * 0.47))
        path.addCurve(to: CGPoint(x: w, y: h * 0.44), controlPoint1: CGPoint(x: w * 0.82, y: h * 0.39), controlPoint2: CGPoint(x: w * 0.91, y: h * 0.56))
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.strokeColor = color.withAlphaComponent(0.35).cgColor
        shape.fillColor = nil
        shape.lineWidth = w * 0.035
        shape.lineCap = .round
        return shape
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.layer.borderWidth = 0
        visualBg.layer.sublayers?.removeAll(where: { $0 is CAShapeLayer })
    }
}
