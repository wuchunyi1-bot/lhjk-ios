import UIKit
import SnapKit

/// 设置页通用开关行 — title + subtitle + UISwitch
/// 参考 funde-client: van-cell + van-switch
final class SettingsToggleCell: UIView {

    // MARK: - Model

    struct Model {
        let title: String
        let subtitle: String
        let isOn: Bool
    }

    // MARK: - UI

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdBody
        l.textColor = .fdText
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdCaption
        l.textColor = .fdSubtext
        l.numberOfLines = 0
        return l
    }()

    private let toggle: UISwitch = {
        let s = UISwitch()
        s.onTintColor = .fdPrimary
        return s
    }()

    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = .fdBorder
        return v
    }()

    // MARK: - State

    var onToggle: ((Bool) -> Void)?

    var isOn: Bool {
        get { toggle.isOn }
        set { toggle.isOn = newValue }
    }

    // MARK: - Init

    init(model: Model, showDivider: Bool = true) {
        super.init(frame: .zero)

        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
        toggle.isOn = model.isOn
        divider.isHidden = !showDivider

        setupUI()
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(toggle)
        addSubview(divider)

        toggle.setContentHuggingPriority(.required, for: .horizontal)
        toggle.setContentCompressionResistancePriority(.required, for: .horizontal)

        toggle.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-2)
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(13)
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualTo(toggle.snp.leading).offset(-12)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualTo(toggle.snp.leading).offset(-12)
            make.bottom.equalToSuperview().offset(-13)
        }

        divider.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    @objc private func toggleChanged() {
        onToggle?(toggle.isOn)
    }
}
