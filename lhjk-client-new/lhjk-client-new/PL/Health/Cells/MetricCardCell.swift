import UIKit
import SnapKit
import Kingfisher

/// 体征监测单卡 — 比例 155:144；内边距、字号、图标随卡片宽度同比缩放
final class MetricCardCell: UICollectionViewCell {

    static let reuseIdentifier = "MetricCardCell"

    private let watermark = UIImageView()
    private let iconView = UIImageView()
    private let badgeLabel = MetricBadgeLabel()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()
    private let timeLabel = UILabel()

    private let dietIntakeCaption = UILabel()
    private let dietIntakeValue = UILabel()
    private let dietConsumeCaption = UILabel()
    private let dietConsumeValue = UILabel()
    private let dietRingView = DietSportRingView()
    private let dietRow = UIStackView()
    private let dietLeftStack = UIStackView()
    private let dietRightStack = UIStackView()

    private var appliedLayoutScale: CGFloat = 1
    private var isDietLayout = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor(hexString: "#FDFCFC")

        watermark.contentMode = .scaleAspectFill
        watermark.clipsToBounds = true

        iconView.contentMode = .scaleAspectFit

        badgeLabel.textAlignment = .center
        badgeLabel.clipsToBounds = true

        titleLabel.textColor = UIColor(hexString: "#717885")
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        valueLabel.textColor = UIColor(hexString: "#1F2942")
        valueLabel.numberOfLines = 2
        unitLabel.textColor = UIColor(hexString: "#717885")
        timeLabel.textColor = UIColor(hexString: "#717885")

        dietIntakeCaption.text = "今日摄入"
        dietIntakeCaption.textColor = UIColor(hexString: "#717885")
        dietIntakeCaption.textAlignment = .left
        dietIntakeValue.textColor = UIColor(hexString: "#1F2942")
        dietIntakeValue.textAlignment = .left
        dietIntakeValue.adjustsFontSizeToFitWidth = true
        dietIntakeValue.minimumScaleFactor = 0.7

        dietConsumeCaption.text = "今日消耗"
        dietConsumeCaption.textColor = UIColor(hexString: "#717885")
        dietConsumeCaption.textAlignment = .right
        dietConsumeValue.textColor = UIColor(hexString: "#1F2942")
        dietConsumeValue.textAlignment = .right
        dietConsumeValue.adjustsFontSizeToFitWidth = true
        dietConsumeValue.minimumScaleFactor = 0.7

        dietLeftStack.axis = .vertical
        dietLeftStack.alignment = .leading
        dietLeftStack.spacing = 0
        dietLeftStack.addArrangedSubview(dietIntakeCaption)
        dietLeftStack.addArrangedSubview(dietIntakeValue)

        dietRightStack.axis = .vertical
        dietRightStack.alignment = .trailing
        dietRightStack.spacing = 0
        dietRightStack.addArrangedSubview(dietConsumeCaption)
        dietRightStack.addArrangedSubview(dietConsumeValue)

        dietRow.axis = .horizontal
        dietRow.alignment = .center
        dietRow.distribution = .fill
        dietRow.spacing = 4
        dietRow.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        dietRow.addArrangedSubview(dietLeftStack)
        dietRow.addArrangedSubview(dietRingView)
        dietRow.addArrangedSubview(dietRightStack)
        dietRow.isHidden = true
        dietRingView.setContentHuggingPriority(.required, for: .horizontal)
        dietRingView.setContentCompressionResistancePriority(.required, for: .horizontal)
        dietLeftStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dietRightStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        hideDietRow()

        [
            watermark, iconView, badgeLabel, titleLabel, valueLabel, unitLabel, timeLabel, dietRow,
        ].forEach(contentView.addSubview)

