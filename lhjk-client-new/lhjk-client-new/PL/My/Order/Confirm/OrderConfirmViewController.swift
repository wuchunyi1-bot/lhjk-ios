import UIKit
import SnapKit
import Combine

/// 确认订单页 — 对齐 funde OrderConfirmView / PRD-605
final class OrderConfirmViewController: BaseViewController {

    private let viewModel: OrderConfirmViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private let fulfillmentCard = OrderConfirmCardView()
    private let fulfillmentView = OrderConfirmFulfillmentView()
    private let addressCard = OrderConfirmCardView()
    private let addressView = OrderConfirmAddressView()
    private let packageCard = OrderConfirmCardView()
    private let packageView = OrderConfirmPackageView()
    private let remarkRow = OrderConfirmSelectRow()
    private let couponRow = OrderConfirmSelectRow()
    private let benefitRow = OrderConfirmSelectRow()
    private let feeView = OrderConfirmFeeView()
    private let payMethodView = OrderConfirmPayMethodView()
    private let submitBar = OrderConfirmSubmitBar()

    init(orderId: Int64, serialNumber: Int? = nil) {
        self.viewModel = OrderConfirmViewModel(orderId: orderId, serialNumber: serialNumber)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = "确认订单"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        view.addSubview(submitBar)
        view.addSubview(loadingIndicator)

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)
        scrollView.addSubview(contentStack)

        fulfillmentCard.addSubview(fulfillmentView)
        fulfillmentView.snp.makeConstraints { $0.edges.equalToSuperview() }
        addressCard.addSubview(addressView)
        addressView.snp.makeConstraints { $0.edges.equalToSuperview() }
        packageCard.addSubview(packageView)
        packageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        [
            fulfillmentCard,
            addressCard,
            packageCard,
            remarkRow,
            couponRow,
            benefitRow,
            feeView,
            payMethodView
        ].forEach { contentStack.addArrangedSubview($0) }

