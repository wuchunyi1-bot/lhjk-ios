import UIKit
import SnapKit
import Combine

/// 确认订单页 — 对齐 Figma 3566:7135
final class OrderConfirmViewController: BaseViewController {

    private let viewModel: OrderConfirmViewModel
    private let entry: OrderConfirmEntry
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private let fulfillmentCard = OrderConfirmCardView()
    private let fulfillmentView = OrderConfirmFulfillmentView()
    private let addressCard = OrderConfirmCardView()
    private let addressView = OrderConfirmAddressView()
    private let pickupCard = OrderConfirmCardView()
    private let pickupView = OrderConfirmPickupView()
    private let packageCard = OrderConfirmCardView()
    private let packageView = OrderConfirmPackageView()
    private let optionsCard = OrderConfirmOptionsCardView()
    private let feeView = OrderConfirmFeeView()
    private let payMethodView = OrderConfirmPayMethodView()
    private let statusView = OrderDetailStatusView()
    private let infoCard = OrderDetailCardView()
    private let infoView = OrderDetailInfoView()
    private let scrollActionBar = OrderDetailActionBar(style: .scrollInline)
    private let submitBar = OrderConfirmSubmitBar()

    private var showsOrderListPayPresentation: Bool { entry == .orderListPay }

    init(orderId: Int64, serialNumber: Int? = nil, entry: OrderConfirmEntry = .default) {
        self.entry = entry
        self.viewModel = OrderConfirmViewModel(orderId: orderId, serialNumber: serialNumber, entry: entry)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        if entry == .cartCheckout {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if entry == .cartCheckout {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }

    override func setupUI() {
        title = showsOrderListPayPresentation ? "订单详情" : "确认订单"
        view.backgroundColor = UIColor(hexString: "#FDF6F3")

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        view.addSubview(submitBar)
        view.addSubview(loadingIndicator)

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.isLayoutMarginsRelativeArrangement = true
        let topInset: CGFloat = showsOrderListPayPresentation ? 0 : 12
        contentStack.layoutMargins = UIEdgeInsets(top: topInset, left: 16, bottom: 24, right: 16)
        scrollView.addSubview(contentStack)

        fulfillmentCard.addSubview(fulfillmentView)
        fulfillmentView.snp.makeConstraints { $0.edges.equalToSuperview() }
        addressCard.addSubview(addressView)
        addressView.snp.makeConstraints { $0.edges.equalToSuperview() }
        pickupCard.addSubview(pickupView)
        pickupView.snp.makeConstraints { $0.edges.equalToSuperview() }
        packageCard.addSubview(packageView)
        packageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        infoCard.addSubview(infoView)
        infoView.snp.makeConstraints { $0.edges.equalToSuperview() }
        infoView.onOrderNumberCopied = { [weak self] in
            self?.showToast("订单号已复制")
        }

        var sections: [UIView] = []
        if showsOrderListPayPresentation {
            sections.append(statusView)
        }
        sections += [
            fulfillmentCard,
            addressCard,
            pickupCard,
            packageCard,
            optionsCard,
            feeView,
            payMethodView,
        ]
        if showsOrderListPayPresentation {
            sections.append(infoCard)
            sections.append(scrollActionBar)
        }
        sections.forEach { contentStack.addArrangedSubview($0) }

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
        pickupView.onCall = { [weak self] in
            self?.callInstitution()
        }
        packageView.onToggleContent = { [weak self] in
            guard let self else { return }
            self.viewModel.contentExpanded.toggle()
        }
        optionsCard.onTapRemark = { [weak self] in
            self?.tapRemark()
        }
        optionsCard.onTapCoupon = { [weak self] in
            self?.tapCoupon()
        }
        optionsCard.onTapBenefit = { [weak self] in
            self?.tapBenefit()
        }
        payMethodView.onSelect = { [weak self] method in
            self?.viewModel.payMethod = method
        }
        submitBar.onPay = { [weak self] in
            self?.viewModel.submitPay()
        }
        submitBar.onCancel = { [weak self] in
            self?.handlePendingPaymentCancel()
        }
        scrollActionBar.onAction = { [weak self] action in
            guard action == .cancel else { return }
            self?.handlePendingPaymentCancel()
        }

        setupCartCheckoutNavigationIfNeeded()
    }

    private func setupCartCheckoutNavigationIfNeeded() {
        guard entry == .cartCheckout else { return }
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: .fdNavBack,
            style: .plain,
            target: self,
            action: #selector(handleCartCheckoutBack)
        )
    }

    @objc private func handleCartCheckoutBack() {
        OrderNavigationCoordinator.navigateToMyOrdersAll(from: self)
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

        viewModel.$orderDetail
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)

        viewModel.$payMethod
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)

