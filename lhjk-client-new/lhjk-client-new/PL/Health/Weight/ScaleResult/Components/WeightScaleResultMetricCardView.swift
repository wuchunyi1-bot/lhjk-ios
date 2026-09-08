import SnapKit
import UIKit

/// 体重报告「我的指标」单卡 — 对齐 Figma `5184:12640`
final class WeightScaleResultMetricCardView: UIView {

    static let preferredHeight: CGFloat = 80

    private let nameLabel = UILabel()
    private let tagLabel = PaddingLabel()
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface
        layer.cornerRadius = 12
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.3).cgColor
        clipsToBounds = true

        nameLabel.font = .fdFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 1
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        tagLabel.font = .fdFont(ofSize: 14, weight: .medium)
        tagLabel.textAlignment = .center
        tagLabel.layer.cornerRadius = 10
        tagLabel.clipsToBounds = true
        tagLabel.contentInsets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)
        tagLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        valueLabel.font = .fdFont(ofSize: 18, weight: .medium)
        valueLabel.textColor = .fdText

        unitLabel.font = .fdFont(ofSize: 16, weight: .regular)
        unitLabel.textColor = .fdSubtext

        addSubview(nameLabel)
        addSubview(tagLabel)
        addSubview(valueLabel)
        addSubview(unitLabel)

        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.lessThanOrEqualTo(tagLabel.snp.leading).offset(-6)
        }
        tagLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-8)
            make.height.greaterThanOrEqualTo(20)
        }
        valueLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
        unitLabel.snp.makeConstraints { make in
            make.leading.equalTo(valueLabel.snp.trailing).offset(2)
            make.lastBaseline.equalTo(valueLabel)
            make.trailing.lessThanOrEqualToSuperview().offset(-12)
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Self.preferredHeight)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ item: WeightBodyCompositionItemVO) {
        nameLabel.text = item.name
        let unit = item.unit?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        unitLabel.text = unit
        unitLabel.isHidden = unit.isEmpty
        valueLabel.text = WeightScaleResultViewModel.formatNumber(item.value)

        let status = item.monitorResults?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        tagLabel.isHidden = status.isEmpty
        tagLabel.text = status
        let style = Self.tagStyle(status: status, colorHex: item.color)
        tagLabel.textColor = style.foreground
        tagLabel.backgroundColor = style.background
    }

    private static func tagStyle(status: String, colorHex: String?) -> (foreground: UIColor, background: UIColor) {
        if let hex = colorHex?.trimmingCharacters(in: .whitespacesAndNewlines),
           hex.hasPrefix("#"), hex.count >= 7 {
            let color = UIColor(hexString: hex)
            return (color, color.withAlphaComponent(0.12))
        }
        switch status {
        case "优", "标准", "理想":
            return (.fdSuccess, .fdSuccessSoft)
        case "偏高", "肥胖", "超标", "需改善":
            return (.fdDanger, .fdDangerSoft)
        default:
            return (.fdPrimary, .fdPrimarySoft)
        }
    }
}

private final class PaddingLabel: UILabel {
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
