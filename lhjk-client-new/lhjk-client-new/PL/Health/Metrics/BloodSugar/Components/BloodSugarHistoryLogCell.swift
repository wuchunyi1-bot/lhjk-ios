import UIKit
import SnapKit

final class BloodSugarHistoryLogCell: UITableViewCell {

    static let reuseID = "BloodSugarHistoryLogCell"

    private let card = UIView()
    private let timeLabel = UILabel()
    private let mealLabel = UILabel()
    private let valueLabel = UILabel()
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
        mealLabel.font = .fdCaption
        mealLabel.textColor = .fdText2
        valueLabel.font = .fdNumL
        valueLabel.textColor = .fdText
        statusBadge.font = .fdMicroSemibold
        statusBadge.textColor = .white
        statusBadge.textAlignment = .center
        statusBadge.layer.cornerRadius = 10
        statusBadge.clipsToBounds = true
        sourceLabel.font = .fdMicro
        sourceLabel.textColor = .fdMuted

        [timeLabel, mealLabel, valueLabel, statusBadge, sourceLabel].forEach(card.addSubview)

        timeLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(14)
        }
        statusBadge.snp.makeConstraints { make in
            make.centerY.equalTo(timeLabel)
            make.trailing.equalToSuperview().offset(-14)
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(44)
        }
        mealLabel.snp.makeConstraints { make in
            make.leading.equalTo(timeLabel)
            make.top.equalTo(timeLabel.snp.bottom).offset(6)
        }
        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(timeLabel)
            make.top.equalTo(mealLabel.snp.bottom).offset(8)
        }
        sourceLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.bottom.equalToSuperview().offset(-14)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(item: BloodSugarLogItem) {
        timeLabel.text = item.timeDisplay
        mealLabel.text = item.typeRemark
        valueLabel.text = item.valueDisplay
        sourceLabel.text = item.dataSource
        statusBadge.text = "  \(item.result ?? "")  "
        if let hex = item.color {
            statusBadge.backgroundColor = UIColor(hexString: hex)
        } else {
            statusBadge.backgroundColor = .fdSuccess
        }
    }
}
