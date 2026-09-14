import UIKit
import SnapKit

/// 微信绑定手机号弹层
/// 对齐 Figma `5574:18136`：微信登录成功但未绑定手机号时的「底部滑出抽屉（Bottom Sheet）」。
final class PhoneBindingView: UIView {

    // MARK: - Mode

    enum Mode {
        case bind
        case rebind(maskedPhone: String)
    }

    // MARK: - Callbacks

    var onSubmit: ((_ phone: String, _ code: String) -> Void)?
    var onDismiss: (() -> Void)?
    var onContactSupport: (() -> Void)?
    /// 真实发码；抛错时不开始倒计时
    var onRequestSMSCode: ((_ phone: String) async throws -> Void)?

    // MARK: - UI Elements

    /// 半透明黑色遮罩背景
    private let dimView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        return view
    }()

    /// 底部白色面板容器
    private let sheetView: UIView = {
        let view = UIView()
        view.backgroundColor = .fdSurface
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()

    /// 顶部背景插画（Figma 5574:18136）
    private let headerBackgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "login_binding_header_bg")
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = false
        return iv
    }()

    /// 右上角关闭按钮
    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let img = UIImage(systemName: "xmark", withConfiguration: config)
        btn.setImage(img, for: .normal)
        btn.tintColor = .fdMuted
        btn.accessibilityLabel = "关闭"
        btn.addTarget(self, action: #selector(tapDismiss), for: .touchUpInside)
        return btn
    }()

    /// 主标题
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 20, weight: .semibold)
        label.textColor = .fdText
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    /// 副说明文本
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .fdLoginMeta
        label.textColor = .fdSubtext
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    /// 手机号输入框（无图标、带浅色细边框、标签在上）
    private lazy var phoneField = LoginFieldView(
        title: "手机号",
        placeholder: "请输入手机号",
        sfSymbol: "phone",
        showsIdleBorder: true,
        showsIcon: false
    )

    /// 验证码输入框（无图标、带浅色细边框、内嵌获取验证码）
    private lazy var codeField = LoginFieldView(
        title: "验证码",
        placeholder: "请输入验证码",
        sfSymbol: "shield",
        showsIdleBorder: true,
        showsIcon: false
    )

    /// 内嵌式验证码倒计时按钮（橙色文本）
    private lazy var codeButton: VerifyCodeButton = {
        let btn = VerifyCodeButton(style: .inline)
        btn.onRequestCode = { [weak self] in
            self?.handleRequestCode()
        }
        return btn
    }()

    /// 提交主按钮（渐变橙色胶囊）
    private lazy var submitButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .fdLoginButton
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 25.5
        btn.layer.borderWidth = 0.5
        btn.layer.borderColor = UIColor.fdLoginButtonEnd.cgColor
        btn.clipsToBounds = true
        btn.addTarget(self, action: #selector(tapSubmit), for: .touchUpInside)
        return btn
    }()

    private let submitGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.fdLoginButtonStart.cgColor,
            UIColor.fdLoginButtonEnd.cgColor,
        ]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        return layer
    }()

    /// 换绑模式下的客服解绑选项
    private lazy var contactSupportButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("联系客服解绑", for: .normal)
        btn.titleLabel?.font = .fdLoginMeta
        btn.setTitleColor(.fdPrimary, for: .normal)
        btn.addTarget(self, action: #selector(tapContactSupport), for: .touchUpInside)
        return btn
    }()

    // MARK: - State & Constraints

    private let mode: Mode
    private var isSubmitting = false
    private var sheetBottomConstraint: Constraint?
    private var isShowingAnimated = false

    // MARK: - Init

    init(mode: Mode = .bind) {
        self.mode = mode
        super.init(frame: .zero)
        setupUI()
        configureForMode()
        registerKeyboard()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        submitGradientLayer.frame = submitButton.bounds
        submitGradientLayer.cornerRadius = submitButton.layer.cornerRadius
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear

        // 遮罩点击：收起键盘；若无键盘则关闭弹层
        let dimTap = UITapGestureRecognizer(target: self, action: #selector(tapDimView))
        dimView.addGestureRecognizer(dimTap)
        addSubview(dimView)
        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 底部白卡面板
        addSubview(sheetView)
        sheetView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            sheetBottomConstraint = make.bottom.equalToSuperview().constraint
        }

        // 面板子视图
        sheetView.addSubview(headerBackgroundImageView)
        sheetView.addSubview(titleLabel)
        sheetView.addSubview(closeButton)
        sheetView.addSubview(descriptionLabel)
        sheetView.addSubview(phoneField)
        sheetView.addSubview(codeField)
        sheetView.addSubview(submitButton)
        submitButton.layer.insertSublayer(submitGradientLayer, at: 0)

        // 验证码内嵌按钮挂载
        codeField.trailingAccessoryView = codeButton

        // 键盘配置
        phoneField.textField.keyboardType = .phonePad
        phoneField.textField.textContentType = .telephoneNumber
        phoneField.attachDoneToolbarIfNeeded()
        codeField.textField.keyboardType = .numberPad
        codeField.textField.textContentType = .oneTimeCode
        codeField.attachDoneToolbarIfNeeded()

        phoneField.onReturnKey = { [weak self] in
            self?.codeField.textField.becomeFirstResponder()
            return true
        }
        codeField.onReturnKey = { [weak self] in
            self?.endEditing(true)
            return true
        }

        // 约束
        headerBackgroundImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(headerBackgroundImageView.snp.width).multipliedBy(108.0 / 375.0)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-16)
            make.size.equalTo(36)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalTo(closeButton.snp.leading).offset(-10)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        phoneField.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        codeField.snp.makeConstraints { make in
            make.top.equalTo(phoneField.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        submitButton.snp.makeConstraints { make in
            make.top.equalTo(codeField.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(51)
            make.bottom.equalTo(sheetView.safeAreaLayoutGuide.snp.bottom).offset(-24)
        }
    }

    private func configureForMode() {
        switch mode {
        case .bind:
            titleLabel.text = "请绑定手机号后继续使用"
            descriptionLabel.text = "微信授权成功，需绑定手机号以完成登录"
            submitButton.setTitle("绑定并登录", for: .normal)

        case .rebind(let maskedPhone):
            titleLabel.text = "该手机号已绑定其他微信号"
            descriptionLabel.text = "手机号 \(maskedPhone) 已绑定其他微信号。如需换绑至当前微信，请通过手机号验证码验证。"
            submitButton.setTitle("验证并换绑", for: .normal)

            sheetView.addSubview(contactSupportButton)
            submitButton.snp.remakeConstraints { make in
                make.top.equalTo(codeField.snp.bottom).offset(30)
                make.leading.trailing.equalToSuperview().inset(24)
                make.height.equalTo(51)
            }
            contactSupportButton.snp.makeConstraints { make in
                make.top.equalTo(submitButton.snp.bottom).offset(12)
                make.centerX.equalToSuperview()
                make.bottom.equalTo(sheetView.safeAreaLayoutGuide.snp.bottom).offset(-20)
            }
        }
    }

    // MARK: - Bottom Sheet Animations

    /// 从底部滑入动画
    func showAnimated() {
        guard !isShowingAnimated else { return }
        isShowingAnimated = true

        dimView.alpha = 0
        sheetView.transform = CGAffineTransform(translationX: 0, y: 700)
        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                self.dimView.alpha = 1
                self.sheetView.transform = .identity
            },
            completion: nil
        )
    }

    /// 向下滑出关闭动画
    func dismissAnimated(completion: (() -> Void)? = nil) {
        endEditing(true)
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                self.dimView.alpha = 0
                self.sheetView.transform = CGAffineTransform(translationX: 0, y: self.sheetView.bounds.height + 40)
            },
            completion: { _ in
                self.removeFromSuperview()
                completion?()
            }
        )
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil && !isShowingAnimated {
            showAnimated()
        }
    }

    // MARK: - Keyboard Handling

    private func registerKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let keyboardInView = convert(endFrame, from: nil)
        let overlap = max(0, bounds.maxY - keyboardInView.minY)
        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt) ?? 0
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)

        // 键盘升起时向上避让
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.sheetBottomConstraint?.update(offset: -overlap)
            self.layoutIfNeeded()
        }
    }

    // MARK: - Actions

    @objc private func tapDimView() {
        // 若有正在编辑的输入框，先收起键盘
        if phoneField.textField.isFirstResponder || codeField.textField.isFirstResponder {
            endEditing(true)
            return
        }
        tapDismiss()
    }

    @objc private func tapDismiss() {
        endEditing(true)
        onDismiss?()
    }

    @objc private func tapContactSupport() {
        onContactSupport?()
    }

    private func handleRequestCode() {
        let phone = phoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard validatePhone(phone) else { return }

        guard let onRequestSMSCode else {
            codeButton.startCountdown()
            showBriefToast("验证码已发送")
            return
        }

        codeButton.isEnabled = false
        Task {
            do {
                try await onRequestSMSCode(phone)
                await MainActor.run {
                    codeButton.isEnabled = true
                    codeButton.startCountdown()
                    showBriefToast("验证码已发送")
                }
            } catch {
                await MainActor.run {
                    codeButton.isEnabled = true
                    showBriefToast(error.localizedDescription)
                }
            }
        }
    }

    @objc private func tapSubmit() {
        guard !isSubmitting else { return }

        let phone = phoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let code = codeField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        guard !phone.isEmpty else { showBriefToast("请输入手机号"); return }
        guard validatePhone(phone) else { return }
        guard !code.isEmpty else { showBriefToast("请输入验证码"); return }

        isSubmitting = true
        submitButton.isEnabled = false
        submitButton.alpha = 0.72

        onSubmit?(phone, code)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self, self.superview != nil else { return }
            self.resetSubmitState()
        }
    }

    // MARK: - Validation

    private func validatePhone(_ phone: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              regex.firstMatch(in: phone, range: NSRange(phone.startIndex..., in: phone)) != nil else {
            showBriefToast("请输入正确的手机号")
            return false
        }
        return true
    }

    // MARK: - Helpers

    func resetSubmitState() {
        isSubmitting = false
        submitButton.isEnabled = true
        submitButton.alpha = 1.0
    }

    private func showBriefToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            topVC.present(alert, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                alert.dismiss(animated: true)
            }
        }
    }
}
