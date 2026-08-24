import SnapKit
import UIKit

/// 体重报告顶部概要卡：体重 + 时间 + 身体年龄 / BMI / 体脂率
final class WeightScaleResultSummaryView: UIView {

    private let weightValueLabel = UILabel()
    private let weightUnitLabel = UILabel()
    private let timeLabel = UILabel()
    private let bodyAgeValueLabel = UILabel()
    private let bmiValueLabel = UILabel()
    private let bodyFatValueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface
        layer.cornerRadius = 16

        weightValueLabel.font = .fdNumL
        weightValueLabel.textColor = .fdText
        weightValueLabel.textAlignment = .center

        weightUnitLabel.text = "kg"
        weightUnitLabel.font = .fdH3
        weightUnitLabel.textColor = .fdSubtext

        timeLabel.font = .fdCaption
        timeLabel.textColor = .fdMuted
        timeLabel.textAlignment = .center

        let weightRow = UIStackView(arrangedSubviews: [weightValueLabel, weightUnitLabel])
        weightRow.axis = .horizontal
        weightRow.alignment = .lastBaseline
        weightRow.spacing = 4

        let subs = UIStackView(arrangedSubviews: [
            makeSubColumn(valueLabel: bodyAgeValueLabel, unit: "岁", title: "身体年龄"),
            makeSubColumn(valueLabel: bmiValueLabel, unit: nil, title: "BMI"),
            makeSubColumn(valueLabel: bodyFatValueLabel, unit: "%", title: "体脂率"),
        ])
        subs.axis = .horizontal
        subs.distribution = .fillEqually
        subs.alignment = .top

        addSubview(weightRow)
        addSubview(timeLabel)
        addSubview(subs)

        weightRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
        }
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(weightRow.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        subs.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().offset(-16)
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

    private func makeSubColumn(valueLabel: UILabel, unit: String?, title: String) -> UIView {
        valueLabel.font = .fdH2
        valueLabel.textColor = .fdText
        valueLabel.textAlignment = .center

        let unitLabel = UILabel()
        unitLabel.text = unit
        unitLabel.font = .fdCaption
        unitLabel.textColor = .fdSubtext
        unitLabel.isHidden = unit == nil

        let valueRow = UIStackView(arrangedSubviews: [valueLabel, unitLabel])
        valueRow.axis = .horizontal
        valueRow.alignment = .lastBaseline
        valueRow.spacing = 2
        valueRow.distribution = .fill

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .fdCaption
        titleLabel.textColor = .fdMuted
        titleLabel.textAlignment = .center

        let column = UIStackView(arrangedSubviews: [valueRow, titleLabel])
        column.axis = .vertical
        column.alignment = .center
        column.spacing = 4
        return column
    }
}
