import UIKit
import SnapKit
import Combine

/// 支付结果页 — 对齐 Figma 3506:9196
/// 完成 / 返回均进入订单列表，不得回到确认订单；查看订单跳转订单详情。
final class OrderPayResultViewController: BaseViewController {

    private let viewModel: OrderPayResultViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let heroView = OrderPayResultHeroView()
    private let infoView = OrderPayResultInfoView()

    private let buttonStack = UIStackView()
    private let completeButton = UIButton(type: .system)
    private let viewOrderButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    init(payload: OrderPayResultPayload) {
        self.viewModel = OrderPayResultViewModel(payload: payload)
        super.init(nibName: nil, bundle: nil)
    }

    init(viewModel: OrderPayResultViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func setupUI() {
        title = "支付结果"
        view.backgroundColor = .fdBg

        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: .fdNavBack,
            style: .plain,
            target: self,
            action: #selector(leaveToOrderList)
        )

        // 左按钮：完成（白底橙框橙字，胶囊）
        completeButton.setTitle("完成", for: .normal)
        completeButton.titleLabel?.font = .fdFont(ofSize: 15, weight: .medium)
        completeButton.setTitleColor(.fdPrimary, for: .normal)
        completeButton.backgroundColor = .white
        completeButton.layer.cornerRadius = 20
        completeButton.layer.borderWidth = 1
        completeButton.layer.borderColor = UIColor.fdPrimary.cgColor
        completeButton.clipsToBounds = true
        completeButton.addTarget(self, action: #selector(leaveToOrderList), for: .touchUpInside)

        // 右按钮：查看订单（实心橙底白字，胶囊）
        viewOrderButton.setTitle("查看订单", for: .normal)
        viewOrderButton.titleLabel?.font = .fdFont(ofSize: 15, weight: .medium)
        viewOrderButton.setTitleColor(.white, for: .normal)
        viewOrderButton.backgroundColor = .fdPrimary
        viewOrderButton.layer.cornerRadius = 20
        viewOrderButton.clipsToBounds = true
        viewOrderButton.addTarget(self, action: #selector(viewOrderDetail), for: .touchUpInside)

        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 10
        buttonStack.alignment = .fill
        buttonStack.addArrangedSubview(completeButton)
        buttonStack.addArrangedSubview(viewOrderButton)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        view.addSubview(buttonStack)
        view.addSubview(loadingIndicator)

        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .fill
        scrollView.addSubview(contentStack)
        contentStack.addArrangedSubview(heroView)
        contentStack.addArrangedSubview(infoView)

        infoView.onOrderNumberCopied = { [weak self] in
            self?.viewModel.copyOrderNumberSucceeded()
        }

        buttonStack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-14)
            $0.height.equalTo(40)
        }
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(buttonStack.snp.top).offset(-12)
        }
        contentStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-16)
            $0.width.equalTo(scrollView).offset(-32)
        }
        loadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    override func bindViewModel() {
        viewModel.$detail
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                guard let self else { return }
                if loading {
                    self.loadingIndicator.startAnimating()
                } else {
                    self.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        viewModel.$toastMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showToastAlert(message, duration: 1.2) {
                    self?.viewModel.consumeToast()
                }
            }
            .store(in: &cancellables)

        viewModel.load()
        render()
    }

    private func render() {
        heroView.configure(payload: viewModel.payload, amountYuan: viewModel.displayAmountYuan)
        let rows = viewModel.infoRows
        infoView.isHidden = rows.isEmpty
        if !rows.isEmpty {
            infoView.configure(rows: rows)
        }
    }

    @objc private func leaveToOrderList() {
        OrderNavigationCoordinator.leavePayResultToOrderList(from: self)
    }

    @objc private func viewOrderDetail() {
        OrderNavigationCoordinator.leavePayResultToOrderDetail(
            from: self,
            orderId: viewModel.payload.orderId
        )
    }
}
