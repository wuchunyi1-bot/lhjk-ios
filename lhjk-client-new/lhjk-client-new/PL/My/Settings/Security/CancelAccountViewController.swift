import UIKit
import SnapKit
import Combine

/// 注销账号 — 对齐 Figma 4457:12851
final class CancelAccountViewController: BaseViewController {

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let contentTopInset: CGFloat = 12
        static let submitButtonHeight: CGFloat = 40
        static let submitButtonBorderWidth: CGFloat = 0.5
        static let bottomBarOffset: CGFloat = 24
    }

    // MARK: - ViewModel

    private let viewModel = CancelAccountViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Data

    private let cancelItems: [(title: String, desc: String)] = [
        ("账户信息", "身份信息、账户信息、会员积分等将被清空。且无法恢复"),
        ("服务权益", "您购买的服务将全部失效(包括活动积分、卡券、服务、未激活的权益等）将全部清空。"),
        ("交易记录", "交易记录将被清空，请确保所有交易已完结且无纠纷，注销后，历史订单可能产生的退款资金退回权益将视为自动放弃。"),
        ("服务记录", "与三好服务团队的交流记录将被清空，无法恢复。"),
        ("健康数据", "各项身体数据将被清空，无法恢复。"),
    ]

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let noticeStackView = UIStackView()
    private let bottomBar = UIView()

    private let submitBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("申请注销", for: .normal)
        btn.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        btn.setTitleColor(.fdPrimary, for: .normal)
        btn.backgroundColor = .clear
        btn.layer.cornerRadius = Layout.submitButtonHeight / 2
        btn.layer.borderWidth = Layout.submitButtonBorderWidth
        btn.layer.borderColor = UIColor.fdPrimary.cgColor
        return btn
    }()

    private let resultContainer = UIView()

    // MARK: - Lifecycle

    override func setupUI() {
        title = "注销账号"
        view.backgroundColor = .fdBg

        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-Layout.bottomBarOffset)
        }

        submitBtn.addTarget(self, action: #selector(handleCancelAccount), for: .touchUpInside)
        bottomBar.addSubview(submitBtn)
        submitBtn.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(Layout.submitButtonHeight)
        }

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top).offset(-16)
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }

        noticeStackView.axis = .vertical
        noticeStackView.spacing = 0
        contentView.addSubview(noticeStackView)
        noticeStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.contentTopInset)
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.bottom.equalToSuperview().offset(-12)
        }

        noticeStackView.addArrangedSubview(CancelAccountWarningBannerView())
        noticeStackView.addArrangedSubview(CancelAccountImpactListView(items: cancelItems))

        setupResultStep()
    }

    private func setupResultStep() {
        resultContainer.isHidden = true
        view.addSubview(resultContainer)
        resultContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        let checkIcon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkIcon.tintColor = .fdSuccess
        checkIcon.contentMode = .scaleAspectFit
        resultContainer.addSubview(checkIcon)
        checkIcon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(100)
            make.size.equalTo(64)
        }

        let resultTitle = UILabel()
        resultTitle.text = "注销成功"
        resultTitle.font = .fdMyH2
        resultTitle.textColor = .fdText
        resultTitle.textAlignment = .center
        resultContainer.addSubview(resultTitle)
        resultTitle.snp.makeConstraints { make in
            make.top.equalTo(checkIcon.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }

        let resultDesc = UILabel()
        resultDesc.text = "您的账户已成功注销，即将跳转至注册页面。"
        resultDesc.font = .fdMyBody
        resultDesc.textColor = .fdSubtext
        resultDesc.textAlignment = .center
        resultDesc.numberOfLines = 0
        resultContainer.addSubview(resultDesc)
        resultDesc.snp.makeConstraints { make in
            make.top.equalTo(resultTitle.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(24)
        }
    }

    // MARK: - Binding

    override func bindViewModel() {
        viewModel.$isSubmitting
            .receive(on: DispatchQueue.main)
            .sink { [weak self] submitting in
                self?.submitBtn.isEnabled = !submitting
                self?.submitBtn.setTitle(submitting ? "处理中..." : "申请注销", for: .normal)
                self?.submitBtn.alpha = submitting ? 0.6 : 1.0
            }
            .store(in: &cancellables)

        viewModel.$isSuccess
            .receive(on: DispatchQueue.main)
            .sink { [weak self] success in
                guard success, let self else { return }
                self.scrollView.isHidden = true
                self.bottomBar.isHidden = true
                self.resultContainer.isHidden = false
                self.title = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    Router.shared.setRoot("/login")
                }
            }
            .store(in: &cancellables)

        viewModel.toastPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                self?.showToastAlert(msg, duration: 1.5)
            }
            .store(in: &cancellables)
    }

    // MARK: - Cancel Flow

    @objc private func handleCancelAccount() {
        guard !viewModel.isSubmitting else { return }

        if viewModel.hasUnfinishedOrders() {
            showUnfinishedOrdersAlert()
        } else {
            showCancelConfirmation()
        }
    }

    private func showUnfinishedOrdersAlert() {
        let alert = UIAlertController(
            title: "暂无法注销账户",
            message: "您当前还有未完成的订单或服务，请处理完成后再申请注销。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "我知道了", style: .cancel))
        alert.addAction(UIAlertAction(title: "查看订单", style: .default) { _ in
            Router.shared.push("/orders")
        })
        present(alert, animated: true)
    }

    private func showCancelConfirmation() {
        let alert = UIAlertController(
            title: "注销确认",
            message: "注销后您将失去本账户的所有信息，请谨慎操作",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定注销", style: .destructive) { [weak self] _ in
            self?.viewModel.cancelAccount()
        })
        present(alert, animated: true)
    }
}
