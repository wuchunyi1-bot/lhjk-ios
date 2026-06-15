import UIKit
import SnapKit

/// 隐私保护提示弹窗
/// 参考 funde-client PRD 3.1: 首次打开/协议更新时展示
///
/// 用户同意后才允许进入登录页；不同意则展示不可继续使用状态。
final class PrivacyPromptView: UIView {

    // MARK: - Callbacks

    var onAgree: (() -> Void)?
    var onDisagree: (() -> Void)?
    var onUserAgreementTap: (() -> Void)?
    var onPrivacyPolicyTap: (() -> Void)?
    var onRetry: (() -> Void)?
    var onExitApp: (() -> Void)?

    // MARK: - UI Elements

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "隐私保护提示"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .fdText
        label.textAlignment = .center
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "为了更好地为您提供健康管理服务，我们将按照《用户协议》与《隐私政策》收集和使用您的个人信息。"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .fdSubtext
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let linksStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        return stack
    }()

    private lazy var userAgreementButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("《用户协议》", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13)
        btn.setTitleColor(.fdPrimary, for: .normal)
        btn.addTarget(self, action: #selector(tapUserAgreement), for: .touchUpInside)
        return btn
    }()

    private lazy var privacyPolicyButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("《隐私政策》", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13)
        btn.setTitleColor(.fdPrimary, for: .normal)
        btn.addTarget(self, action: #selector(tapPrivacyPolicy), for: .touchUpInside)
        return btn
    }()

    private let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    private lazy var agreeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("同意", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .fdPrimary
        btn.layer.cornerRadius = 18
        btn.addTarget(self, action: #selector(tapAgree), for: .touchUpInside)
        return btn
    }()

    private lazy var disagreeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("不同意", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(.fdSubtext, for: .normal)
        btn.addTarget(self, action: #selector(tapDisagree), for: .touchUpInside)
        return btn
    }()

    // MARK: - Unavailable State

    private let unavailableView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private let unavailableIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "exclamationmark.shield.fill"))
        iv.tintColor = .fdMuted
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let unavailableLabel: UILabel = {
        let label = UILabel()
        label.text = "未同意隐私政策，暂无法使用富德健康"
        label.font = .systemFont(ofSize: 15)
        label.textColor = .fdSubtext
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var retryButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("重新查看并同意", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .fdPrimary
        btn.layer.cornerRadius = 14
        btn.addTarget(self, action: #selector(tapRetry), for: .touchUpInside)
        return btn
    }()

    private lazy var exitButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("退出 App", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(.fdSubtext, for: .normal)
        btn.addTarget(self, action: #selector(tapExitApp), for: .touchUpInside)
        return btn
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.45)

        addSubview(containerView)

        // Consent content
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(linksStack)
        linksStack.addArrangedSubview(userAgreementButton)
        linksStack.addArrangedSubview(privacyPolicyButton)
        containerView.addSubview(buttonStack)
        buttonStack.addArrangedSubview(agreeButton)
        buttonStack.addArrangedSubview(disagreeButton)

        // Unavailable state
        containerView.addSubview(unavailableView)
        unavailableView.addSubview(unavailableIcon)
        unavailableView.addSubview(unavailableLabel)
        unavailableView.addSubview(retryButton)
        unavailableView.addSubview(exitButton)

        // Layout
        containerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        linksStack.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }

        buttonStack.snp.makeConstraints { make in
            make.top.equalTo(linksStack.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-28)
        }

        agreeButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }

        // Unavailable state layout (overlays the consent content)
        unavailableView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-40)
        }

        unavailableIcon.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(56)
        }

        unavailableLabel.snp.makeConstraints { make in
            make.top.equalTo(unavailableIcon.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
        }

        retryButton.snp.makeConstraints { make in
            make.top.equalTo(unavailableLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }

        exitButton.snp.makeConstraints { make in
            make.top.equalTo(retryButton.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - Actions

    @objc private func tapAgree() {
        onAgree?()
    }

    @objc private func tapDisagree() {
        showUnavailableState()
        onDisagree?()
    }

    @objc private func tapUserAgreement() {
        onUserAgreementTap?()
    }

    @objc private func tapPrivacyPolicy() {
        onPrivacyPolicyTap?()
    }

    @objc private func tapRetry() {
        hideUnavailableState()
        onRetry?()
    }

    @objc private func tapExitApp() {
        onExitApp?()
    }

    // MARK: - State

    private func showUnavailableState() {
        titleLabel.isHidden = true
        descriptionLabel.isHidden = true
        linksStack.isHidden = true
        buttonStack.isHidden = true
        unavailableView.isHidden = false
    }

    private func hideUnavailableState() {
        titleLabel.isHidden = false
        descriptionLabel.isHidden = false
        linksStack.isHidden = false
        buttonStack.isHidden = false
        unavailableView.isHidden = true
    }

    /// 更新提示文案（用于协议版本更新场景）
    func updateDescription(_ text: String) {
        descriptionLabel.text = text
    }
}
