import UIKit
import SnapKit

/// 热量摘要头 — 对齐源 `ADFootRecordHeadView`
final class ExerciseFoodCalorieHeaderView: UIView {

    private let card = UIView()
    private let gaugeView = BloodPressureGaugeView()
    private let centerTitleLabel = UILabel()
    private let centerValueLabel = UILabel()
    private let centerUnitLabel = UILabel()
    private let hintLabel = UILabel()
    private let intakeTitleLabel = UILabel()
    private let intakeValueLabel = UILabel()
    private let sportTitleLabel = UILabel()
    private let sportValueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        card.backgroundColor = UIColor(hexString: "#FF7A50")
        card.layer.cornerRadius = 20
        addSubview(card)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 12, right: 16))
            make.height.equalTo(200)
        }

        gaugeView.setProgress(0)
        card.addSubview(gaugeView)
        gaugeView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.size.equalTo(160)
        }

        centerTitleLabel.font = .fdCaptionSemibold
        centerTitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        centerTitleLabel.textAlignment = .center
        centerValueLabel.font = .fdNumXL
        centerValueLabel.textColor = .white
        centerValueLabel.textAlignment = .center
        centerUnitLabel.font = .fdCaption
        centerUnitLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        centerUnitLabel.text = "kcal"
        centerUnitLabel.textAlignment = .center
        hintLabel.font = .fdMicro
        hintLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 2

        intakeTitleLabel.font = .fdCaption
        intakeTitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        intakeTitleLabel.text = "食物摄入"
        intakeValueLabel.font = .fdNumL
        intakeValueLabel.textColor = .white
        sportTitleLabel.font = .fdCaption
        sportTitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        sportTitleLabel.text = "运动消耗"
        sportValueLabel.font = .fdNumL
        sportValueLabel.textColor = .white

        [centerTitleLabel, centerValueLabel, centerUnitLabel, hintLabel,
         intakeTitleLabel, intakeValueLabel, sportTitleLabel, sportValueLabel].forEach(card.addSubview)

        centerTitleLabel.snp.makeConstraints { make in
            make.centerX.equalTo(gaugeView)
            make.top.equalTo(gaugeView).offset(24)
        }
        centerValueLabel.snp.makeConstraints { make in
            make.centerX.equalTo(gaugeView)
            make.top.equalTo(centerTitleLabel.snp.bottom).offset(4)
        }
        centerUnitLabel.snp.makeConstraints { make in
            make.centerX.equalTo(gaugeView)
            make.top.equalTo(centerValueLabel.snp.bottom)
        }
        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(centerUnitLabel.snp.bottom).offset(6)
            make.leading.trailing.equalTo(gaugeView).inset(8)
        }

        intakeTitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-20)
        }
        intakeValueLabel.snp.makeConstraints { make in
            make.leading.equalTo(intakeTitleLabel)
            make.bottom.equalTo(intakeTitleLabel.snp.top).offset(-4)
        }
        sportTitleLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(intakeTitleLabel)
        }
        sportValueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(sportTitleLabel)
            make.bottom.equalTo(sportTitleLabel.snp.top).offset(-4)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(summary: ExerciseFoodDaySummary?) {
        let remaining = Double(summary?.remainingIntake?.value ?? "") ?? 0
        centerTitleLabel.text = ExerciseFoodCalorieCenter.title(
            recommendCalories: summary?.recommendCalories,
            remaining: remaining
        )
        centerValueLabel.text = ExerciseFoodCalorieCenter.valueText(remainingRaw: summary?.remainingIntake?.value)
        hintLabel.text = summary?.recommendCalories
        intakeValueLabel.text = summary?.intake?.value ?? "--"
        sportValueLabel.text = summary?.sport?.consumeNum?.value ?? "--"

        let intake = Double(summary?.intake?.value ?? "") ?? 0
        let maxValue = max(intake + max(remaining, 0), 1)
        gaugeView.setProgress(min(intake / maxValue * 100, 100))
    }
}
