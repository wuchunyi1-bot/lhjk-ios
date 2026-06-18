import UIKit
import SnapKit

/// 健康档案完整度卡片 Cell — 视图 init 创建，configure 仅赋值 + 更新进度条宽度
final class HealthArchiveCardCell: UITableViewCell {

    static let reuseIdentifier = "HealthArchiveCardCell"
    var onCompleteTap: (() -> Void)?

    // MARK: - Views

    private let card = UIView()
    private let titleLbl = UILabel()
    private let hintLbl = UILabel()
    private let pctLabel = UILabel()
    private let pctUnit = UILabel()
    private let progressBg = UIView()
    private let progressFill = UIView()
    private let footerLbl = UILabel()
    private let completeBtn = UIButton(type: .system)
    private var fillWidthConstraint: Constraint?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupViews() {
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6; card.layer.shadowOpacity = 0.03
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        titleLbl.font = .fdBodySemibold; titleLbl.textColor = .fdText
        hintLbl.font = .fdMicro; hintLbl.textColor = .fdSubtext
        pctLabel.font = .fdH2; pctLabel.textColor = .fdPrimary
        pctUnit.font = .fdCaption; pctUnit.textColor = .fdSubtext; pctUnit.text = "%"

        progressBg.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.14)
        progressBg.layer.cornerRadius = 4
        progressFill.backgroundColor = .fdPrimary
        progressFill.layer.cornerRadius = 4
        progressBg.addSubview(progressFill)

        footerLbl.font = .fdMicro; footerLbl.textColor = .fdMuted
        completeBtn.setTitle("去补全", for: .normal)
        completeBtn.titleLabel?.font = .fdCaptionSemibold
        completeBtn.setTitleColor(.fdPrimary, for: .normal)
        completeBtn.backgroundColor = .fdPrimarySoft
        completeBtn.layer.cornerRadius = 999
        completeBtn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        completeBtn.addTarget(self, action: #selector(didTapComplete), for: .touchUpInside)

        [titleLbl, hintLbl, pctLabel, pctUnit, progressBg, footerLbl, completeBtn].forEach(card.addSubview)

        titleLbl.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }
        hintLbl.snp.makeConstraints { $0.top.equalTo(titleLbl.snp.bottom).offset(2); $0.leading.equalToSuperview().inset(16) }
        pctLabel.snp.makeConstraints { $0.top.equalToSuperview().inset(16); $0.trailing.equalTo(pctUnit.snp.leading).offset(-2) }
        pctUnit.snp.makeConstraints { $0.lastBaseline.equalTo(pctLabel); $0.trailing.equalToSuperview().offset(-16) }
        progressBg.snp.makeConstraints { $0.top.equalTo(hintLbl.snp.bottom).offset(10); $0.leading.trailing.equalToSuperview().inset(16); $0.height.equalTo(8) }
        progressFill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            fillWidthConstraint = make.width.equalTo(0).constraint
        }
        footerLbl.snp.makeConstraints { $0.top.equalTo(progressBg.snp.bottom).offset(12); $0.leading.equalToSuperview().inset(16); $0.bottom.equalToSuperview().offset(-16) }
        completeBtn.snp.makeConstraints { $0.centerY.equalTo(footerLbl); $0.trailing.equalToSuperview().offset(-16) }
    }

    // MARK: - Configure

    func configure(archiveProgress: Int) {
        titleLbl.text = "健康档案完整度"
        hintLbl.text = "缺：心电图 / 家族病史"
        pctLabel.text = "\(archiveProgress)"
        footerLbl.text = "补全后 +20 健康分 · 解锁家族风险图谱"
        fillWidthConstraint?.update(offset: progressBg.bounds.width * CGFloat(archiveProgress) / 100.0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Re-apply progress width after layout (bounds known)
        if let pctText = pctLabel.text, let pct = Int(pctText) {
            fillWidthConstraint?.update(offset: progressBg.bounds.width * CGFloat(pct) / 100.0)
        }
    }

    @objc private func didTapComplete() { onCompleteTap?() }
}
