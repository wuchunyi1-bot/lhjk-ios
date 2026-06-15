import UIKit
import SnapKit

/// 推送通知权限预引导弹窗
/// 参考 funde-client PRD 3.7: 登录成功后先展示预引导，再请求系统权限
///
/// 用户点击"去开启"后调用系统权限；"暂不开启"则跳过，均不阻塞进入首页。
final class NotificationGuideView: UIView {

    // MARK: - Callbacks

    var onEnable: (() -> Void)?
    var onSkip: (() -> Void)?

    // MARK: - UI

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        return view
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "bell.badge.fill"))
        iv.tintColor = .fdPrimary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "开启通知，及时获取健康提醒和保单服务动态。"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .fdText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "我们会提醒您查看健康服务进度、重要通知和账号安全提醒。"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .fdSubtext
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    private lazy var enableButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("去开启", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .fdPrimary
        btn.layer.cornerRadius = 18
        btn.addTarget(self, action: #selector(tapEnable), for: .touchUpInside)
        return btn
    }()

    private lazy var skipButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("暂不开启", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(.fdSubtext, for: .normal)
        btn.addTarget(self, action: #selector(tapSkip), for: .touchUpInside)
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
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(buttonStack)
        buttonStack.addArrangedSubview(enableButton)
        buttonStack.addArrangedSubview(skipButton)

        containerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }

        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.centerX.equalToSuperview()
            make.size.equalTo(56)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        buttonStack.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-28)
        }

        enableButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
    }

    // MARK: - Actions

    @objc private func tapEnable() {
        onEnable?()
    }

    @objc private func tapSkip() {
        onSkip?()
    }
}
