import UIKit
import SnapKit

/// 健康档案完整度 — 对齐 Figma 3543:3528
final class HealthArchiveCardCell: UITableViewCell {

    static let reuseIdentifier = "HealthArchiveCardCell"
    var onCompleteTap: (() -> Void)?

    private let card = UIView()
    private let titleLbl = UILabel()
    private let missLabel = UILabel()
    private let progressTrackBg = UIView()
    private let barBg = UIView()
    private let progressFill = UIView()
    private let pctLabel = UILabel()
    private let pctUnit = UILabel()
    private let footerLbl = UILabel()
    private let completeBtn = UIButton(type: .system)
    private let illustView = UIImageView()
    private var fillWidthConstraint: Constraint?
    private var currentProgress = 72

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupViews() {
        backgroundColor = .clear
        contentView.clipsToBounds = true
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        contentView.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(155)
        }

        titleLbl.font = .fdFont(ofSize: 18, weight: .medium)
        titleLbl.textColor = .fdText
        titleLbl.text = "健康档案完整度"

        missLabel.font = .fdFont(ofSize: 14, weight: .regular)
        missLabel.textColor = .fdTabInactive
        missLabel.numberOfLines = 1
        missLabel.lineBreakMode = .byClipping
        missLabel.text = "一份完整的健康档案，是做好自我健康管理的基础。"

        progressTrackBg.backgroundColor = UIColor(hexString: "#FDF6F3")
        progressTrackBg.layer.cornerRadius = 12

        barBg.backgroundColor = .white
        barBg.layer.cornerRadius = 3
        progressFill.backgroundColor = .fdPrimary
        progressFill.layer.cornerRadius = 3
        progressTrackBg.addSubview(barBg)
        progressTrackBg.addSubview(progressFill)
        progressTrackBg.addSubview(pctLabel)
        progressTrackBg.addSubview(pctUnit)

        pctLabel.font = .fdFont(ofSize: 20, weight: .medium)
        pctLabel.textColor = .fdPrimary
        pctUnit.font = .fdFont(ofSize: 14, weight: .medium)
        pctUnit.textColor = .fdPrimary
        pctUnit.text = "%"

        barBg.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(6)
            $0.trailing.equalTo(pctLabel.snp.leading).offset(-10)
        }
        progressFill.snp.makeConstraints { make in
            make.leading.top.bottom.equalTo(barBg)
            fillWidthConstraint = make.width.equalTo(0).constraint
        }
        pctUnit.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(10)
            $0.bottom.equalTo(pctLabel).offset(-2)
        }
        pctLabel.snp.makeConstraints {
            $0.trailing.equalTo(pctUnit.snp.leading)
            $0.centerY.equalToSuperview()
        }

        footerLbl.font = .fdFont(ofSize: 12, weight: .regular)
        footerLbl.textColor = UIColor(hexString: "#717885")
        footerLbl.numberOfLines = 2
        footerLbl.text = "补齐基础健康信息，获得个性化健康建议"

        completeBtn.setTitle("立即完善", for: .normal)
        completeBtn.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        completeBtn.setTitleColor(.white, for: .normal)
        completeBtn.backgroundColor = .fdPrimary
        completeBtn.layer.cornerRadius = 14
        completeBtn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        completeBtn.addTarget(self, action: #selector(didTapComplete), for: .touchUpInside)

        illustView.image = UIImage(named: "health_archive_illust")
        illustView.contentMode = .scaleAspectFit
        illustView.clipsToBounds = false
        illustView.isUserInteractionEnabled = false

        // 插画沉底作为背景水印，文案在其上层展示
        card.addSubview(illustView)
        [titleLbl, missLabel, progressTrackBg, footerLbl, completeBtn].forEach(card.addSubview)
        card.bringSubviewToFront(missLabel)

        illustView.snp.makeConstraints {
            // Figma 3543:3535 (Group 1739333335) — 宽高 140×98，top: 4，右边距 8 (343 - 195 - 140 = 8)
            $0.trailing.equalToSuperview().inset(8)
            $0.top.equalToSuperview().offset(4)
            $0.width.equalTo(140)
            $0.height.equalTo(98)
        }
        titleLbl.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(12)
        }
        missLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalTo(titleLbl.snp.bottom).offset(4)
            $0.trailing.equalToSuperview().inset(12)
        }
        progressTrackBg.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().inset(12)
            $0.top.equalTo(missLabel.snp.bottom).offset(14)
            $0.height.equalTo(38)
        }
        footerLbl.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().inset(14)
            $0.trailing.lessThanOrEqualTo(completeBtn.snp.leading).offset(-8)
        }
        completeBtn.setContentCompressionResistancePriority(.required, for: .horizontal)
        completeBtn.setContentHuggingPriority(.required, for: .horizontal)
        completeBtn.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalTo(footerLbl)
            $0.height.equalTo(28)
        }
    }

    func configure(archiveProgress: Int) {
        currentProgress = archiveProgress
        pctLabel.text = "\(archiveProgress)"
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let barWidth = barBg.bounds.width
        guard barWidth > 0 else { return }
        fillWidthConstraint?.update(offset: barWidth * CGFloat(currentProgress) / 100.0)
    }

    @objc private func didTapComplete() { onCompleteTap?() }
}
