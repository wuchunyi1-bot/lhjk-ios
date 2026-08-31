import UIKit
import SnapKit

/// 套餐列表机构卡片 — 对齐 Figma 3021:2241 / 3760:10603
final class ServiceInstitutionCardView: UIView {

    var onSwitchTap: (() -> Void)?

    private let iconView: UIView = {
        let view = UIView()
        view.backgroundColor = .fdPrimary
        view.layer.cornerRadius = 10
        return view
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "cross.case.fill"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 16, weight: .semibold)
        label.textColor = .fdText
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let typeBadgeContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.5).cgColor
        view.clipsToBounds = true
        return view
    }()

    private let typeBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 12, weight: .regular)
        label.textColor = .fdPrimary
        label.textAlignment = .center
        return label
    }()

    private let metaLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 12, weight: .regular)
        label.textColor = .fdSubtext
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    /// 「切换」+ 图标；宽度随内容，热区至少 44，避免旧版固定 48 宽导致点偏无响应
    private lazy var switchButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("切换", for: .normal)
        btn.setTitleColor(.fdPrimary, for: .normal)
        btn.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        btn.setImage(UIImage(named: "institution_switch")?.withRenderingMode(.alwaysOriginal), for: .normal)
        btn.semanticContentAttribute = .forceRightToLeft
        btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
        btn.addTarget(self, action: #selector(switchTapped), for: .touchUpInside)
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdBg
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        iconView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(22)
        }

        typeBadgeContainer.addSubview(typeBadgeLabel)
        typeBadgeLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
        }

        let titleRow = UIStackView(arrangedSubviews: [nameLabel, typeBadgeContainer])
        titleRow.axis = .horizontal
        titleRow.spacing = 8
        titleRow.alignment = .center

        typeBadgeContainer.setContentHuggingPriority(.required, for: .horizontal)
        typeBadgeContainer.setContentCompressionResistancePriority(.required, for: .horizontal)

        let infoStack = UIStackView(arrangedSubviews: [titleRow, metaLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 6
        infoStack.alignment = .leading

        addSubview(iconView)
        addSubview(infoStack)
        addSubview(switchButton)

        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.top.equalToSuperview().offset(18)
            $0.size.equalTo(42)
        }
        switchButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(8)
            $0.centerY.equalTo(iconView)
            $0.height.greaterThanOrEqualTo(44)
        }
        switchButton.setContentHuggingPriority(.required, for: .horizontal)
        switchButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        infoStack.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(8)
            $0.centerY.equalTo(iconView)
            $0.trailing.lessThanOrEqualTo(switchButton.snp.leading).offset(-4)
        }
        snp.makeConstraints { $0.height.equalTo(78) }
    }

    func configure(_ display: ServiceListInstitutionDisplay) {
        nameLabel.text = display.name
        typeBadgeLabel.text = display.typeLabel
        let address = display.address.trimmingCharacters(in: .whitespacesAndNewlines)
        let distance = display.distance.trimmingCharacters(in: .whitespacesAndNewlines)
        if address.isEmpty {
            metaLabel.text = distance
        } else if distance.isEmpty {
            metaLabel.text = address
        } else {
            metaLabel.text = "\(address)｜\(distance)"
        }
    }

    @objc private func switchTapped() {
        onSwitchTap?()
    }
}
