import UIKit
import SnapKit
import Combine

/// 订单详情 — 非待支付订单查看履约、明细与费用
final class OrderDetailViewController: BaseViewController {

    private let viewModel: OrderDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let loadingOverlay = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()

    private let statusView = OrderDetailStatusView()
    private let hintBar = OrderDetailHintBar()
    private let afterSaleCard = OrderDetailCardView()
    private let afterSaleView = OrderDetailAfterSaleView()
    private let packageCard = OrderDetailCardView()
    private let packageView = OrderDetailPackageView()
    private let addressCard = OrderDetailCardView()
    private let addressView = OrderDetailAddressView()
    private let expressLogisticsCard = OrderDetailCardView()
    private let expressLogisticsView = OrderDetailLogisticsView()
    private let pickupLogisticsCard = OrderDetailCardView()
    private let pickupLogisticsView = OrderDetailLogisticsView()
    private let institutionCard = OrderDetailCardView()
    private let institutionView = OrderDetailInstitutionView()
    private let feeCard = OrderDetailCardView()
    private let feeView = OrderDetailFeeView()
    private let infoCard = OrderDetailCardView()
    private let infoView = OrderDetailInfoView()
    private let actionBar = OrderDetailActionBar()
    private var actionBarHeightConstraint: Constraint?

    init(orderId: Int64) {
        self.viewModel = OrderDetailViewModel(orderId: orderId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = "订单详情"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .fdBg
        view.addSubview(scrollView)
        view.addSubview(actionBar)

        loadingOverlay.backgroundColor = UIColor.fdBg.withAlphaComponent(0.72)
        loadingOverlay.isHidden = true
        view.addSubview(loadingOverlay)
        loadingOverlay.addSubview(loadingIndicator)

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 24, right: 16)
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(actionBar.snp.top)
        }