        watermark.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        applyProportionalLayout(scale: 1)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        guard width > 0 else { return }
        let scale = width / Design.cardWidth
        guard abs(scale - appliedLayoutScale) > 0.01 else { return }
        applyProportionalLayout(scale: scale)
    }

    private static let cardBgs: [String: UIColor] = [
        "blood-pressure": UIColor(hexString: "#FDFCFC"),
        "blood-sugar": UIColor(hexString: "#FFF8F7"),
        "weight": UIColor(hexString: "#FBFAF7"),
        "temperature": UIColor(hexString: "#FFF8FA"),
        "heart-rate": UIColor(hexString: "#FFF8FA"),
        "sleep": UIColor(hexString: "#F8F7FC"),
        "ecg": UIColor(hexString: "#FFF8FA"),
        "fundus": UIColor(hexString: "#F7FAFF"),
        "exercise": UIColor(hexString: "#FFFAF5"),
        "spo2": UIColor(hexString: "#F7FCF9"),
        "digestive": UIColor(hexString: "#FFFAF5"),
    ]

    func configure(
        metricKey: String = "",
        icon: String,
        iconUrl: String? = nil,
        backgroundUrl: String? = nil,
        status: String,
        statusType: String,
        label: String,
        value: String,
        unit: String,
        trend: String,
        time: String,
        dietSport: DietSportCardDisplay? = nil
    ) {
        let bg = Self.cardBgs[metricKey] ?? UIColor(hexString: "#FDFCFC")
        contentView.backgroundColor = bg
        applyBackground(backgroundUrl: backgroundUrl, metricKey: metricKey)

        iconView.kf.cancelDownloadTask()
        if let iconUrl, let url = URL(string: iconUrl) {
            iconView.tintColor = nil
            iconView.kf.setImage(with: url, options: [.transition(.fade(0.15))])
        } else {
            iconView.image = UIImage(systemName: icon)
            iconView.tintColor = .fdPrimary
        }

        let trimmedStatus = status.trimmingCharacters(in: .whitespacesAndNewlines)
        badgeLabel.isHidden = trimmedStatus.isEmpty
        badgeLabel.text = trimmedStatus
        switch statusType {
        case "warning":
            badgeLabel.backgroundColor = UIColor(hexString: "#FFEDED")
            badgeLabel.textColor = UIColor(hexString: "#DF0340")
        case "info":
            badgeLabel.backgroundColor = UIColor(hexString: "#FFF0E0")
            badgeLabel.textColor = UIColor(hexString: "#FF6637")
        default:
            badgeLabel.backgroundColor = UIColor(hexString: "#E9F6F2")
            badgeLabel.textColor = UIColor(hexString: "#2EBA83")
        }

        isDietLayout = dietSport != nil
        titleLabel.text = label
        valueLabel.text = value
        unitLabel.text = unit
        timeLabel.text = time
        timeLabel.isHidden = time.isEmpty

        if let dietSport {
            titleLabel.isHidden = false
            valueLabel.isHidden = true
            unitLabel.isHidden = true
            dietLeftStack.isHidden = false
            dietRightStack.isHidden = false
            dietRingView.isHidden = false
            dietRow.isHidden = false
            dietIntakeValue.text = dietSport.intakeText
            dietConsumeValue.text = dietSport.consumeText
            dietRingView.configure(remainingText: dietSport.remainingText, progress: dietSport.progress)
        } else {
            titleLabel.isHidden = false
            valueLabel.isHidden = false
            unitLabel.isHidden = unit.isEmpty || value == "--"
            hideDietRow()
        }

        if bounds.width > 0 {
            applyProportionalLayout(scale: bounds.width / Design.cardWidth)
        }
    }

    private func applyProportionalLayout(scale: CGFloat) {
        appliedLayoutScale = scale

        contentView.layer.cornerRadius = Design.cornerRadius * scale

        badgeLabel.font = .fdFont(ofSize: Design.badgeFontSize * scale, weight: .regular)
        badgeLabel.layer.cornerRadius = Design.badgeCornerRadius * scale
        badgeLabel.contentInsets = UIEdgeInsets(
            top: Design.badgePadding.top * scale,
            left: Design.badgePadding.left * scale,
            bottom: Design.badgePadding.bottom * scale,
            right: Design.badgePadding.right * scale
        )
        badgeLabel.invalidateIntrinsicContentSize()

        titleLabel.font = .fdFont(ofSize: Design.titleFontSize * scale, weight: .regular)
        valueLabel.font = .fdFont(ofSize: Design.valueFontSize * scale, weight: .medium)
        unitLabel.font = .fdFont(ofSize: Design.unitFontSize * scale, weight: .regular)
        timeLabel.font = .fdFont(ofSize: Design.timeFontSize * scale, weight: .regular)

        dietIntakeCaption.font = .fdFont(ofSize: Design.dietCaptionFontSize * scale, weight: .regular)
        dietConsumeCaption.font = .fdFont(ofSize: Design.dietCaptionFontSize * scale, weight: .regular)
        dietIntakeValue.font = .fdFont(ofSize: Design.dietValueFontSize * scale, weight: .medium)
        dietConsumeValue.font = .fdFont(ofSize: Design.dietValueFontSize * scale, weight: .medium)
        dietRingView.applyScale(scale)

        let inset = Design.edgeInset * scale
        let iconTitleGap = Design.iconTitleGap * scale
        let titleValueGap = Design.titleValueGap * scale
        let unitGap = Design.unitGap * scale
        let valueTimeGap = Design.valueTimeGap * scale
        let timeBottomInset = Design.timeBottomInset * scale
        let ringSize = Design.dietRingSize * scale

        iconView.snp.remakeConstraints {
            $0.top.leading.equalToSuperview().inset(inset)
            $0.size.equalTo(Design.iconSize * scale)
        }
        badgeLabel.snp.remakeConstraints {
            $0.top.trailing.equalToSuperview().inset(inset)
            $0.height.equalTo(Design.badgeHeight * scale)
        }
        timeLabel.snp.remakeConstraints {
            $0.leading.equalToSuperview().inset(inset)
            $0.bottom.equalToSuperview().inset(timeBottomInset)
            $0.trailing.lessThanOrEqualToSuperview().inset(inset)
            if timeLabel.isHidden {
                $0.height.equalTo(0)
            }
        }

        if isDietLayout {
            titleLabel.snp.remakeConstraints {
                $0.leading.equalToSuperview().inset(inset)
                $0.top.equalTo(iconView.snp.bottom).offset(iconTitleGap)
                $0.trailing.lessThanOrEqualToSuperview().inset(inset)
            }
            valueLabel.snp.remakeConstraints { $0.leading.top.equalToSuperview() }
            unitLabel.snp.remakeConstraints { $0.leading.top.equalToSuperview() }

            dietRingView.snp.remakeConstraints {
                $0.size.equalTo(ringSize)
            }
            dietLeftStack.snp.remakeConstraints {
                $0.width.equalTo(dietRightStack)
            }
            dietRow.snp.remakeConstraints {
                $0.leading.trailing.equalToSuperview().inset(inset)
                $0.top.equalTo(titleLabel.snp.bottom).offset(Design.dietRowTopGap * scale)
                $0.bottom.lessThanOrEqualTo(timeLabel.snp.top).offset(-4).priority(.low)
            }
        } else {
            titleLabel.snp.remakeConstraints {
                $0.leading.equalToSuperview().inset(inset)
                $0.top.equalTo(iconView.snp.bottom).offset(iconTitleGap)
                $0.trailing.lessThanOrEqualToSuperview().inset(inset)
            }
            valueLabel.snp.remakeConstraints {
                $0.leading.equalToSuperview().inset(inset)
                $0.top.equalTo(titleLabel.snp.bottom).offset(titleValueGap)
                if timeLabel.isHidden {
                    $0.bottom.lessThanOrEqualToSuperview().inset(inset)
                } else {
                    $0.bottom.lessThanOrEqualTo(timeLabel.snp.top).offset(-valueTimeGap)
                }
            }
            unitLabel.snp.remakeConstraints {
                $0.leading.equalTo(valueLabel.snp.trailing).offset(unitGap)
                $0.lastBaseline.equalTo(valueLabel)
                $0.trailing.lessThanOrEqualToSuperview().inset(Design.unitTrailingInset * scale)
            }
            hideDietRow()
            dietRow.snp.remakeConstraints {
                $0.top.leading.equalToSuperview()
            }
        }
    }

    private func hideDietRow() {
        dietLeftStack.isHidden = true
        dietRightStack.isHidden = true
        dietRingView.isHidden = true
        dietRow.isHidden = true
    }

    /// 背景图：服务端 `backgroundUrl` → 本地 `metric_*` → 仅底色
    private func applyBackground(backgroundUrl: String?, metricKey: String) {
        watermark.kf.cancelDownloadTask()
        let remote = backgroundUrl?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
            .flatMap { URL(string: $0) }

        if let remote {
            watermark.kf.setImage(
                with: remote,
                options: [.transition(.fade(0.15))],
                completionHandler: { [weak self] result in
                    guard case .failure = result else { return }
                    self?.applyLocalBackground(metricKey: metricKey)
                }
            )
        } else {
            applyLocalBackground(metricKey: metricKey)
        }
    }

    private func applyLocalBackground(metricKey: String) {
        guard let name = Self.localBackgroundAsset(for: metricKey),
              let image = UIImage(named: name) else {
            watermark.image = nil
            return
        }
        watermark.image = image
    }

    private static func localBackgroundAsset(for metricKey: String) -> String? {
        switch metricKey {
        case "blood-pressure": return "metric_bp"
        case "blood-sugar": return "metric_bs"
        case "weight": return "metric_weight"
        case "temperature": return "metric_temperature"
        case "heart-rate": return "metric_hr"
        case "sleep": return "metric_sleep"
        case "ecg": return "metric_ecg"
        case "fundus": return "metric_fundus"
        case "exercise": return "metric_exercise"
        case "spo2": return "metric_spo2"
        case "digestive": return "metric_digestive"
        case "medication": return "metric_medication"
        case "supplement": return "metric_supplement"
        default: return nil
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        watermark.kf.cancelDownloadTask()
        watermark.image = nil
        iconView.kf.cancelDownloadTask()
        iconView.image = nil
        badgeLabel.text = nil
        badgeLabel.isHidden = true
        isDietLayout = false
        dietIntakeValue.text = nil
        dietConsumeValue.text = nil
        dietRingView.configure(remainingText: "--", progress: 0)
        hideDietRow()
        titleLabel.isHidden = false
        valueLabel.isHidden = false
    }
}

