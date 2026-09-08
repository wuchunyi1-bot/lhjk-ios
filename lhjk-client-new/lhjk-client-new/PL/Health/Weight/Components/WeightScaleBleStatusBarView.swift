import SnapKit
import UIKit

/// 体重 H5 顶部体脂秤蓝牙状态横条 — 对齐 Figma 4449:11585 / 5126:7385 / 5136:12244
final class WeightScaleBleStatusBarView: UIControl {

    enum Style {
        case unbound
        case listening
        case disconnected
        case bluetoothUnavailable
    }

    static let preferredHeight: CGFloat = 52

    var onPrimaryAction: (() -> Void)?
    var onRetryAction: (() -> Void)?

    private let iconView = UIImageView()
    private let messageLabel = UILabel()
    private let separatorLabel = UILabel()
    private let retryButton = UIButton(type: .custom)
    private let messageStack = UIStackView()
    private let bindActionView = UIView()
    private let bindActionLabel = UILabel()
    private let chevronView = UIImageView()
    private let accessoryStack = UIStackView()
    private var iconSizeConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(style: Style, message: String, actionTitle: String?) {
        stopConnectingSpin()
        messageLabel.attributedText = nil
        messageLabel.font = .fdFont(ofSize: 14, weight: .medium)
        messageLabel.textColor = UIColor(hexString: "#1F2942")
        messageLabel.text = message

        switch style {
        case .unbound:
            applyIcon(named: "weight_ble_unbound_scale", size: 28)
            bindActionLabel.text = actionTitle ?? "去绑定"
            bindActionView.isHidden = false
            separatorLabel.isHidden = true
            retryButton.isHidden = true
            chevronView.isHidden = true
            accessoryStack.isHidden = false
            isUserInteractionEnabled = true

        case .listening:
            applyIcon(named: "weight_ble_connecting", size: 24)
            startConnectingSpin()
            bindActionView.isHidden = true
            separatorLabel.isHidden = true
            retryButton.isHidden = true
            chevronView.isHidden = false
            accessoryStack.isHidden = false
            isUserInteractionEnabled = true

        case .disconnected:
            applyIcon(named: "weight_ble_disconnected", size: 24)
            retryButton.setTitle(actionTitle ?? "点击重试", for: .normal)
            bindActionView.isHidden = true
            separatorLabel.isHidden = false
            retryButton.isHidden = false
            chevronView.isHidden = false
            accessoryStack.isHidden = false
            isUserInteractionEnabled = true

        case .bluetoothUnavailable:
            iconView.isHidden = true
            iconSizeConstraint?.update(offset: 0)
            accessoryStack.isHidden = true
            bindActionView.isHidden = true
            separatorLabel.isHidden = true
            retryButton.isHidden = true
            chevronView.isHidden = true
            isUserInteractionEnabled = false
        }
    }

    // MARK: - Private

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 12
        clipsToBounds = true

        iconView.contentMode = .scaleAspectFit

        messageLabel.font = .fdFont(ofSize: 14, weight: .medium)
        messageLabel.textColor = UIColor(hexString: "#1F2942")
        messageLabel.numberOfLines = 1
        messageLabel.lineBreakMode = .byTruncatingTail
        messageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        separatorLabel.text = "｜"
        separatorLabel.font = .fdFont(ofSize: 14, weight: .medium)
        separatorLabel.textColor = UIColor(hexString: "#A6ACB8")
        separatorLabel.isHidden = true
        separatorLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        retryButton.setTitle("点击重试", for: .normal)
        retryButton.setTitleColor(.fdPrimary, for: .normal)
        retryButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        retryButton.isHidden = true
        retryButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 2, bottom: 8, right: 4)
        retryButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        retryButton.addTarget(self, action: #selector(handleRetryTap), for: .touchUpInside)

        messageStack.axis = .horizontal
        messageStack.alignment = .center
        messageStack.spacing = 0
        messageStack.addArrangedSubview(messageLabel)
        messageStack.addArrangedSubview(separatorLabel)
        messageStack.addArrangedSubview(retryButton)

        bindActionView.layer.cornerRadius = 14
        bindActionView.layer.borderWidth = 0.5
        bindActionView.layer.borderColor = UIColor.fdPrimary.cgColor
        bindActionView.backgroundColor = .clear

        bindActionLabel.font = .fdFont(ofSize: 12, weight: .medium)
        bindActionLabel.textColor = .fdPrimary
        bindActionLabel.textAlignment = .center
        bindActionLabel.text = "去绑定"

        chevronView.image = UIImage(named: "weight_ble_chevron")
        chevronView.contentMode = .scaleAspectFit

        accessoryStack.axis = .horizontal
        accessoryStack.alignment = .center
        accessoryStack.spacing = 0
        accessoryStack.addArrangedSubview(bindActionView)
        accessoryStack.addArrangedSubview(chevronView)

        addSubview(iconView)
        addSubview(messageStack)
        addSubview(accessoryStack)
        bindActionView.addSubview(bindActionLabel)

        [
            iconView, messageLabel, separatorLabel, messageStack,
            accessoryStack, bindActionView, bindActionLabel, chevronView,
        ].forEach { $0.isUserInteractionEnabled = false }
        retryButton.isUserInteractionEnabled = true

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            iconSizeConstraint = make.size.equalTo(24).constraint
        }

        bindActionView.snp.makeConstraints { make in
            make.width.equalTo(70)
            make.height.equalTo(28)
        }
        bindActionLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        chevronView.snp.makeConstraints { make in
            make.size.equalTo(12)
        }

        accessoryStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }

        messageStack.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(accessoryStack.snp.leading).offset(-8)
        }
    }

    private func applyIcon(named name: String, size: CGFloat) {
        iconView.isHidden = false
        iconView.image = UIImage(named: name)
        iconSizeConstraint?.update(offset: size)
    }

    private func startConnectingSpin() {
        iconView.layer.removeAnimation(forKey: "weightBleSpin")
        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = 0
        spin.toValue = CGFloat.pi * 2
        spin.duration = 1.0
        spin.repeatCount = .infinity
        spin.timingFunction = CAMediaTimingFunction(name: .linear)
        iconView.layer.add(spin, forKey: "weightBleSpin")
    }

    private func stopConnectingSpin() {
        iconView.layer.removeAnimation(forKey: "weightBleSpin")
        iconView.transform = .identity
    }

    @objc private func handleTap() {
        guard isUserInteractionEnabled else { return }
        onPrimaryAction?()
    }

    @objc private func handleRetryTap() {
        onRetryAction?()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.contains(point)
    }
}
