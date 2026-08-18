import UIKit
import SnapKit

/// 健康档案完整度 — 对齐 Figma 3021:1352
final class HealthArchiveCardCell: UITableViewCell {

    static let reuseIdentifier = "HealthArchiveCardCell"
    var onCompleteTap: (() -> Void)?

    private let card = UIView()
    private let titleLbl = UILabel()
    private let missBadge = UILabel()
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

        titleLbl.font = .fdFont(ofSize: 16, weight: .medium)
        titleLbl.textColor = .fdText
        titleLbl.text = "健康档案完整度"

        missBadge.text = "缺"
        missBadge.font = .fdFont(ofSize: 10, weight: .medium)
        missBadge.textColor = .white
        missBadge.backgroundColor = UIColor(hexString: "#DF0340")
        missBadge.textAlignment = .center
        missBadge.layer.cornerRadius = 4
        missBadge.clipsToBounds = true

        missLabel.font = .fdFont(ofSize: 12, weight: .regular)
        missLabel.textColor = UIColor(hexString: "#DF0340")
        missLabel.text = "心电图/家族病史"

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

        pctLabel.font = .fdFont(ofSize: 18, weight: .medium)
        pctLabel.textColor = .fdPrimary
        pctUnit.font = .fdFont(ofSize: 12, weight: .medium)
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

        footerLbl.numberOfLines = 1

        completeBtn.setTitle("去补全", for: .normal)
        completeBtn.titleLabel?.font = .fdFont(ofSize: 12, weight: .medium)
        completeBtn.setTitleColor(.white, for: .normal)
        completeBtn.backgroundColor = .fdPrimary
        completeBtn.layer.cornerRadius = 14
        completeBtn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        completeBtn.addTarget(self, action: #selector(didTapComplete), for: .touchUpInside)

        illustView.image = UIImage(named: "health_archive_illust")
        illustView.contentMode = .scaleAspectFit
        illustView.alpha = 1.0
        illustView.isUserInteractionEnabled = false

        // 插画沉底，进度条 / 文案压在上面（对齐 Figma 层级）
        card.addSubview(illustView)
        [titleLbl, missBadge, missLabel, progressTrackBg, footerLbl, completeBtn].forEach(card.addSubview)

        illustView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(4)
            $0.size.equalTo(98)
        }
        titleLbl.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(12)
            $0.trailing.lessThanOrEqualTo(illustView.snp.leading).offset(-4)
        }
        missBadge.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.top.equalTo(titleLbl.snp.bottom).offset(10)
            $0.size.equalTo(14)
        }
        missLabel.snp.makeConstraints {
            $0.leading.equalTo(missBadge.snp.trailing).offset(4)
            $0.centerY.equalTo(missBadge)
            $0.trailing.lessThanOrEqualTo(illustView.snp.leading).offset(-4)
        }
        progressTrackBg.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().inset(12)
            $0.top.equalTo(missBadge.snp.bottom).offset(14)
            $0.height.equalTo(38)
        }
        footerLbl.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().inset(14)
            $0.trailing.lessThanOrEqualTo(completeBtn.snp.leading).offset(-8)
        }
        completeBtn.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalTo(footerLbl)
            $0.width.equalTo(70)
            $0.height.equalTo(28)
        }
    }

    func configure(archiveProgress: Int) {
        currentProgress = archiveProgress
        pctLabel.text = "\(archiveProgress)"
        let attr = NSMutableAttributedString(
            string: "补全后 ",
            attributes: [.font: UIFont.fdFont(ofSize: 12, weight: .regular), .foregroundColor: UIColor.fdSubtext]
        )
        attr.append(NSAttributedString(
            string: "+20",
            attributes: [.font: UIFont.fdFont(ofSize: 14, weight: .medium), .foregroundColor: UIColor.fdPrimary]
        ))
        attr.append(NSAttributedString(
            string: " 健康分·解锁家族风险图谱",
            attributes: [.font: UIFont.fdFont(ofSize: 12, weight: .regular), .foregroundColor: UIColor.fdSubtext]
        ))
        footerLbl.attributedText = attr
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
