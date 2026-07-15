import UIKit
import SnapKit

/// 服务首页表头 — 圆环 + 读数
final class BloodPressureServiceHeadCell: UITableViewCell {

    static let reuseID = "BloodPressureServiceHeadCell"

    private let card = UIView()
    private let gaugeView = BloodPressureGaugeView()
    private let pressureLabel = UILabel()
    private let heartLabel = UILabel()
    private let stateLabel = UILabel()
    private let dateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
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

        pressureLabel.font = .fdNumXL
        pressureLabel.textColor = .fdText
        pressureLabel.textAlignment = .center

        heartLabel.font = .fdCaption
        heartLabel.textColor = .fdSubtext
        heartLabel.textAlignment = .center

        stateLabel.font = .fdCaptionSemibold
        stateLabel.textColor = .fdSuccess
        stateLabel.textAlignment = .center

        dateLabel.font = .fdMicro
        dateLabel.textColor = .fdMuted
        dateLabel.textAlignment = .center

        card.addSubview(pressureLabel)
        card.addSubview(heartLabel)
        card.addSubview(stateLabel)
        card.addSubview(dateLabel)

        pressureLabel.snp.makeConstraints { make in
            make.center.equalTo(gaugeView)
        }
        heartLabel.snp.makeConstraints { make in
            make.top.equalTo(gaugeView.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }
        stateLabel.snp.makeConstraints { make in
            make.top.equalTo(heartLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(stateLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(record: BloodPressureRecord?, stateText: String, dateText: String) {
        if let record, record.systolicDisplay != "--" {
            pressureLabel.text = record.pressureDisplay
            heartLabel.text = "心率\(record.heartRateDisplay)/分"
            gaugeView.setProgress(100)
        } else {
            pressureLabel.text = "--/--"
            heartLabel.text = "心率--"
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
