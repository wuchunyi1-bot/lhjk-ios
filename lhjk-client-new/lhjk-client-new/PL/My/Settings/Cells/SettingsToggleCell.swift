import UIKit
import SnapKit

/// 设置页通用开关行 — title + subtitle + UISwitch
final class SettingsToggleCell: UIView {

    // MARK: - Model

    struct Model {
        let title: String
        let subtitle: String
        let isOn: Bool
    }

    enum VisualStyle {
        /// 隐私设置等默认样式
        case standard
        /// 消息通知设置 Figma 卡片内行
        case notification
    }

    // MARK: - UI

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

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

    private let style: VisualStyle
    private let contentInset: CGFloat
    private let textSpacing: CGFloat

    // MARK: - State

    var onToggle: ((Bool) -> Void)?

    var isOn: Bool {
        get { toggle.isOn }
        set { toggle.isOn = newValue }
    }

    // MARK: - Init

    init(model: Model, showDivider: Bool = true, style: VisualStyle = .standard) {
        self.style = style
        switch style {
        case .standard:
            contentInset = 16
            textSpacing = 2
        case .notification:
            contentInset = 12
            textSpacing = 4
        }
        super.init(frame: .zero)

        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
        toggle.isOn = model.isOn
        divider.isHidden = !showDivider
        applyTypography()

        setupUI()
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func applyTypography() {
        switch style {
        case .standard:
            titleLabel.font = SettingsStyle.rowTitleFont
            titleLabel.textColor = SettingsStyle.titleColor
            subtitleLabel.font = SettingsStyle.rowSubtitleFont
            subtitleLabel.textColor = SettingsStyle.subtitleColor
            toggle.transform = CGAffineTransform(scaleX: 0.72, y: 0.72)
        case .notification:
            titleLabel.font = SettingsStyle.rowTitleFont
            titleLabel.textColor = SettingsStyle.titleColor
            subtitleLabel.font = SettingsStyle.rowSubtitleFont
            subtitleLabel.textColor = SettingsStyle.subtitleColor
            // Figma 开关约 37×20
            toggle.transform = CGAffineTransform(scaleX: 0.78, y: 0.78)
        }
        subtitleLabel.numberOfLines = 0
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
            make.trailing.equalToSuperview().inset(contentInset)
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(contentInset + 2)
            make.leading.equalToSuperview().inset(contentInset)
            make.trailing.lessThanOrEqualTo(toggle.snp.leading).offset(-12)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(textSpacing)
            make.leading.equalToSuperview().inset(contentInset)
            make.trailing.lessThanOrEqualTo(toggle.snp.leading).offset(-12)
            make.bottom.equalToSuperview().offset(-(contentInset + 2))
        }

        divider.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(contentInset)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        let minHeight: CGFloat = style == .notification ? 67 : 58
        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(minHeight)
        }
    }

    @objc private func toggleChanged() {
        onToggle?(toggle.isOn)
    }
}
