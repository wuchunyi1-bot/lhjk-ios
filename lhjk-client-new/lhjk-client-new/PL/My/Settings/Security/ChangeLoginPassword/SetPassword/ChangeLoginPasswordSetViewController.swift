import UIKit
import SnapKit
import Combine

/// 登录密码 · 设置登录密码 — 对齐 Figma `4828:11665`
final class ChangeLoginPasswordSetViewController: BaseViewController {

    private let viewModel: ChangeLoginPasswordSetViewModel
    private var cancellables = Set<AnyCancellable>()

    private let card = ChangeLoginPasswordCardView()
    private let newPasswordField = ChangeLoginPasswordFieldView(
        title: "新密码",
        placeholder: "请设置新密码",
        usesSecureToggle: true
    )
    private let confirmPasswordField = ChangeLoginPasswordFieldView(
        title: "确认新密码",
        placeholder: "请再次输入新密码",
        usesSecureToggle: true
    )
    private let actionButton = ChangeLoginPasswordActionButton()
    private let bottomBar = UIView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    init(viewModel: ChangeLoginPasswordSetViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
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

        actionButton.setTitle("完成设置", for: .normal)
        actionButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

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

        let header = ChangeLoginPasswordHeaderView(
            title: "设置登录密码",
            subtitle: "密码设置成功后，可退出登录并使用手机号密码登录"
        )
        card.setBodyViews([header, newPasswordField, confirmPasswordField])
        card.bodyStack.setCustomSpacing(ChangeLoginPasswordStyle.headerToBody, after: header)
        card.bodyStack.setCustomSpacing(ChangeLoginPasswordStyle.passwordGroupSpacing, after: newPasswordField)

        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(ChangeLoginPasswordStyle.screenInset)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    override func bindViewModel() {
        viewModel.$isBusy
            .receive(on: DispatchQueue.main)
            .sink { [weak self] busy in self?.actionButton.setBusy(busy) }
            .store(in: &cancellables)

        viewModel.toast
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showToastAlert(message, duration: 1.5)
            }
            .store(in: &cancellables)

        viewModel.didSucceed
            .delay(for: .seconds(1.2), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.popToSecurityCenter()
            }
            .store(in: &cancellables)
    }

    @objc private func backTapped() {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }

    @objc private func submitTapped() {
        view.endEditing(true)
        viewModel.submit(
            newPassword: newPasswordField.textField.text ?? "",
            confirmPassword: confirmPasswordField.textField.text ?? ""
        )
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func popToSecurityCenter() {
        if let security = navigationController?.viewControllers.first(where: { $0 is SecuritySettingsViewController }) {
            navigationController?.popToViewController(security, animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}