// MARK: - 设计稿基准（155×144 单卡）

private enum Design {
    static let cardWidth: CGFloat = 155
    static let cornerRadius: CGFloat = 16
    static let edgeInset: CGFloat = 12
    static let iconSize: CGFloat = 22
    static let badgeHeight: CGFloat = 18
    static let badgeFontSize: CGFloat = 10
    static let badgeCornerRadius: CGFloat = 9
    static let badgePadding = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
    static let iconTitleGap: CGFloat = 10
    static let titleFontSize: CGFloat = 12
    static let titleValueGap: CGFloat = 6
    static let valueFontSize: CGFloat = 20
    static let unitFontSize: CGFloat = 12
    static let unitGap: CGFloat = 4
    static let unitTrailingInset: CGFloat = 8
    static let valueTimeGap: CGFloat = 8
    static let timeFontSize: CGFloat = 12
    /// 时间底边距（大于 edgeInset，使时间略上移）
    static let timeBottomInset: CGFloat = 16
    static let dietCaptionFontSize: CGFloat = 8
    static let dietValueFontSize: CGFloat = 12
    static let dietRingSize: CGFloat = 52
    static let dietRingLineWidth: CGFloat = 3
    static let dietRowTopGap: CGFloat = 8
}

// MARK: - Metric Badge Label (Padding)

