import UIKit
import SnapKit

/// 套餐列表机构卡片 — 对齐 funde `ServiceListView.vue` `.service-institution-card`
final class ServiceInstitutionCardView: UIView {

    var onSwitchTap: (() -> Void)?

    private let iconView: UIView = {
        let view = UIView()
        view.backgroundColor = .fdPrimarySoft
        view.layer.cornerRadius = 8
        return view
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "cross.case"))
        iv.tintColor = .fdPrimary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .fdBodyBold
        label.textColor = .fdText
        return label
    }()

    private let typeBadge: UILabel = {
        let label = UILabel()
        label.font = .fdMicroSemibold
        label.textColor = .fdPrimary
        label.backgroundColor = .fdPrimarySoft
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.textAlignment = .center
        return label
    }()

    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = .fdCaption
        label.textColor = .fdSubtext
        return label
    }()

    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .fdCaption
        label.textColor = .fdSubtext
        return label
    }()

    private lazy var switchButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("切换", for: .normal)
        btn.setImage(UIImage(systemName: "arrow.left.arrow.right"), for: .normal)
        btn.tintColor = .fdPrimary
        btn.titleLabel?.font = .fdCaptionSemibold
        btn.semanticContentAttribute = .forceRightToLeft
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
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
        iconImageView.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(18) }

        let titleRow = UIStackView(arrangedSubviews: [nameLabel, typeBadge])
        titleRow.axis = .horizontal
        titleRow.spacing = 8
        titleRow.alignment = .center

        typeBadge.setContentHuggingPriority(.required, for: .horizontal)
        typeBadge.setContentCompressionResistancePriority(.required, for: .horizontal)

        let metaRow = UIStackView(arrangedSubviews: [addressLabel, distanceLabel])
        metaRow.axis = .horizontal
        metaRow.spacing = 8
        metaRow.alignment = .center

        let divider = UIView()
        divider.backgroundColor = .fdBorderStrong
        divider.snp.makeConstraints { $0.width.equalTo(1); $0.height.equalTo(12) }
        metaRow.insertArrangedSubview(divider, at: 1)

        let infoStack = UIStackView(arrangedSubviews: [titleRow, metaRow])
        infoStack.axis = .vertical
        infoStack.spacing = 4

        addSubview(iconView)
        addSubview(infoStack)
        addSubview(switchButton)

        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(36)
        }
        infoStack.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(switchButton.snp.leading).offset(-8)
        }
        switchButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(44)
        }
        snp.makeConstraints { $0.height.equalTo(68) }
    }

    func configure(_ display: ServiceListInstitutionDisplay) {
        nameLabel.text = display.name
        typeBadge.text = " \(display.typeLabel) "
        addressLabel.text = display.address
        distanceLabel.text = display.distance
    }

    @objc private func switchTapped() {
        onSwitchTap?()
    }
}