        viewModel.$remark
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
                guard let self else { return }
                self.viewModel.consumeNavigationFlags()
                if self.entry == .cartCheckout {
                    OrderNavigationCoordinator.navigateToMyOrdersAll(from: self)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }
            .store(in: &cancellables)

        viewModel.$payResult
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payload in
                guard let self else { return }
                self.viewModel.consumePayResult()
                self.pushPayResult(payload)
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

        let showExpress = viewModel.needsExpressAddress
        let showPickup = viewModel.needsPickupInfo
        addressCard.isHidden = !showExpress
        pickupCard.isHidden = !showPickup
        if showExpress {
            addressView.configureExpress(address: viewModel.selectedAddress)
        }
        if showPickup {
            pickupView.configure(
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

        optionsCard.configureRemark(text: viewModel.remark)
        optionsCard.configureCoupon(
            text: viewModel.couponSummaryText,
            isPlaceholder: viewModel.couponSummaryIsPlaceholder,
            hasAvailable: viewModel.availableCouponCount > 0 || viewModel.couponDiscount > 0
        )
        optionsCard.configureBenefit(
            text: viewModel.benefitSummaryText,
            isPlaceholder: viewModel.benefitSummaryIsPlaceholder,
            hasDiscount: viewModel.benefitDiscount > 0
        )

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
        submitBar.configure(
            amount: viewModel.payableAmount,
            submitting: viewModel.isSubmitting,
            showsCancel: false,
            payTitle: showsOrderListPayPresentation ? "去支付" : nil
        )

        if showsOrderListPayPresentation {
            scrollActionBar.configure(actions: [.cancel])
        } else {
            scrollActionBar.configure(actions: [])
        }

        if showsOrderListPayPresentation {
            statusView.configure(
                presentation: .make(
                    status: .pendingPayment,
                    title: AppOrderStatus.pendingPayment.label,
                    preferPrimaryForPending: true
                )
            )
            infoCard.isHidden = viewModel.orderDetail == nil
            if let detail = viewModel.orderDetail {
                infoView.configure(
                    detail: detail,
                    remarkOverride: viewModel.remark,
                    expandedRows: [("支付状态", "待支付")],
                    showsExpandToggle: true
                )
            }
        }
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
        Task { [weak self] in
            guard let self else { return }
            do {
                let coupons = try await self.viewModel.fetchCouponOptions()
                await MainActor.run {
                    let sheet = OrderCouponPickerSheet(
                        coupons: coupons,
                        selectedTakeId: self.viewModel.selectedCouponTakeId
                    )
                    sheet.onSelect = { [weak self] takeId in
                        self?.viewModel.bindCoupon(takeId: takeId)
                    }
                    self.present(sheet, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.showToast(error.localizedDescription.isEmpty
                        ? "查询优惠券失败"
                        : error.localizedDescription)
                }
            }
        }
    }

    @objc private func tapBenefit() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let cards = try await self.viewModel.fetchBenefitOptions()
                await MainActor.run {
                    let sheet = OrderBenefitPickerSheet(
                        cards: cards,
                        selectedIds: self.viewModel.selectedBenefitIds,
                        cardLimit: self.viewModel.benefitCardLimit
                    )
                    sheet.onConfirm = { [weak self] ids in
                        self?.viewModel.applyBenefitSelection(ids: ids)
                    }
                    self.present(sheet, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.showToast(error.localizedDescription.isEmpty
                        ? "查询权益卡失败"
                        : error.localizedDescription)
                }
            }
        }
    }

    private func handlePendingPaymentCancel() {
        guard showsOrderListPayPresentation else { return }
        let onSuccess: (OrderCancelFlow.Result) -> Void = { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
        if let detail = viewModel.orderDetail {
            OrderCancelFlow.start(from: self, detail: detail, onSuccess: onSuccess)
            return
        }
        OrderCancelFlow.startPendingPaymentCancel(
            from: self,
            orderId: viewModel.currentOrderId,
            hospitalId: nil,
            onSuccess: onSuccess
        )
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

    private func pushPayResult(_ payload: OrderPayResultPayload) {
        OrderNavigationCoordinator.presentPayResultOnMyOrders(from: self, payload: payload)
    }

    private func showToast(_ message: String, completion: (() -> Void)? = nil) {
        showToastAlert(message, duration: 1.2, completion: completion)
    }
}