private final class MetricBadgeLabel: UILabel {
    var contentInsets = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }
}

/// 饮食运动「还可摄入」圆环（文案画在环内，避免被轨道层挡住）
private final class DietSportRingView: UIView {
    private var progress: CGFloat = 0
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let captionLabel = UILabel()
    private let valueLabel = UILabel()
    private let textStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        clipsToBounds = false

        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor(hexString: "#E6E6E6").cgColor
        trackLayer.lineCap = .round
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor(hexString: "#87C617").cgColor
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)

        captionLabel.text = "还可摄入"
        captionLabel.textColor = UIColor(hexString: "#717885")
        captionLabel.textAlignment = .center
        captionLabel.numberOfLines = 1
        captionLabel.adjustsFontSizeToFitWidth = true
        captionLabel.minimumScaleFactor = 0.7

        valueLabel.textColor = UIColor(hexString: "#1F2942")
        valueLabel.textAlignment = .center
        valueLabel.numberOfLines = 1
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.5

        textStack.axis = .vertical
        textStack.alignment = .center
        textStack.spacing = 0
        textStack.addArrangedSubview(captionLabel)
        textStack.addArrangedSubview(valueLabel)
        addSubview(textStack)
        textStack.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(8)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(remainingText: String, progress: CGFloat) {
        valueLabel.text = remainingText
        self.progress = min(1, max(0, progress))
        updateProgress()
    }

    func applyScale(_ scale: CGFloat) {
        captionLabel.font = .fdFont(ofSize: Design.dietCaptionFontSize * scale, weight: .regular)
        valueLabel.font = .fdFont(ofSize: Design.dietValueFontSize * scale, weight: .medium)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let lineWidth = max(1, bounds.width * (Design.dietRingLineWidth / Design.dietRingSize))
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = max(0, (min(bounds.width, bounds.height) - lineWidth) / 2)
        let start: CGFloat = -.pi / 2
        // 12 点起沿逆时针增长（strokeEnd 沿 path 方向）
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: start,
            endAngle: start - .pi * 2,
            clockwise: false
        ).cgPath
        trackLayer.frame = bounds
        progressLayer.frame = bounds
        trackLayer.lineWidth = lineWidth
        progressLayer.lineWidth = lineWidth
        trackLayer.path = path
        progressLayer.path = path
        bringSubviewToFront(textStack)
        updateProgress()
    }

    private func updateProgress() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        progressLayer.strokeEnd = progress
        CATransaction.commit()
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
