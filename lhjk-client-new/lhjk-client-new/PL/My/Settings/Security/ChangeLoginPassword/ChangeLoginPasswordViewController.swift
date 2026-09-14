import UIKit
import SnapKit
import Combine

/// 登录密码 · 验证当前注册手机号 — 对齐 Figma `4828:11644`
final class ChangeLoginPasswordViewController: BaseViewController {

    private let viewModel: ChangeLoginPasswordViewModel
    private var cancellables = Set<AnyCancellable>()

    private let card = ChangeLoginPasswordCardView()
    private let phoneBox = ChangeLoginPasswordPhoneBoxView()
    private let codeField = ChangeLoginPasswordFieldView(
        title: "验证码",
        placeholder: "请输入验证码",
        iconAssetName: "login_password_code_icon"
    )
    private lazy var codeButton: VerifyCodeButton = {
        let btn = VerifyCodeButton(style: .inline)
        btn.titleLabel?.font = ChangeLoginPasswordStyle.fieldFont
        btn.onRequestCode = { [weak self] in
            self?.viewModel.sendCode()
        }
        return btn
    }()
    private let actionButton = ChangeLoginPasswordActionButton()
    private let bottomBar = UIView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    init(viewModel: ChangeLoginPasswordViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    convenience init() {
        self.init(viewModel: ChangeLoginPasswordViewModel())
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = "登录密码"
        view.backgroundColor = .fdBg
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: .fdNavBack,
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .fdText

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTap)

        actionButton.setTitle("下一步", for: .normal)
        actionButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        view.addSubview(bottomBar)
        bottomBar.addSubview(actionButton)
        actionButton.snp.makeConstraints { $0.edges.equalToSuperview() }
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(ChangeLoginPasswordStyle.buttonInset)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
        }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }

        phoneBox.setPhone(viewModel.maskedPhone)
        codeField.textField.keyboardType = .numberPad
        codeField.textField.textContentType = .oneTimeCode
        codeField.setTrailingAccessory(codeButton)
        codeField.attachDoneToolbarIfNeeded()

        let header = ChangeLoginPasswordHeaderView(
            title: "验证当前注册手机号",
            subtitle: "验证码将发送至当前注册手机号，手机号不可手动修改"
        )
        card.setBodyViews([header, phoneBox, codeField])
        card.bodyStack.setCustomSpacing(ChangeLoginPasswordStyle.headerToBody, after: header)
        card.bodyStack.setCustomSpacing(ChangeLoginPasswordStyle.phoneToCode, after: phoneBox)

        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(ChangeLoginPasswordStyle.screenInset)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    override func bindViewModel() {
        viewModel.$maskedPhone
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in self?.phoneBox.setPhone(text) }
            .store(in: &cancellables)

        viewModel.$isBusy
            .receive(on: DispatchQueue.main)
            .sink { [weak self] busy in
                self?.actionButton.setBusy(busy)
            }
            .store(in: &cancellables)

        viewModel.codeSent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.codeButton.startCountdown() }
            .store(in: &cancellables)

        viewModel.toast
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showToastAlert(message, duration: 1.5)
            }
            .store(in: &cancellables)

        viewModel.didVerify
            .receive(on: DispatchQueue.main)
            .sink { [weak self] code in
                guard let self else { return }
                let setVC = ChangeLoginPasswordSetViewController(
                    viewModel: ChangeLoginPasswordSetViewModel(
                        phone: self.viewModel.phone,
                        smsCode: code
                    )
                )
                self.navigationController?.pushViewController(setVC, animated: true)
            }
            .store(in: &cancellables)
    }

    @objc private func backTapped() {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }

    @objc private func nextTapped() {
        viewModel.verify(code: codeField.textField.text ?? "")
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
