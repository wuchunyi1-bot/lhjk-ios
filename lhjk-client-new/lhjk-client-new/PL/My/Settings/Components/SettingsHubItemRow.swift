import UIKit
import SnapKit

/// 设置主页行 — 对齐 SettingsView.vue `.settings-item`
/// 左图标软底 + 标题/说明 + 右箭头
final class SettingsHubItemRow: UIControl {

    private let iconBg = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let descLabel = UILabel()
    private let arrowView = UIImageView()
    private let divider = UIView()

    var descText: String? {
        get { descLabel.text }
        set { descLabel.text = newValue }
    }

    init(
        title: String,
        desc: String,
        systemImage: String,
        showDivider: Bool,
        action: @escaping () -> Void
    ) {
        super.init(frame: .zero)
        addAction(UIAction { _ in action() }, for: .touchUpInside)

        iconBg.backgroundColor = .fdPrimarySoft
        iconBg.layer.cornerRadius = 10
        iconBg.isUserInteractionEnabled = false

        iconView.image = UIImage(systemName: systemImage)
        iconView.tintColor = .fdPrimary
        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false

        titleLabel.text = title
        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText
        titleLabel.isUserInteractionEnabled = false

        descLabel.text = desc
        descLabel.font = .fdFont(ofSize: 11, weight: .regular)
        descLabel.textColor = .fdSubtext
        descLabel.numberOfLines = 2
        descLabel.isUserInteractionEnabled = false

        arrowView.image = UIImage(systemName: "chevron.right")
        arrowView.tintColor = .fdMuted
        arrowView.contentMode = .scaleAspectFit
        arrowView.isUserInteractionEnabled = false

        divider.backgroundColor = .fdBorder
        divider.isHidden = !showDivider

        let textStack = UIStackView(arrangedSubviews: [titleLabel, descLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.isUserInteractionEnabled = false

        addSubview(iconBg)
        iconBg.addSubview(iconView)
        addSubview(textStack)
        addSubview(arrowView)
        addSubview(divider)

        iconBg.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(36)
        }
        iconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(20)
        }
        arrowView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(14)
        }
        textStack.snp.makeConstraints {
            $0.leading.equalTo(iconBg.snp.trailing).offset(12)
            $0.trailing.equalTo(arrowView.snp.leading).offset(-8)
            $0.top.equalToSuperview().offset(13)
            $0.bottom.equalToSuperview().offset(-13)
        }
        divider.snp.makeConstraints {
            $0.leading.equalTo(textStack)
            $0.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }

        snp.makeConstraints { $0.height.greaterThanOrEqualTo(56) }
    }

    required init?(coder: NSCoder) { fatalError() }
}
