import SnapKit
import UIKit

/// 体重 H5 顶部体脂秤蓝牙状态横条 — 对齐 funde-client weight.md §6.6
final class WeightScaleBleStatusBarView: UIControl {

    enum Style {
        case unbound
        case listening
        case disconnected
        case bluetoothUnavailable
    }

    static let preferredHeight: CGFloat = 52

    var onPrimaryAction: (() -> Void)?

    private let gradientLayer = CAGradientLayer()
    private let iconView = UIImageView()
    private let messageLabel = UILabel()
    private let actionLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let chevronView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = layer.cornerRadius
    }

    func configure(style: Style, message: String, actionTitle: String?) {
        messageLabel.text = message
        actionLabel.text = actionTitle
        actionLabel.isHidden = actionTitle == nil

        switch style {
        case .unbound:
            applyGradient(start: .fdInfo, end: UIColor(hexString: "#7BA8D9"))
            iconView.image = UIImage(systemName: "scalemass.fill")
            iconView.tintColor = .white
            iconView.isHidden = false
            spinner.stopAnimating()
            spinner.isHidden = true
            chevronView.isHidden = true
            messageLabel.textColor = .white
            actionLabel.textColor = .white
            actionLabel.backgroundColor = UIColor.white.withAlphaComponent(0.22)
            actionLabel.layer.cornerRadius = 12
            actionLabel.clipsToBounds = true
            isUserInteractionEnabled = true

        case .listening:
            applyGradient(start: .fdPrimary, end: .fdLoginButtonEnd)
            iconView.isHidden = true
            spinner.color = .white
            spinner.isHidden = false
            spinner.startAnimating()
            chevronView.image = UIImage(systemName: "chevron.right")
            chevronView.tintColor = UIColor.white.withAlphaComponent(0.9)
            chevronView.isHidden = false
            messageLabel.textColor = .white
            actionLabel.isHidden = true
            isUserInteractionEnabled = true

        case .disconnected:
            applyGradient(start: .fdSurface2, end: .fdBg2)
            iconView.image = UIImage(systemName: "scalemass")
            iconView.tintColor = .fdSubtext
            iconView.isHidden = false
            spinner.stopAnimating()
            spinner.isHidden = true
            chevronView.isHidden = true
            messageLabel.textColor = .fdText
            actionLabel.textColor = .fdPrimary
            actionLabel.backgroundColor = .clear
            actionLabel.isHidden = actionTitle == nil
            isUserInteractionEnabled = true

        case .bluetoothUnavailable:
            applyGradient(start: .fdWarningSoft, end: .fdSurface2)
            iconView.image = UIImage(systemName: "bluetooth.slash")
            iconView.tintColor = .fdWarning
            iconView.isHidden = false
            spinner.stopAnimating()
            spinner.isHidden = true
            chevronView.isHidden = true
            messageLabel.textColor = .fdText2
            actionLabel.isHidden = true
            isUserInteractionEnabled = false
        }
    }

    // MARK: - Private

    private func setupUI() {
        layer.cornerRadius = 12
        clipsToBounds = true
        layer.insertSublayer(gradientLayer, at: 0)

        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)

        messageLabel.font = .fdBody
        messageLabel.numberOfLines = 2

        actionLabel.font = .fdCaptionSemibold
        actionLabel.textAlignment = .center

        chevronView.contentMode = .scaleAspectFit

        let textStack = UIStackView(arrangedSubviews: [messageLabel, actionLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading

        addSubview(iconView)
        addSubview(spinner)
        addSubview(textStack)
        addSubview(chevronView)

        // 子视图默认会吃掉点击，导致 UIControl 的 touchUpInside 不触发
        [iconView, spinner, textStack, messageLabel, actionLabel, chevronView].forEach {
            $0.isUserInteractionEnabled = false
        }

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(22)
        }

        spinner.snp.makeConstraints { make in
            make.center.equalTo(iconView)
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(chevronView.snp.leading).offset(-8)
        }

        actionLabel.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.width.greaterThanOrEqualTo(56)
        }
        actionLabel.layoutMargins = UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 10)

        chevronView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
        }
    }

    private func applyGradient(start: UIColor, end: UIColor) {
        gradientLayer.colors = [start.cgColor, end.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
    }

    @objc private func handleTap() {
        guard isUserInteractionEnabled else { return }
        onPrimaryAction?()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.contains(point)
    }
}
