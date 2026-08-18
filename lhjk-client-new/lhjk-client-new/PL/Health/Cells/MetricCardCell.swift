import UIKit
import SnapKit
import Kingfisher

/// 体征监测单卡 — 对齐 Figma：软底 + 左侧圆形水印 + 状态胶囊
final class MetricCardCell: UICollectionViewCell {

    static let reuseIdentifier = "MetricCardCell"

    private let watermark = UIImageView()
    private let fadeOverlay = UIView()
    private let iconView = UIImageView()
    private let badgeLabel = MetricBadgeLabel()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()
    private let timeLabel = UILabel()
    private let fadeGradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor(hexString: "#FDFCFC")

        watermark.contentMode = .scaleAspectFill
        watermark.alpha = 1
        watermark.clipsToBounds = true

        fadeGradient.colors = [
            UIColor.white.withAlphaComponent(0.85).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor,
        ]
        fadeGradient.startPoint = CGPoint(x: 0.5, y: 0)
        fadeGradient.endPoint = CGPoint(x: 0.5, y: 1)
        fadeOverlay.layer.addSublayer(fadeGradient)
        fadeOverlay.isUserInteractionEnabled = false
        fadeOverlay.isHidden = true

        iconView.contentMode = .scaleAspectFit

        badgeLabel.font = .fdFont(ofSize: 12, weight: .medium)
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 11
        badgeLabel.clipsToBounds = true
        badgeLabel.contentInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

        titleLabel.font = .fdFont(ofSize: 12, weight: .regular)
        titleLabel.textColor = .fdSubtext

        valueLabel.font = .fdFont(ofSize: 20, weight: .medium)
        valueLabel.textColor = .fdText

        unitLabel.font = .fdFont(ofSize: 12, weight: .regular)
        unitLabel.textColor = .fdSubtext

        timeLabel.font = .fdFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = .fdText

        [watermark, fadeOverlay, iconView, badgeLabel, titleLabel, valueLabel, unitLabel, timeLabel].forEach(contentView.addSubview)

        watermark.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        fadeOverlay.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(118)
        }
        iconView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(12)
            $0.size.equalTo(22)
        }
        badgeLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(12)
            $0.trailing.equalToSuperview().inset(12)
            $0.height.equalTo(22)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12)
            $0.top.equalTo(iconView.snp.bottom).offset(10)
            $0.trailing.lessThanOrEqualToSuperview().inset(12)
        }
        valueLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12)
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
        unitLabel.snp.makeConstraints {
            $0.leading.equalTo(valueLabel.snp.trailing).offset(4)
            $0.lastBaseline.equalTo(valueLabel)
            $0.trailing.lessThanOrEqualToSuperview().inset(8)
        }
        timeLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12)
            $0.top.equalTo(valueLabel.snp.bottom).offset(10)
            $0.bottom.lessThanOrEqualToSuperview().inset(12)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        fadeGradient.frame = fadeOverlay.bounds
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
        time: String
    ) {
        let bg = Self.cardBgs[metricKey] ?? UIColor(hexString: "#FDFCFC")
        contentView.backgroundColor = bg
        applyBackground(backgroundUrl: backgroundUrl)
        watermark.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }

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

        titleLabel.text = label
        valueLabel.text = value
        unitLabel.text = unit
        unitLabel.isHidden = unit.isEmpty
        timeLabel.text = time
        timeLabel.isHidden = time.isEmpty
    }

    /// 背景图：从服务端下发 `backgroundUrl` 网络获取
    private func applyBackground(backgroundUrl: String?) {
        watermark.kf.cancelDownloadTask()
        let remote = backgroundUrl?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
            .flatMap { URL(string: $0) }

        if let remote {
            watermark.kf.setImage(
                with: remote,
                options: [.transition(.fade(0.15))]
            )
        } else {
            watermark.image = nil
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
    }
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

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
