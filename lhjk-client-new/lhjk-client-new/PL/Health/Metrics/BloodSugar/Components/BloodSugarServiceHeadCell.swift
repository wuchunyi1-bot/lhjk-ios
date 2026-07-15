import UIKit
import SnapKit

final class BloodSugarServiceHeadCell: UITableViewCell {

    static let reuseID = "BloodSugarServiceHeadCell"

    private let card = UIView()
    private let gaugeView = BloodPressureGaugeView()
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()
    private let mealLabel = UILabel()
    private let stateLabel = UILabel()
    private let dateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 12, right: 16))
            make.height.equalTo(260)
        }

        card.addSubview(gaugeView)
        gaugeView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
            make.size.equalTo(200)
        }

        valueLabel.font = .fdNumXL
        valueLabel.textColor = .fdText
        unitLabel.font = .fdCaption
        unitLabel.textColor = .fdSubtext
        unitLabel.text = "mmol/L"
        mealLabel.font = .fdCaption
        mealLabel.textColor = .fdSubtext
        stateLabel.font = .fdCaptionSemibold
        dateLabel.font = .fdMicro
        dateLabel.textColor = .fdMuted

        [valueLabel, unitLabel, mealLabel, stateLabel, dateLabel].forEach(card.addSubview)

        valueLabel.snp.makeConstraints { make in
            make.centerX.equalTo(gaugeView).offset(-12)
            make.centerY.equalTo(gaugeView)
        }
        unitLabel.snp.makeConstraints { make in
            make.leading.equalTo(valueLabel.snp.trailing).offset(4)
            make.bottom.equalTo(valueLabel).offset(-4)
        }
        mealLabel.snp.makeConstraints { make in
            make.top.equalTo(gaugeView.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }
        stateLabel.snp.makeConstraints { make in
            make.top.equalTo(mealLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(stateLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(record: BloodSugarRecord?, stateText: String, dateText: String) {
        if let record, record.valueDisplay != "--", let value = Double(record.valueDisplay) {
            valueLabel.text = record.valueDisplay
            mealLabel.text = record.typeRemark
            gaugeView.setProgress(min(value / 15 * 100, 100))
        } else {
            valueLabel.text = "--"
            mealLabel.text = nil
            gaugeView.setProgress(0)
        }
        stateLabel.text = stateText
        dateLabel.text = dateText.isEmpty ? "------" : dateText
        if let colorHex = record?.color {
            stateLabel.textColor = UIColor(hexString: colorHex)
        } else {
            stateLabel.textColor = .fdSuccess
        }
    }
}
