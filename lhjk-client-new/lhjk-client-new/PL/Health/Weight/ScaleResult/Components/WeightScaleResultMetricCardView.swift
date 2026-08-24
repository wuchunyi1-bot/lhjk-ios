import SnapKit
import UIKit

/// 体重报告「我的指标」单卡
final class WeightScaleResultMetricCardView: UIView {

    private let nameLabel = UILabel()
    private let tagLabel = UILabel()
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface
        layer.cornerRadius = 12

        nameLabel.font = .fdCaption
        nameLabel.textColor = .fdText2
        nameLabel.numberOfLines = 1

        tagLabel.font = .fdMicro
        tagLabel.textAlignment = .center
        tagLabel.layer.cornerRadius = 10
        tagLabel.clipsToBounds = true

        valueLabel.font = .fdH2
        valueLabel.textColor = .fdText

        unitLabel.font = .fdCaption
        unitLabel.textColor = .fdSubtext

        addSubview(nameLabel)
        addSubview(tagLabel)
        addSubview(valueLabel)
        addSubview(unitLabel)

        nameLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(12)
            make.trailing.lessThanOrEqualTo(tagLabel.snp.leading).offset(-6)
        }
        tagLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().inset(12)
            make.height.equalTo(20)
        }
        valueLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.top.equalTo(nameLabel.snp.bottom).offset(10)
            make.bottom.equalToSuperview().offset(-12)
        }
        unitLabel.snp.makeConstraints { make in
            make.leading.equalTo(valueLabel.snp.trailing).offset(4)
            make.lastBaseline.equalTo(valueLabel)
            make.trailing.lessThanOrEqualToSuperview().inset(12)
        }
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
        tagLabel.text = "  \(status)  "
        let style = Self.tagStyle(for: status)
        tagLabel.textColor = style.foreground
        tagLabel.backgroundColor = style.background
    }

    private static func tagStyle(for status: String) -> (foreground: UIColor, background: UIColor) {
        switch status {
        case "优", "标准", "理想":
            return (.fdSuccess, .fdSuccessSoft)
        case "肥胖", "超标", "需改善":
            return (.fdDanger, .fdDangerSoft)
        default:
            return (.fdWarning, .fdWarningSoft)
        }
    }
}
