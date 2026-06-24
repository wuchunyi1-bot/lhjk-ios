import UIKit
import SnapKit

/// 量化改善指标 2×2 grid — 阶段小结中展示 before → after 对比
/// 参考 funde-client: metrics-grid + metric-delta
final class StageMetricsCardView: UIView {

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hexString: "#FAF8F6")
        layer.cornerRadius = 12
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(metrics: [StageMetric]) {
        subviews.forEach { $0.removeFromSuperview() }

        let outerStack = UIStackView()
        outerStack.axis = .vertical
        outerStack.spacing = 8
        addSubview(outerStack)
        outerStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }

        // Layout metrics in 2×N grid
        let rowCount = (metrics.count + 1) / 2
        for rowIndex in 0..<rowCount {
            let row = UIStackView()
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 8

            for colIndex in 0..<2 {
                let idx = rowIndex * 2 + colIndex
                if idx < metrics.count {
                    row.addArrangedSubview(buildDeltaItem(metrics[idx]))
                } else {
                    // Placeholder for odd count
                    row.addArrangedSubview(UIView())
                }
            }
            outerStack.addArrangedSubview(row)
        }
    }

    private func buildDeltaItem(_ metric: StageMetric) -> UIView {
        let container = UIView()

        // Label
        let label = UILabel()
        label.text = metric.label
        label.font = .fdMicro
        label.textColor = .fdSubtext
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        // Before → After row
        let deltaRow = UIStackView()
        deltaRow.axis = .horizontal
        deltaRow.spacing = 5
        deltaRow.alignment = .firstBaseline

        let beforeLabel = UILabel()
        beforeLabel.text = metric.before
        beforeLabel.font = .fdCaption
        beforeLabel.textColor = UIColor(hexString: "#BBBBBB")
        deltaRow.addArrangedSubview(beforeLabel)

        let arrowLabel = UILabel()
        arrowLabel.text = "→"
        arrowLabel.font = .fdCaption
        arrowLabel.textColor = UIColor(hexString: "#CCCCCC")
        deltaRow.addArrangedSubview(arrowLabel)

        let afterLabel = UILabel()
        let afterText = metric.unit.isEmpty ? metric.after : "\(metric.after)\(metric.unit)"
        afterLabel.text = afterText
        afterLabel.font = .fdBodyBold
        afterLabel.textColor = metric.isGood ? UIColor(hexString: "#1F9A6B") : .fdText
        deltaRow.addArrangedSubview(afterLabel)

        container.addSubview(deltaRow)
        deltaRow.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(5)
            make.leading.trailing.bottom.equalToSuperview()
        }

        return container
    }
}

// MARK: - Data Model

/// 量化改善指标（阶段小结用）
struct StageMetric {
    let label: String       // "血压达标率"
    let before: String      // "52%"
    let after: String       // "85%"
    let unit: String        // "" / "分"
    let isGood: Bool        // true → after 文字色为绿色
}
