import UIKit
import SnapKit

/// 套餐列表机构卡片 — 对齐 Figma 3021:2241
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
        return label
    }()

    private let typeBadge: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 12, weight: .regular)
        label.textColor = .fdPrimary
        label.backgroundColor = .clear
        label.layer.cornerRadius = 4
        label.layer.borderWidth = 0.5
        label.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.5).cgColor
        label.clipsToBounds = true
        label.textAlignment = .center
        return label
    }()

    private let metaLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 12, weight: .regular)
        label.textColor = .fdSubtext
        return label
    }()

    private lazy var switchButton: UIButton = {
        let btn = UIButton(type: .custom)
        let titleLabel = UILabel()
        titleLabel.text = "切换"
        titleLabel.textColor = .fdPrimary
        titleLabel.font = .fdFont(ofSize: 14, weight: .medium)

        let iconView = UIImageView(image: UIImage(named: "institution_switch"))
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { $0.size.equalTo(18) }

        let content = UIStackView(arrangedSubviews: [titleLabel, iconView])
        content.axis = .horizontal
        content.spacing = 2
        content.alignment = .center
        btn.addSubview(content)
        content.snp.makeConstraints { $0.center.equalToSuperview() }

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

        let titleRow = UIStackView(arrangedSubviews: [nameLabel, typeBadge])
        titleRow.axis = .horizontal
        titleRow.spacing = 8
        titleRow.alignment = .center

        typeBadge.setContentHuggingPriority(.required, for: .horizontal)
        typeBadge.setContentCompressionResistancePriority(.required, for: .horizontal)

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
        infoStack.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(8)
            $0.centerY.equalTo(iconView)
            $0.trailing.lessThanOrEqualTo(switchButton.snp.leading).offset(-8)
        }
        typeBadge.snp.makeConstraints {
            $0.height.equalTo(18)
        }
        switchButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(iconView)
            $0.width.equalTo(48)
            $0.height.equalTo(44)
        }
        snp.makeConstraints { $0.height.equalTo(78) }
    }

    func configure(_ display: ServiceListInstitutionDisplay) {
        nameLabel.text = display.name
        typeBadge.text = "  \(display.typeLabel)  "
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
