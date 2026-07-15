import UIKit
import SnapKit

/// 体重服务首页表头 — 圆环 + 读数 + BMI
final class WeightServiceHeadCell: UITableViewCell {

    static let reuseID = "WeightServiceHeadCell"

    private let card = UIView()
    private let gaugeView = BloodPressureGaugeView()
    private let weightLabel = UILabel()
    private let unitLabel = UILabel()
    private let bmiLabel = UILabel()
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

        weightLabel.font = .fdNumXL
        weightLabel.textColor = .fdText
        unitLabel.font = .fdCaption
        unitLabel.textColor = .fdSubtext
        unitLabel.text = "kg"
        bmiLabel.font = .fdCaption
        bmiLabel.textColor = .fdSubtext
        stateLabel.font = .fdCaptionSemibold
        dateLabel.font = .fdMicro
        dateLabel.textColor = .fdMuted

        [weightLabel, unitLabel, bmiLabel, stateLabel, dateLabel].forEach(card.addSubview)

        weightLabel.snp.makeConstraints { make in
            make.centerX.equalTo(gaugeView).offset(-10)
            make.centerY.equalTo(gaugeView)
        }
        unitLabel.snp.makeConstraints { make in
            make.leading.equalTo(weightLabel.snp.trailing).offset(4)
            make.bottom.equalTo(weightLabel).offset(-4)
        }
        bmiLabel.snp.makeConstraints { make in
            make.top.equalTo(gaugeView.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }
        stateLabel.snp.makeConstraints { make in
            make.top.equalTo(bmiLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(stateLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(record: WeightRecord?, stateText: String, dateText: String) {
        if let record, record.weightDisplay != "--", let value = Double(record.weightDisplay) {
            weightLabel.text = record.weightDisplay
            bmiLabel.text = "BMI \(record.bmiDisplay)"
            gaugeView.setProgress(min(value / 200 * 100, 100))
        } else {
            weightLabel.text = "--"
            bmiLabel.text = "BMI --"
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
