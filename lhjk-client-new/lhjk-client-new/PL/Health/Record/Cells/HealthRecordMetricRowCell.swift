import UIKit
import SnapKit

/// 体征监测数据行 Cell — 内嵌 vertical UIStackView，每行一条数据
/// 参考 funde-client: hp-metric-row
final class HealthRecordMetricRowCell: UITableViewCell {

    static let reuseIdentifier = "HealthRecordMetricRowCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(metrics: [MetricRowItem]) {
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let stack = UIStackView()
        stack.axis = .vertical
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)) }

        for (index, metric) in metrics.enumerated() {
            let row = buildRow(metric)
            stack.addArrangedSubview(row)

            // Add divider except for last item
            if index < metrics.count - 1 {
                let divider = UIView()
                divider.backgroundColor = .fdBorder
                stack.addArrangedSubview(divider)
                divider.snp.makeConstraints { $0.height.equalTo(1) }
            }
        }
    }

    private func buildRow(_ metric: MetricRowItem) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        row.isLayoutMarginsRelativeArrangement = true

        // Label
        let label = UILabel()
        label.text = metric.label
        label.font = .fdBody
        label.textColor = .fdText
        row.addArrangedSubview(label)

        // Time (flex fill)
        let timeLabel = UILabel()
        timeLabel.text = metric.time
        timeLabel.font = .fdMicro
        timeLabel.textColor = .fdMuted
        timeLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(timeLabel)

        // Status badge
        let badge = buildBadge(status: metric.status, type: metric.statusType)
        row.addArrangedSubview(badge)

        // Value + Unit
        let valueLabel = UILabel()
        valueLabel.font = .fdMonoFont(ofSize: 16, weight: .bold)
        valueLabel.textColor = .fdText
        valueLabel.text = metric.value
        row.addArrangedSubview(valueLabel)

        if !metric.unit.isEmpty {
            let unitLabel = UILabel()
            unitLabel.text = metric.unit
            unitLabel.font = .fdMicro
            unitLabel.textColor = .fdSubtext
            row.addArrangedSubview(unitLabel)
        }

        return row
    }

    private func buildBadge(status: String, type: MetricStatusType) -> UIView {
        let container = UIView()
        let label = UILabel()
        label.text = status
        label.font = .fdMicroSemibold
        label.textAlignment = .center

        switch type {
        case .normal:
            container.backgroundColor = .fdSuccessSoft
            label.textColor = .fdSuccess
        case .warning:
            container.backgroundColor = .fdWarningSoft
            label.textColor = UIColor(hexString: "#B47300")
        }

        container.layer.cornerRadius = 4
        container.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }

        return container
    }
}
