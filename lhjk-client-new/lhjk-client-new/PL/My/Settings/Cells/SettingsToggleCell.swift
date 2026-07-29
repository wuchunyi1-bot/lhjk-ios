import UIKit
import SnapKit

/// 设置页通用开关行 — title + subtitle + UISwitch
/// 对齐 PrivacySettingsView.vue `.switch-row`：内边距 16，开关缩小至约 22pt 高度
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
        l.font = .fdBodySemibold
        l.textColor = .fdText2
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 11, weight: .regular)
        l.textColor = .fdSubtext
        l.numberOfLines = 0
        return l
    }()

    private let toggle: UISwitch = {
        let s = UISwitch()
        s.onTintColor = .fdPrimary
        // 对齐 Vue van-switch size="22"（系统 UISwitch 默认高约 31）
        s.transform = CGAffineTransform(scaleX: 0.72, y: 0.72)
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

        // 预留缩放后开关宽度，避免文字顶到开关
        toggle.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualTo(toggle.snp.leading).offset(-12)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualTo(toggle.snp.leading).offset(-12)
            make.bottom.equalToSuperview().offset(-14)
        }

        divider.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(58)
        }
    }

    @objc private func toggleChanged() {
        onToggle?(toggle.isOn)
    }
}
