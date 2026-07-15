import UIKit
import SnapKit

/// 三列指标展示 — 对齐源项目 `ADCustomTBView`
final class BloodPressureMetricColumnView: UIView {

    private let titleLabel = UILabel()
    private let descLabel = UILabel()
    private let unitLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .fdNumL
        titleLabel.textColor = .fdText
        titleLabel.textAlignment = .center

        descLabel.font = .fdCaption
        descLabel.textColor = .fdSubtext
        descLabel.textAlignment = .center

        unitLabel.font = .fdMicro
        unitLabel.textColor = .fdMuted
        unitLabel.textAlignment = .center

        addSubview(titleLabel)
        addSubview(descLabel)
        addSubview(unitLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview()
        }
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
        }
        unitLabel.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, description: String, unit: String) {
        titleLabel.text = title
        descLabel.text = description
        unitLabel.text = unit
    }
}
