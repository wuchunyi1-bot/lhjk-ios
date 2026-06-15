import UIKit
import SnapKit

/// 健康档案完整度卡片 Cell
final class HealthArchiveCardCell: UITableViewCell {

    static let reuseIdentifier = "HealthArchiveCardCell"

    var onCompleteTap: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(archiveProgress: Int) {
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

        let titleLbl = label("健康档案完整度", size: 14, weight: .semibold, color: .fdText)
        let hintLbl = label("缺：心电图 / 家族病史", size: 11, weight: .regular, color: .fdSubtext)
        let pctLabel = label("\(archiveProgress)", size: 22, weight: .bold, color: .fdPrimary)
        let pctUnit = label("%", size: 12, weight: .regular, color: .fdSubtext)

        let progressBg = UIView()
        progressBg.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.14)
        progressBg.layer.cornerRadius = 4
        let progressFill = UIView()
        progressFill.backgroundColor = .fdPrimary
        progressFill.layer.cornerRadius = 4
        progressBg.addSubview(progressFill)

        let footerLbl = label("补全后 +20 健康分 · 解锁家族风险图谱", size: 11, weight: .regular, color: .fdMuted)
        let completeBtn = UIButton(type: .system)
        completeBtn.setTitle("去补全", for: .normal)
        completeBtn.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
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
            make.width.equalToSuperview().multipliedBy(CGFloat(archiveProgress) / 100.0)
        }
        footerLbl.snp.makeConstraints { $0.top.equalTo(progressBg.snp.bottom).offset(12); $0.leading.equalToSuperview().inset(16); $0.bottom.equalToSuperview().offset(-16) }
        completeBtn.snp.makeConstraints { $0.centerY.equalTo(footerLbl); $0.trailing.equalToSuperview().offset(-16) }
    }

    @objc private func didTapComplete() { onCompleteTap?() }

    private func label(_ text: String, size: CGFloat, weight: UIFont.Weight, color: UIColor) -> UILabel {
        let l = UILabel(); l.text = text; l.font = .systemFont(ofSize: size, weight: weight); l.textColor = color
        return l
    }
}