        submitBar.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(submitBar.snp.top)
        }
        contentStack.snp.makeConstraints {
            $0.edges.width.equalToSuperview()
        }
        loadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }
        loadingIndicator.color = .fdPrimary
        loadingIndicator.hidesWhenStopped = true

        fulfillmentView.onSelect = { [weak self] method in
            self?.viewModel.selectFulfillment(method)
        }
        addressView.onTap = { [weak self] in
            self?.pushAddressSelection()
        }
        addressView.onCall = { [weak self] in
            self?.callInstitution()
        }
        packageView.onToggleContent = { [weak self] in
            guard let self else { return }
            self.viewModel.contentExpanded.toggle()
        }
        remarkRow.addTarget(self, action: #selector(tapRemark), for: .touchUpInside)
        couponRow.addTarget(self, action: #selector(tapCoupon), for: .touchUpInside)
        benefitRow.addTarget(self, action: #selector(tapBenefit), for: .touchUpInside)
        payMethodView.onSelect = { [weak self] method in
            self?.viewModel.payMethod = method
        }
        submitBar.onPay = { [weak self] in
            self?.viewModel.submitPay()
        }
    }

    override func bindViewModel() {
        viewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.render()
            }
            .store(in: &cancellables)

        // 首次与异步完成后也刷一次
        viewModel.$draft
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)

        viewModel.$fulfillment
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)

        viewModel.$supportsExpress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)

        viewModel.$hospitalDetail
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)

        viewModel.$toastMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showToast(message) {
                    self?.viewModel.consumeToast()
                }
            }
            .store(in: &cancellables)

        viewModel.$navigateBack
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.viewModel.consumeNavigationFlags()
                self?.navigationController?.popViewController(animated: true)
            }
            .store(in: &cancellables)

        viewModel.$navigateToOrders
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.viewModel.consumeNavigationFlags()
                self?.replaceWithOrders()
            }
            .store(in: &cancellables)

        viewModel.load()
        render()
    }

    // MARK: - Render

    private func render() {
        if viewModel.isLoading {
            loadingIndicator.startAnimating()
            scrollView.isHidden = true
            submitBar.isHidden = true
            return
        }
        loadingIndicator.stopAnimating()
        scrollView.isHidden = false
        submitBar.isHidden = viewModel.draft == nil

        guard let draft = viewModel.draft else { return }

        fulfillmentCard.isHidden = !viewModel.showsFulfillment
        if viewModel.showsFulfillment {
            fulfillmentView.configure(
                selected: viewModel.fulfillment,
                supportsExpress: viewModel.supportsExpress
            )
        }

        let showAddress = viewModel.needsExpressAddress || viewModel.needsPickupInfo
        addressCard.isHidden = !showAddress
        if viewModel.needsExpressAddress {
            addressView.configureExpress(address: viewModel.selectedAddress)
        } else if viewModel.needsPickupInfo {
            addressView.configurePickup(
                name: viewModel.pickupName,
                address: viewModel.pickupAddress,
                showCall: !viewModel.institutionPhone.isEmpty
            )
        }

        packageView.configure(
            name: draft.packageName,
            subtitle: draft.subtitle,
            amount: viewModel.packageAmount,
            items: viewModel.visibleContentItems,
            canExpand: viewModel.canExpandContent,
            expanded: viewModel.contentExpanded,
            totalCount: draft.selectedItems.count
        )

        let remarkText = viewModel.remark.trimmingCharacters(in: .whitespacesAndNewlines)
        remarkRow.configure(
            title: "订单备注",
            value: remarkText.isEmpty ? "选填" : remarkText,
            placeholder: remarkText.isEmpty
        )
        couponRow.configure(title: "优惠券", value: "暂无可用", placeholder: true)
        benefitRow.configure(title: "权益卡", value: "暂无可用", placeholder: true)

        feeView.configure(
            packageAmount: viewModel.packageAmount,
            shipping: viewModel.shippingFee,
            coupon: viewModel.couponDiscount,
            benefit: viewModel.benefitDiscount,
            payable: viewModel.payableAmount
        )
        payMethodView.configure(
            selected: viewModel.payMethod,
            supportsWechat: viewModel.supportsWechat,
            supportsAlipay: viewModel.supportsAlipay
        )
        submitBar.configure(amount: viewModel.payableAmount, submitting: viewModel.isSubmitting)
    }

    // MARK: - Actions

    @objc private func tapRemark() {
        let sheet = OrderRemarkEditorSheet(current: viewModel.remark)
        sheet.onSave = { [weak self] text in
            self?.viewModel.updateRemark(text)
        }
        present(sheet, animated: true)
    }

    @objc private func tapCoupon() {
        showToast("暂无可用优惠券")
    }

    @objc private func tapBenefit() {
        showToast("暂无可用权益卡")
    }

    private func callInstitution() {
        let phone = viewModel.institutionPhone.filter { $0.isNumber || $0 == "+" }
        guard !phone.isEmpty,
              let url = URL(string: "tel://\(phone)"),
              UIApplication.shared.canOpenURL(url) else {
            showToast("暂无法拨打服务热线")
            return
        }
        UIApplication.shared.open(url)
    }

    private func pushAddressSelection() {
        let onSelect: (MAddress) -> Void = { [weak self] address in
            self?.viewModel.bindDelivery(address: address)
        }
        Router.shared.push(
            "/me/address",
            params: ["selectMode": true, "onSelect": onSelect],
            from: self
        )
    }

    private func replaceWithOrders() {
        guard let nav = navigationController else {
            Router.shared.push("/orders", from: self)
            return
        }
        var stack = nav.viewControllers.filter { !($0 is OrderConfirmViewController) }
        stack.append(OrderListViewController())
        nav.setViewControllers(stack, animated: true)
    }

    private func showToast(_ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            alert.dismiss(animated: true) {
                completion?()
            }
        }
    }
}
