import UIKit
import SnapKit

/// Hero 区域 Cell — 用户姓名、风险评分环、体征指标条
final class HomeHeroCell: UITableViewCell {

    static let reuseID = "HomeHeroCell"

    // MARK: - Data types

    struct Metric {
        let name: String
        let value: String
        let unit: String
        let status: String
        let statusType: String // "warning" / "success"
    }

    // MARK: - UI

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdPrimary
        v.clipsToBounds = true
        return v
    }()

    // Decorative blobs
    private let blob1: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        v.layer.cornerRadius = 90
        return v
    }()
    private let blob2: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        v.layer.cornerRadius = 40
        return v
    }()

    // Top bar
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .fdH2
        l.textColor = .white
        return l
    }()
    private let subLabel = UILabel()

    private let brandPill: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        return v
    }()

    // Score ring
    private let ringView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        v.layer.cornerRadius = 43
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.45).cgColor
        return v
    }()
    private let scoreNumLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 38, weight: .bold)
        l.textColor = .white
        return l
    }()
    private let scoreLabel: UILabel = {
        let l = UILabel()
        l.text = "SCORE"
        l.font = .fdMicro
        l.textColor = UIColor.white.withAlphaComponent(0.85)
        return l
    }()

    // Risk badge
    private let riskBadge: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#FFF5E0")
        v.layer.cornerRadius = 999
        return v
    }()
    private let riskDot: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#B47300")
        v.layer.cornerRadius = 3
        return v
    }()
    private let riskLabel: UILabel = {
        let l = UILabel()
        l.font = .fdMicroSemibold
        l.textColor = UIColor(hexString: "#7A3F00")
        return l
    }()

    private let hintLabel: UILabel = {
        let l = UILabel()
        l.font = .fdBody
        l.textColor = .white
        l.numberOfLines = 0
        return l
    }()

    // Metric chips
    private let chipsStack: UIStackView = {
        let s = UIStackView()
        s.distribution = .fillEqually
        s.spacing = 8
        return s
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .fdBg
        selectionStyle = .none
        contentView.clipsToBounds = false
        clipsToBounds = false
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(blob1)
        containerView.addSubview(blob2)

        // Brand pill
        let brandIcon = UIView()
        brandIcon.backgroundColor = .white
        brandIcon.layer.cornerRadius = 8
        let brandLbl = UILabel()
        brandLbl.text = "富德健康"
        brandLbl.font = .fdBodyBold
        brandLbl.textColor = .white
        brandPill.addSubview(brandIcon)
        brandPill.addSubview(brandLbl)
        brandIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        brandLbl.snp.makeConstraints { make in
            make.leading.equalTo(brandIcon.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }

        containerView.addSubview(nameLabel)
        containerView.addSubview(subLabel)
        containerView.addSubview(brandPill)

        // Score ring
        ringView.addSubview(scoreNumLabel)
        ringView.addSubview(scoreLabel)
        scoreNumLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-6)
        }
        scoreLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(scoreNumLabel.snp.bottom).offset(2)
        }

        // Risk badge
        riskBadge.addSubview(riskDot)
        riskBadge.addSubview(riskLabel)
        riskDot.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(6)
        }
        riskLabel.snp.makeConstraints { make in
            make.leading.equalTo(riskDot.snp.trailing).offset(5)
            make.trailing.equalToSuperview().offset(-8)
            make.top.bottom.equalToSuperview().inset(3)
        }

        containerView.addSubview(ringView)
        containerView.addSubview(riskBadge)
        containerView.addSubview(hintLabel)
        containerView.addSubview(chipsStack)

        // Layout — containerView 填满 contentView，内部内容通过 lessThanOrEqualTo 推高 cell 高度
        containerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        blob1.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-40)
            make.trailing.equalToSuperview().offset(30)
            make.size.equalTo(180)
        }
        blob2.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(60)
            make.trailing.equalToSuperview().offset(-40)
            make.size.equalTo(80)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(52)
            make.leading.equalToSuperview().offset(18)
        }
        subLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(18)
        }
        brandPill.snp.makeConstraints { make in
            make.centerY.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-18)
            make.height.equalTo(32)
        }

        ringView.snp.makeConstraints { make in
            make.top.equalTo(subLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(18)
            make.size.equalTo(86)
        }
        riskBadge.snp.makeConstraints { make in
            make.top.equalTo(ringView).offset(12)
            make.leading.equalTo(ringView.snp.trailing).offset(14)
        }
        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(riskBadge.snp.bottom).offset(8)
            make.leading.equalTo(ringView.snp.trailing).offset(14)
            make.trailing.equalToSuperview().offset(-16)
        }
        chipsStack.snp.makeConstraints { make in
            make.top.equalTo(ringView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(58)
            make.bottom.lessThanOrEqualToSuperview().offset(-20)
        }
    }

    // MARK: - Layout

    /// 修复 automaticDimension 高度计算时 contentView.width == 0 导致的 fillEqually 约束冲突
    /// 将 targetSize.width 替换为 table view 实际宽度，并强制水平方向按 required 解析
    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        var size = targetSize
        if size.width == 0, let tv = superview as? UITableView {
            size.width = tv.bounds.width
        }
        return super.systemLayoutSizeFitting(
            size,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: verticalFittingPriority
        )
    }

    // MARK: - Configure

    func configure(
        name: String,
        advisor: String,
        daysLeft: Int,
        riskScore: Int,
        riskLevel: String,
        riskHint: String,
        metrics: [Metric]
    ) {
        nameLabel.text = "你好，\(name)"

        let attr = NSMutableAttributedString(
            string: "健管师 · \(advisor)  |  服务剩 ",
            attributes: [
                .font: UIFont.fdCaption,
                .foregroundColor: UIColor.white.withAlphaComponent(0.85)
            ]
        )
        attr.append(NSAttributedString(
            string: "\(daysLeft)",
            attributes: [
                .font: UIFont.fdCaptionSemibold,
                .foregroundColor: UIColor.white
            ]
        ))
        attr.append(NSAttributedString(
            string: " 天",
            attributes: [
                .font: UIFont.fdCaption,
                .foregroundColor: UIColor.white.withAlphaComponent(0.85)
            ]
        ))
        subLabel.attributedText = attr

        scoreNumLabel.text = "\(riskScore)"
        riskLabel.text = riskLevel
        hintLabel.text = riskHint

        // Metric chips
        chipsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for m in metrics {
            let chip = makeMetricChip(m)
            chipsStack.addArrangedSubview(chip)
        }
    }

    private func makeMetricChip(_ m: Metric) -> UIView {
        let isWarning = m.statusType == "warning"
        let chip = UIView()
        chip.backgroundColor = UIColor.white.withAlphaComponent(isWarning ? 0.22 : 0.18)
        chip.layer.cornerRadius = 14
        chip.layer.borderWidth = 1
        chip.layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor

        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.distribution = .equalSpacing

        let nameLbl = UILabel()
        nameLbl.text = m.name
        nameLbl.font = .fdMicro
        nameLbl.textColor = UIColor.white.withAlphaComponent(0.78)

        let tag = UIView()
        tag.backgroundColor = isWarning
            ? UIColor(hexString: "#FFF5E0")
            : UIColor.white.withAlphaComponent(0.3)
        tag.layer.cornerRadius = 4
        let tagLbl = UILabel()
        tagLbl.text = m.status
        tagLbl.font = .fdMicroSemibold
        tagLbl.textColor = isWarning
            ? UIColor(hexString: "#7A3F00")
            : .white
        tagLbl.textAlignment = .center
        tag.addSubview(tagLbl)
        tagLbl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 1, left: 5, bottom: 1, right: 5)) }
        topRow.addArrangedSubview(nameLbl)
        topRow.addArrangedSubview(tag)

        let valRow = UIStackView()
        valRow.axis = .horizontal
        valRow.alignment = .lastBaseline
        valRow.spacing = 2
        let valLbl = UILabel()
        valLbl.text = m.value
        valLbl.font = .fdH3
        valLbl.textColor = .white
        let unitLbl = UILabel()
        unitLbl.text = m.unit
        unitLbl.font = .fdMicro
        unitLbl.textColor = UIColor.white.withAlphaComponent(0.7)
        valRow.addArrangedSubview(valLbl)
        valRow.addArrangedSubview(unitLbl)

        chip.addSubview(topRow)
        chip.addSubview(valRow)
        topRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(8)
        }
        valRow.snp.makeConstraints { make in
            make.top.equalTo(topRow.snp.bottom).offset(5)
            make.leading.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().offset(-8)
        }

        return chip
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        chipsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}
