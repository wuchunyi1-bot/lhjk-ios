import SnapKit
import UIKit

/// 体重报告顶部概要卡：背景图 `weight_ble_result_bg` + 体重 / 时间 / 身体年龄 / BMI / 体脂率
/// 对齐 Figma `5175:12559`
final class WeightScaleResultSummaryView: UIView {

    private static let verticalInset: CGFloat = 27
    private static let imageAspect: CGFloat = 199.0 / 343.0

    private let backgroundImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "weight_ble_result_bg"))
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = false
        return iv
    }()

    private let weightValueLabel = UILabel()
    private let currentLabel = UILabel()
    private let timeLabel = UILabel()
    private let bodyAgeValueLabel = UILabel()
    private let bodyAgeUnitLabel = UILabel()
    private let bmiValueLabel = UILabel()
    private let bodyFatValueLabel = UILabel()
    private let bodyFatUnitLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface
        layer.cornerRadius = 16
        clipsToBounds = true

        weightValueLabel.font = .fdFont(ofSize: 38, weight: .medium)
        weightValueLabel.textColor = .fdText
        weightValueLabel.textAlignment = .center
        weightValueLabel.adjustsFontSizeToFitWidth = true
        weightValueLabel.minimumScaleFactor = 0.6

        currentLabel.text = "当前(KG)"
        currentLabel.font = .fdFont(ofSize: 14, weight: .regular)
        currentLabel.textColor = .fdMuted
        currentLabel.textAlignment = .center

        timeLabel.font = .fdFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = .fdMuted
        timeLabel.textAlignment = .center

        let weightStack = UIStackView(arrangedSubviews: [weightValueLabel, currentLabel, timeLabel])
        weightStack.axis = .vertical
        weightStack.alignment = .center
        weightStack.spacing = 0
        weightStack.setCustomSpacing(-4, after: weightValueLabel)

        let leftDivider = makeDivider()
        let rightDivider = makeDivider()
        let bottomRow = UIStackView(arrangedSubviews: [
            makeBodyAgeColumn(),
            makeSimpleColumn(valueLabel: bmiValueLabel, title: "BMI"),
            makeBodyFatColumn(),
        ])
        bottomRow.axis = .horizontal
        bottomRow.alignment = .center
        bottomRow.distribution = .fillEqually
        bottomRow.spacing = 0

        addSubview(backgroundImageView)
        addSubview(weightStack)
        addSubview(bottomRow)
        addSubview(leftDivider)
        addSubview(rightDivider)

        backgroundImageView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(Self.verticalInset)
            make.bottom.equalToSuperview().offset(-Self.verticalInset)
            make.height.equalTo(backgroundImageView.snp.width).multipliedBy(Self.imageAspect)
        }
        weightStack.snp.makeConstraints { make in
            make.centerX.equalTo(backgroundImageView)
            make.top.equalTo(backgroundImageView).offset(48)
            make.width.lessThanOrEqualTo(backgroundImageView).offset(-32)
        }
        bottomRow.snp.makeConstraints { make in
            make.leading.trailing.equalTo(backgroundImageView)
            make.bottom.equalTo(backgroundImageView).offset(-8)
            make.height.equalTo(52)
        }
        leftDivider.snp.makeConstraints { make in
            make.centerY.equalTo(bottomRow)
            make.centerX.equalTo(backgroundImageView).multipliedBy(2.0 / 3.0)
        }
        rightDivider.snp.makeConstraints { make in
            make.centerY.equalTo(bottomRow)
            make.centerX.equalTo(backgroundImageView).multipliedBy(4.0 / 3.0)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(weight: String, time: String, bodyAge: String, bmi: String, bodyFat: String) {
        weightValueLabel.text = weight
        timeLabel.text = time
        bodyAgeValueLabel.text = bodyAge
        bmiValueLabel.text = bmi
        bodyFatValueLabel.text = bodyFat
    }

    private func makeBodyAgeColumn() -> UIView {
        bodyAgeValueLabel.font = .fdFont(ofSize: 18, weight: .medium)
        bodyAgeValueLabel.textColor = .fdText
        bodyAgeValueLabel.textAlignment = .center

        bodyAgeUnitLabel.text = "岁"
        bodyAgeUnitLabel.font = .fdFont(ofSize: 16, weight: .regular)
        bodyAgeUnitLabel.textColor = .fdText

        let valueRow = UIStackView(arrangedSubviews: [bodyAgeValueLabel, bodyAgeUnitLabel])
        valueRow.axis = .horizontal
        valueRow.alignment = .lastBaseline
        valueRow.spacing = 2

        return wrapColumn(valueRow, title: "身体年龄")
    }

    private func makeBodyFatColumn() -> UIView {
        bodyFatValueLabel.font = .fdFont(ofSize: 18, weight: .medium)
        bodyFatValueLabel.textColor = .fdText
        bodyFatValueLabel.textAlignment = .center

        bodyFatUnitLabel.text = "%"
        bodyFatUnitLabel.font = .fdFont(ofSize: 16, weight: .regular)
        bodyFatUnitLabel.textColor = .fdText

        let valueRow = UIStackView(arrangedSubviews: [bodyFatValueLabel, bodyFatUnitLabel])
        valueRow.axis = .horizontal
        valueRow.alignment = .lastBaseline
        valueRow.spacing = 2

        return wrapColumn(valueRow, title: "体脂率")
    }

    private func makeSimpleColumn(valueLabel: UILabel, title: String) -> UIView {
        valueLabel.font = .fdFont(ofSize: 18, weight: .medium)
        valueLabel.textColor = .fdText
        valueLabel.textAlignment = .center
        return wrapColumn(valueLabel, title: title)
    }

    private func wrapColumn(_ valueView: UIView, title: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .fdFont(ofSize: 12, weight: .regular)
        titleLabel.textColor = .fdSubtext
        titleLabel.textAlignment = .center

        let column = UIStackView(arrangedSubviews: [valueView, titleLabel])
        column.axis = .vertical
        column.alignment = .center
        column.spacing = 2
        column.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return column
    }

    private func makeDivider() -> UIView {
        let line = UIView()
        line.backgroundColor = UIColor.fdBorder
        line.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(42)
        }
        return line
    }
}
