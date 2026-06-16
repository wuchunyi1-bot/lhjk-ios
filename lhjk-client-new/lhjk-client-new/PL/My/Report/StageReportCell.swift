import UIKit
import SnapKit

/// 阶段小结卡片 Cell — 支持 UITableView 复用，条件渲染 metrics grid
/// 参考 funde-client: report-card + metrics-grid
final class StageReportCell: UITableViewCell {

    static let reuseIdentifier = "StageReportCell"

    // MARK: - UI Elements

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let tagLabel = UILabel()
    private let tagContainer = UIView()
    private let summaryLabel = UILabel()
    private let metricsCardView = StageMetricsCardView()
    private let detailButton = UIButton(type: .system)

    /// 指向 summaryLabel 底部或 metricsCardView 底部的动态约束
    private var buttonTopConstraint: Constraint?

    var onDetailTap: (() -> Void)?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupCard()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupCard() {
        // Card
        cardView.backgroundColor = .fdSurface
        cardView.layer.cornerRadius = 24
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 1)
        cardView.layer.shadowRadius = 6
        cardView.layer.shadowOpacity = 0.03
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)) }

        // Tag
        tagContainer.backgroundColor = .fdPrimarySoft
        tagContainer.layer.cornerRadius = 999
        tagLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        tagLabel.textColor = .fdPrimary
        tagContainer.addSubview(tagLabel)
        tagLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }

        // Title
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .fdText

        // Date
        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = .fdSubtext

        // Summary
        summaryLabel.font = .systemFont(ofSize: 14)
        summaryLabel.textColor = .fdText2
        summaryLabel.numberOfLines = 0

        // Metrics card (hidden by default, shown when metrics exist)
        metricsCardView.isHidden = true

        // Button
        detailButton.setTitle("查看报告详情", for: .normal)
        detailButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        detailButton.setTitleColor(.fdPrimary, for: .normal)
        detailButton.backgroundColor = .fdPrimarySoft
        detailButton.layer.cornerRadius = 12
        detailButton.addTarget(self, action: #selector(didTapDetail), for: .touchUpInside)

        cardView.addSubview(titleLabel)
        cardView.addSubview(tagContainer)
        cardView.addSubview(dateLabel)
        cardView.addSubview(summaryLabel)
        cardView.addSubview(metricsCardView)
        cardView.addSubview(detailButton)

        // Fixed constraints
        tagContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(tagContainer.snp.leading).offset(-12)
        }
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        summaryLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        metricsCardView.snp.makeConstraints { make in
            make.top.equalTo(summaryLabel.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        detailButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    // MARK: - Configure

    func configure(title: String, date: String, tag: String, summary: String, metrics: [StageMetric]?) {
        titleLabel.text = title
        dateLabel.text = date
        tagLabel.text = tag
        summaryLabel.text = summary

        if let metrics = metrics, !metrics.isEmpty {
            metricsCardView.isHidden = false
            metricsCardView.configure(metrics: metrics)

            // Button below metrics card
            detailButton.snp.remakeConstraints { make in
                make.top.equalTo(metricsCardView.snp.bottom).offset(14)
                make.leading.trailing.equalToSuperview().inset(16)
                make.height.equalTo(40)
                make.bottom.equalToSuperview().offset(-16)
            }
        } else {
            metricsCardView.isHidden = true

            // Button directly below summary
            detailButton.snp.remakeConstraints { make in
                make.top.equalTo(summaryLabel.snp.bottom).offset(14)
                make.leading.trailing.equalToSuperview().inset(16)
                make.height.equalTo(40)
                make.bottom.equalToSuperview().offset(-16)
            }
        }
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        dateLabel.text = nil
        tagLabel.text = nil
        summaryLabel.text = nil
        // Clean up metrics grid to avoid stale data leaking into next cell
        metricsCardView.isHidden = true
        metricsCardView.subviews.forEach { $0.removeFromSuperview() }
        onDetailTap = nil
    }

    @objc private func didTapDetail() {
        onDetailTap?()
    }
}