        actionBar.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            actionBarHeightConstraint = $0.height.equalTo(0).constraint
        }
        actionBarHeightConstraint?.deactivate()

        loadingOverlay.snp.makeConstraints { $0.edges.equalTo(scrollView) }
        loadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }

        errorLabel.font = .fdBody
        errorLabel.textColor = .fdSubtext
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        view.addSubview(errorLabel)
        errorLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        afterSaleCard.addSubview(afterSaleView)
        afterSaleView.snp.makeConstraints { $0.edges.equalToSuperview() }

        packageCard.addSubview(packageView)
        packageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        packageView.onToggleContent = { [weak self] in
            self?.viewModel.contentExpanded.toggle()
            if let detail = self?.viewModel.detail {
                self?.renderPackage(detail)
            }
        }

        addressCard.addSubview(addressView)
        addressView.snp.makeConstraints { $0.edges.equalToSuperview() }

        expressLogisticsCard.addSubview(expressLogisticsView)
        expressLogisticsView.snp.makeConstraints { $0.edges.equalToSuperview() }
        expressLogisticsView.onCopyTracking = { [weak self] trackingNo in
            UIPasteboard.general.string = trackingNo
            self?.showToast("物流单号已复制")
        }
        expressLogisticsView.onOpenRecords = { [weak self] in
            self?.openShipmentRecords(isPickup: false)
        }

        pickupLogisticsCard.addSubview(pickupLogisticsView)
        pickupLogisticsView.snp.makeConstraints { $0.edges.equalToSuperview() }
        pickupLogisticsView.onOpenRecords = { [weak self] in
            self?.openShipmentRecords(isPickup: true)
        }

        institutionCard.addSubview(institutionView)
        institutionView.snp.makeConstraints { $0.edges.equalToSuperview() }
        institutionView.onCall = { [weak self] in
            self?.callInstitution()
        }

        feeCard.addSubview(feeView)
        feeView.snp.makeConstraints { $0.edges.equalToSuperview() }

        infoCard.addSubview(infoView)
        infoView.snp.makeConstraints { $0.edges.equalToSuperview() }
        infoView.onOrderNumberCopied = { [weak self] in
            self?.showToast("订单号已复制")
        }

        [
            statusView,
            hintBar,
            afterSaleCard,
            packageCard,
            addressCard,
            expressLogisticsCard,
            pickupLogisticsCard,
            institutionCard,
            feeCard,
            infoCard
        ].forEach { contentStack.addArrangedSubview($0) }

        contentStack.setCustomSpacing(4, after: statusView)
        contentStack.setCustomSpacing(8, after: hintBar)

        actionBar.onAction = { [weak self] action in
            guard let self else { return }
            if action == .cancel, let detail = self.viewModel.detail {
                OrderCancelFlow.start(from: self, detail: detail) { [weak self] _ in
                    self?.navigationController?.popViewController(animated: true)
                }
                return
            }
            if action == .confirmShip, let detail = self.viewModel.detail {
                OrderStatusActionFlow.confirmShipment(from: self, detail: detail) { [weak self] in
                    self?.viewModel.load()
                }
                return
            }
            if action == .renew, let detail = self.viewModel.detail {
                OrderNavigationCoordinator.openPackageRenewal(from: self, detail: detail)
                return
            }
            if action == .confirmReceipt, let detail = self.viewModel.detail {
                OrderStatusActionFlow.confirmReceipt(from: self, detail: detail) { [weak self] in
                    self?.viewModel.load()
                }
                return
            }
            if action == .afterSale, let detail = self.viewModel.detail {
                OrderStatusActionFlow.afterSale(from: self, detail: detail) { [weak self] in
                    self?.viewModel.load()
                }
                return
            }
            if action == .settle, let detail = self.viewModel.detail {
                OrderStatusActionFlow.settle(from: self, detail: detail) { [weak self] in
                    self?.viewModel.load()
                }
                return
            }
            self.showToast(self.viewModel.handleAction(action))
        }
    }

    override func bindViewModel() {
        Publishers.CombineLatest4(
            viewModel.$detail,
            viewModel.$isLoading,
            viewModel.$errorMessage,
            viewModel.$hasAttemptedLoad
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] detail, loading, errorMessage, hasAttemptedLoad in
            self?.applyState(
                detail: detail,
                isLoading: loading,
                errorMessage: errorMessage,
                hasAttemptedLoad: hasAttemptedLoad
            )
        }
        .store(in: &cancellables)

        viewModel.load()
    }

    private func applyState(
        detail: AppOrderDetailBO?,
        isLoading: Bool,
        errorMessage: String?,
        hasAttemptedLoad: Bool
    ) {
        loadingOverlay.isHidden = !isLoading
        if isLoading {
            loadingIndicator.startAnimating()
            errorLabel.isHidden = true
            return
        }
        loadingIndicator.stopAnimating()

        guard hasAttemptedLoad else { return }

        if let errorMessage, !errorMessage.isEmpty, detail == nil {
            scrollView.isHidden = true
            collapseActionBar()
            errorLabel.isHidden = false
            errorLabel.text = errorMessage
            return
        }

        guard let detail else {
            scrollView.isHidden = true
            collapseActionBar()
            errorLabel.isHidden = false
            errorLabel.text = "订单信息加载失败"
            return
        }

        render(detail)
    }

    private func render(_ detail: AppOrderDetailBO) {
        scrollView.isHidden = false
        errorLabel.isHidden = true

        statusView.configure(
            presentation: .make(
                status: detail.orderStatus,
                title: detail.statusTitle
            )
        )
        hintBar.configure(text: detail.statusHint)

        let showsAfterSale = detail.showsAfterSaleInfoCard
        afterSaleCard.isHidden = !showsAfterSale
        if showsAfterSale {
            afterSaleView.configure(detail: detail)
        }

        renderPackage(detail)

        addressCard.isHidden = !detail.showsDeliveryAddressCard
        if detail.showsDeliveryAddressCard {
            addressView.configure(detail: detail)
        }

        expressLogisticsCard.isHidden = !detail.showsExpressLogisticsCard
        if detail.showsExpressLogisticsCard {
            expressLogisticsView.configure(
                lines: detail.logisticsLines,
                isPickup: false,
                logisticsSummary: detail.logisticsSummary
            )
        }

        pickupLogisticsCard.isHidden = !detail.showsPickupLogisticsCard
        if detail.showsPickupLogisticsCard {
            pickupLogisticsView.configure(
                lines: detail.logisticsLines,
                isPickup: true,
                logisticsSummary: detail.logisticsSummary
            )
        }

        institutionCard.isHidden = !detail.showsInstitutionCard
        if detail.showsInstitutionCard {
            institutionView.configure(detail: detail)
        }

        feeView.configure(detail: detail)

        var expandedRows: [(String, String)] = []
        let service = detail.serviceTime?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !service.isEmpty {
            expandedRows.append(("服务时间", service))
        }
        infoView.configure(
            detail: detail,
            paymentMethodOverride: detail.paymentTypeLabel,
            expandedRows: expandedRows,
            showsExpandToggle: true
        )

        let actions = viewModel.bottomActions
        actionBar.configure(actions: actions)
        let showsActions = !actions.isEmpty
        if showsActions {
            actionBarHeightConstraint?.deactivate()
        } else {
            actionBarHeightConstraint?.activate()
        }

        view.setNeedsLayout()
        view.layoutIfNeeded()
        scrollView.setNeedsLayout()
        scrollView.layoutIfNeeded()
        contentStack.setNeedsLayout()
        contentStack.layoutIfNeeded()
    }

    private func renderPackage(_ detail: AppOrderDetailBO) {
        packageView.configure(
            name: packageName(from: detail),
            subtitle: packageSubtitle(from: detail),
            amount: detail.packageAmount,
            lines: viewModel.visibleContentLines,
            canExpand: viewModel.canExpandContent,
            expanded: viewModel.contentExpanded,
            totalCount: detail.detailLines.count
        )
    }

    private func packageName(from detail: AppOrderDetailBO) -> String {
        let name = detail.orderName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "未命名订单" : name
    }

    private func packageSubtitle(from detail: AppOrderDetailBO) -> String {
        detail.packageDescription?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func showToast(_ message: String) {
        guard !message.isEmpty else { return }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            alert.dismiss(animated: true)
        }
    }

    private func collapseActionBar() {
        actionBar.configure(actions: [])
        actionBarHeightConstraint?.activate()
    }

    private func callInstitution() {
        guard let detail = viewModel.detail,
              let phone = detail.contactPhone?.filter({ $0.isNumber || $0 == "+" }),
              !phone.isEmpty,
              let url = URL(string: "tel://\(phone)"),
              UIApplication.shared.canOpenURL(url) else {
            showToast("暂无机构联系电话")
            return
        }
        UIApplication.shared.open(url)
    }

    private func openShipmentRecords(isPickup: Bool) {
        guard let orderId = viewModel.detail?.id else { return }
        Router.shared.push(
            "/orders/shipment-records",
            params: [
                "orderId": "\(orderId)",
                "type": isPickup ? "pickup" : "express",
            ],
            from: self
        )
    }
}
