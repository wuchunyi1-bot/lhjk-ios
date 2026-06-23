import UIKit
import SnapKit

/// 用户信息卡片 Cell — init 创建控件，configure 仅赋值
final class HealthRecordUserInfoCell: UITableViewCell {

    static let reuseIdentifier = "HealthRecordUserInfoCell"
    var onSixDimTap: (() -> Void)?

    // MARK: - Views
    private let card = UIView()
    private let avatarView = UIView()
    private let avatarLabel = UILabel()
    private let avatarGradient = CAGradientLayer()
    private let nameLbl = UILabel()
    private let tagView = UIView(); private let tagLabel = UILabel()
    private let progressLabel = UILabel(); private let pctLabel = UILabel()
    private let progressBg = UIView(); private let progressFill = UIView()
    private let sixDimBtn = UIButton(type: .system)
    private var fillWidthConstraint: Constraint?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none; backgroundColor = .clear
        setupViews()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupViews() {
        card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor; card.layer.shadowOffset = CGSize(width: 0, height: 1); card.layer.shadowRadius = 6; card.layer.shadowOpacity = 0.03
        contentView.addSubview(card); card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        // Avatar
        avatarView.layer.cornerRadius = 24; avatarView.clipsToBounds = true
        avatarGradient.colors = [UIColor(hexString: "#F4ECE3").cgColor, UIColor(hexString: "#E8DAC8").cgColor]
        avatarGradient.startPoint = CGPoint(x: 0, y: 0); avatarGradient.endPoint = CGPoint(x: 1, y: 1)
        avatarView.layer.insertSublayer(avatarGradient, at: 0)
        avatarView.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor; avatarView.layer.borderWidth = 2
        avatarLabel.font = .fdH3; avatarLabel.textColor = UIColor(hexString: "#7B5E40"); avatarLabel.textAlignment = .center
        avatarView.addSubview(avatarLabel); avatarLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        // Name + tag
        nameLbl.font = .fdH2; nameLbl.textColor = .fdText
        tagView.backgroundColor = .fdPrimarySoft; tagView.layer.cornerRadius = 4
        tagLabel.text = "本人"; tagLabel.font = .fdMicroSemibold; tagLabel.textColor = .fdPrimary
        tagView.addSubview(tagLabel); tagLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6)) }
        let nameRow = UIStackView(arrangedSubviews: [nameLbl, tagView, UIView()]); nameRow.spacing = 6; nameRow.alignment = .center

        // Progress
        progressLabel.text = "档案完整度"; progressLabel.font = .fdMicro; progressLabel.textColor = .fdSubtext
        pctLabel.font = .fdMonoFont(ofSize: 14, weight: .bold); pctLabel.textColor = .fdPrimary
        let progressTextRow = UIStackView(arrangedSubviews: [progressLabel, pctLabel]); progressTextRow.spacing = 4; progressTextRow.alignment = .firstBaseline

        progressBg.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.14); progressBg.layer.cornerRadius = 4; progressBg.clipsToBounds = true
        progressFill.backgroundColor = .fdPrimary; progressFill.layer.cornerRadius = 4
        progressBg.addSubview(progressFill)
        progressFill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            fillWidthConstraint = make.width.equalTo(0).constraint
        }

        let metaStack = UIStackView(arrangedSubviews: [nameRow, progressTextRow, progressBg]); metaStack.axis = .vertical; metaStack.spacing = 4; metaStack.alignment = .leading
        progressBg.snp.makeConstraints { $0.width.equalTo(110); $0.height.equalTo(8) }

        let leftStack = UIStackView(arrangedSubviews: [avatarView, metaStack]); leftStack.spacing = 12; leftStack.alignment = .center
        card.addSubview(leftStack)
        avatarView.snp.makeConstraints { $0.size.equalTo(48) }
        leftStack.snp.makeConstraints { $0.leading.equalToSuperview().offset(16); $0.centerY.equalToSuperview() }

        // Six-dim button
        sixDimBtn.setTitle("六维评测 ›", for: .normal)
        sixDimBtn.titleLabel?.font = .fdCaptionSemibold; sixDimBtn.setTitleColor(.white, for: .normal)
        sixDimBtn.backgroundColor = .fdPrimary; sixDimBtn.layer.cornerRadius = 20
        sixDimBtn.contentEdgeInsets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
        sixDimBtn.addTarget(self, action: #selector(didTapSixDim), for: .touchUpInside)
        card.addSubview(sixDimBtn)
        sixDimBtn.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview() }

        card.snp.makeConstraints { $0.height.greaterThanOrEqualTo(80) }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarGradient.frame = avatarView.bounds
    }

    // MARK: - Configure

    func configure(userName: String, avatarText: String, archiveProgress: Int) {
        avatarLabel.text = avatarText
        nameLbl.text = userName
        pctLabel.text = "\(archiveProgress)%"
        fillWidthConstraint?.update(offset: 110 * CGFloat(archiveProgress) / 100.0)
    }

    @objc private func didTapSixDim() { onSixDimTap?() }
}
