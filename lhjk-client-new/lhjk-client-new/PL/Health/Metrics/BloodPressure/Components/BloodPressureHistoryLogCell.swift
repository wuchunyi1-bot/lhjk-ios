import UIKit
import SnapKit

/// 历史日志行
final class BloodPressureHistoryLogCell: UITableViewCell {

    static let reuseID = "BloodPressureHistoryLogCell"

    private let card = UIView()
    private let timeLabel = UILabel()
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()
    private let heartLabel = UILabel()
    private let statusBadge = UILabel()
    private let sourceLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 10, right: 16))
            make.height.equalTo(110)
        }

        timeLabel.font = .fdCaption
        timeLabel.textColor = .fdSubtext

        valueLabel.font = .fdNumL
        valueLabel.textColor = .fdText

        unitLabel.font = .fdMicro
        unitLabel.textColor = .fdMuted
        unitLabel.text = "mmHg"

        heartLabel.font = .fdCaption
        heartLabel.textColor = .fdText2

        statusBadge.font = .fdMicroSemibold
        statusBadge.textColor = .white
        statusBadge.textAlignment = .center
        statusBadge.layer.cornerRadius = 10
        statusBadge.clipsToBounds = true

        sourceLabel.font = .fdMicro
        sourceLabel.textColor = .fdMuted

        [timeLabel, valueLabel, unitLabel, heartLabel, statusBadge, sourceLabel].forEach(card.addSubview)

        timeLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(14)
        }
        statusBadge.snp.makeConstraints { make in
            make.centerY.equalTo(timeLabel)
            make.trailing.equalToSuperview().offset(-14)
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(44)
        }
        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(timeLabel)
            make.top.equalTo(timeLabel.snp.bottom).offset(12)
        }
        unitLabel.snp.makeConstraints { make in
            make.leading.equalTo(valueLabel.snp.trailing).offset(4)
            make.bottom.equalTo(valueLabel).offset(-2)
        }
        heartLabel.snp.makeConstraints { make in
            make.leading.equalTo(timeLabel)
            make.top.equalTo(valueLabel.snp.bottom).offset(6)
        }
        sourceLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.bottom.equalToSuperview().offset(-14)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(item: BloodPressureLogItem) {
        timeLabel.text = item.timeDisplay
        valueLabel.text = item.pressureDisplay
        heartLabel.text = item.heartRateDisplay
        sourceLabel.text = item.dataSource
        statusBadge.text = "  \(item.monitorResults ?? "")  "
        if let hex = item.color {
            statusBadge.backgroundColor = UIColor(hexString: hex)
        } else {
            statusBadge.backgroundColor = .fdSuccess
        }
    }
}
