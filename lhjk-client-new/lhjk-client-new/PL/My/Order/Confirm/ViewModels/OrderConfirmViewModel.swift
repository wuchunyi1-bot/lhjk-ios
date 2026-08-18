import Foundation
import Combine

enum OrderFulfillmentMethod: String {
    case express
    case selfPickup = "self_pickup"

    var title: String {
        switch self {
        case .express: return "快递配送"
        case .selfPickup: return "机构自提"
        }
    }

    /// 后端 `typeOrder`：1 快递 / 0 上门自提
    var typeOrderValue: Int {
        switch self {
        case .express: return 1
        case .selfPickup: return 0
        }
    }
}

enum OrderPayMethod: String, CaseIterable {
    case wechat
    case alipay

    var title: String {
        switch self {
        case .wechat: return "微信支付"
        case .alipay: return "支付宝支付"
        }
    }
}

/// 确认订单 ViewModel — 主数据源：`getOrderSettlement(orderId)`
final class OrderConfirmViewModel: ObservableObject {

    @Published private(set) var draft: PackageOrderDraft?
    @Published private(set) var isLoading = false
    @Published private(set) var isSubmitting = false
    @Published private(set) var isSyncing = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var toastMessage: String?
    @Published var contentExpanded = false
    @Published var fulfillment: OrderFulfillmentMethod = .selfPickup
    @Published var payMethod: OrderPayMethod = .wechat
    @Published var remark = ""
    @Published private(set) var deliveryAddress: MAddress?
    @Published private(set) var supportsExpress = false
    @Published private(set) var supportsWechat = true
    @Published private(set) var supportsAlipay = true
    @Published private(set) var settlementExpressFee: Double = 0
    @Published private(set) var settlementPayable: Double = 0
    @Published private(set) var settlementPackageAmount: Double = 0
    @Published private(set) var settlementCouponDiscount: Double = 0
    @Published private(set) var selectedCouponTakeId: Int64?
    @Published private(set) var selectedCouponName = ""
    @Published private(set) var hospitalDetail: OHospital?
    @Published var navigateBack = false
    @Published var navigateToOrders = false
    @Published private(set) var orderDetail: AppOrderDetailBO?
    @Published private(set) var availableCouponCount = 0
    @Published private(set) var availableBenefitCount = 0
    @Published private(set) var selectedBenefitIds: [String] = []

    private let orderId: Int64
    private let serialNumber: Int?
    private let entry: OrderConfirmEntry
    private let hospitalService: HospitalService
    private let orderService: OrderService
    private let couponService: CouponService
    private let voucherService: VoucherService
    private let paymentService: PaymentService
    private let institutionStore: InstitutionSelectionStore
    private var loadTask: Task<Void, Never>?
    private var payTask: Task<Void, Never>?
    private var fallbackHospitalName: String?
    private var latestSettlement: OrderSettlementBO?
    private var availableBenefits: [BenefitsRedeemCardVO] = []
    /// 绑单后结算 `totalPrice` 是否已体现权益抵扣（启发式）
    private var settlementIncludesBenefitDiscount = false

    init(
        orderId: Int64,
        serialNumber: Int? = nil,
        entry: OrderConfirmEntry = .default,
        hospitalService: HospitalService = AppContainer.shared.hospitalService,
        orderService: OrderService = AppContainer.shared.orderService,
        couponService: CouponService = AppContainer.shared.couponService,
        voucherService: VoucherService = AppContainer.shared.voucherService,
        paymentService: PaymentService = AppContainer.shared.paymentService,
        institutionStore: InstitutionSelectionStore = AppContainer.shared.institutionSelectionStore
    ) {
        self.orderId = orderId
        self.serialNumber = serialNumber
        self.entry = entry
        self.hospitalService = hospitalService
        self.orderService = orderService
        self.couponService = couponService
        self.voucherService = voucherService
        self.paymentService = paymentService
        self.institutionStore = institutionStore
    }

    deinit {
        loadTask?.cancel()
        payTask?.cancel()
    }

    var showsOrderListPayPresentation: Bool { entry == .orderListPay }

    /// 当前结算订单 id（取消等操作）
    var currentOrderId: Int64 { orderId }

    var selectedPaymentMethodLabel: String { payMethod.title }

    /// 机构自提始终可用；仅机构自提时不展示「收货方式」选择卡。
    var showsFulfillment: Bool { supportsExpress }

    var needsExpressAddress: Bool {
        fulfillment == .express
    }

    var needsPickupInfo: Bool {
        fulfillment == .selfPickup
    }

    var selectedAddress: MAddress? { deliveryAddress }

    var visibleContentItems: [PackageOrderDraftItem] {
        let items = draft?.selectedItems ?? []
        if contentExpanded || items.count <= 3 { return items }
        return Array(items.prefix(3))
    }

    var canExpandContent: Bool {
        (draft?.selectedItems.count ?? 0) > 3
    }

    var packageAmount: Double { settlementPackageAmount }

    var shippingFee: Double {
        fulfillment == .express ? settlementExpressFee : 0
    }

    var couponDiscount: Double { settlementCouponDiscount }

    /// 权益卡抵扣上限：仅套餐金额 − 优惠券，不抵运费
    var benefitCardLimit: Double {
        max(0, packageAmount - couponDiscount)
    }

    var benefitDiscount: Double {
        let raw = selectedBenefits.reduce(0) { $0 + $1.effectiveDeduct }
        return min(benefitCardLimit, raw)
    }

    var payableAmount: Double {
        if settlementIncludesBenefitDiscount {
            return settlementPayable
        }
        return max(0, settlementPayable - benefitDiscount)
    }

    var couponSummaryText: String {
        if settlementCouponDiscount > 0, selectedCouponTakeId != nil {
            return "已使用一张，共优惠\(OrderConfirmMoney.yen(settlementCouponDiscount))"
        }
        if availableCouponCount > 0 {
            return "有\(availableCouponCount)张可用"
        }
        return "暂无可用"
    }

    var couponSummaryIsPlaceholder: Bool {
        settlementCouponDiscount <= 0 && availableCouponCount == 0
    }

    var benefitSummaryText: String {
        let selectedCount = selectedBenefitIds.count
        if selectedCount > 0 {
            return "已使用\(selectedCount)张，共优惠\(OrderConfirmMoney.yen(benefitDiscount))"
        }
        if availableBenefitCount > 0 {
            return "有\(availableBenefitCount)张可用"
        }
        return "暂无可用"
    }

    var benefitSummaryIsPlaceholder: Bool {
        selectedBenefitIds.isEmpty && availableBenefitCount == 0
    }

    private var selectedBenefits: [BenefitsRedeemCardVO] {
        let idSet = Set(selectedBenefitIds)
        return availableBenefits.filter { idSet.contains($0.id) }
    }

    var pickupName: String {
        let fromHospital = hospitalDetail?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !fromHospital.isEmpty { return fromHospital }
        if let fallback = fallbackHospitalName, !fallback.isEmpty { return fallback }
        return draft?.hospitalName
            ?? institutionStore.selected?.name
            ?? "服务机构"
    }

    var pickupAddress: String {
        let fromHospital = hospitalDetail?.fullAddress ?? ""
        if !fromHospital.isEmpty { return fromHospital }
        let fromDraft = draft?.hospitalAddress?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !fromDraft.isEmpty { return fromDraft }
        return institutionStore.selected?.fullAddress ?? "请到机构前台办理"
    }

    var institutionPhone: String {
        if let phone = hospitalDetail?.contactPhone, !phone.isEmpty {
            return phone
        }
        return ""
    }

    func load() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    func selectFulfillment(_ method: OrderFulfillmentMethod) {
        if method == .express, !supportsExpress { return }
        guard method != fulfillment else { return }

        let previous = fulfillment
        fulfillment = method

        Task { [weak self] in
            guard let self else { return }
            await self.syncFulfillmentChange(from: previous, to: method)
        }
    }

    func updateRemark(_ text: String) {
        let trimmed = String(text.prefix(300))
        let previous = remark
        remark = trimmed
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.orderService.updateOrderDescription(
                    orderId: self.orderId,
                    description: trimmed
                )
            } catch {
                await MainActor.run {
                    self.remark = previous
                    self.toastMessage = error.localizedDescription.isEmpty
                        ? "保存备注失败"
                        : error.localizedDescription
                }
            }
        }
    }

    func submitPay() {
        guard !isSubmitting else { return }
        guard draft != nil else {
            toastMessage = "订单信息已失效，请重新下单"
            navigateBack = true
            return
        }
        if needsExpressAddress, selectedAddress == nil {
            toastMessage = "请选择收货地址"
            return
        }

        isSubmitting = true
        payTask?.cancel()
        payTask = Task { [weak self] in
            guard let self else { return }
            await self.performSubmitPay()
        }
    }

    private func performSubmitPay() async {
        let channel: PaymentChannel = payMethod == .wechat ? .wechatPay : .alipay
        let productName = draft?.packageName
            ?? latestSettlement?.packageName
            ?? "健康服务套餐"
        let amount = payableAmount
        let remarkText = remark.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            _ = try await paymentService.payMallOrder(
                orderId: orderId,
                productName: productName,
                amountYuan: amount,
                channel: channel,
                description: remarkText.isEmpty ? nil : remarkText
            )
            await MainActor.run {
                isSubmitting = false
                toastMessage = "支付成功"
                NotificationCenter.default.post(name: .orderListNeedsRefresh, object: nil)
                navigateToOrders = true
            }
        } catch let error as PaymentError {
            await MainActor.run {
                isSubmitting = false
                switch error {
                case .userCancelled:
                    toastMessage = "已取消支付"
                case .channelNotAvailable:
                    toastMessage = channel == .wechatPay
                        ? "请先安装微信后再支付"
                        : "当前支付方式暂不可用"
                case .paymentFailed(let reason):
                    toastMessage = reason.isEmpty ? "支付失败，请稍后重试" : reason
                default:
                    toastMessage = error.localizedDescription.isEmpty
                        ? "支付失败，请稍后重试"
                        : error.localizedDescription
                }
            }
        } catch {
            await MainActor.run {
                isSubmitting = false
                toastMessage = error.localizedDescription.isEmpty
                    ? "发起支付失败，请稍后重试"
                    : error.localizedDescription
            }
        }
    }

    func consumeToast() {
        toastMessage = nil
    }

    func consumeNavigationFlags() {
        navigateBack = false
        navigateToOrders = false
    }

    // MARK: - 优惠券

    func fetchCouponOptions() async throws -> [CouponTakeItem] {
        let hospitalId = latestSettlement?.resolvedHospitalId
        let result = try await couponService.getCouponTakeList(hospitalId: hospitalId)
        await MainActor.run {
            availableCouponCount = result.items.count
        }
        return result.items
    }

    func bindCoupon(takeId: Int64?) {
        Task { [weak self] in
            guard let self else { return }
            await self.performBindCoupon(takeId: takeId)
        }
    }

    // MARK: - 权益卡

    /// 加载 / 刷新订单可选权益卡 `getOrderBenefitsList`
    @discardableResult
    func fetchBenefitOptions() async throws -> [BenefitsRedeemCardVO] {
        let list = try await voucherService.getOrderBenefitsList(orderId: orderId)
        await MainActor.run {
            applyOrderBenefitsList(list)
            objectWillChange.send()
        }
        return list
    }

    func applyBenefitSelection(ids: [String]) {
        Task { [weak self] in
            guard let self else { return }
            await MainActor.run { self.isSyncing = true }
            do {
                let takeIds = ids.compactMap { Int64($0) }
                try await self.voucherService.updateOrderBenefits(
                    orderId: self.orderId,
                    benefitsTakeIds: takeIds
                )
                await self.refreshSettlement(
                    showToast: takeIds.isEmpty ? "已取消权益卡" : "已选择权益卡"
                )
                _ = try? await self.fetchBenefitOptions()
            } catch {
                await MainActor.run {
                    self.toastMessage = error.localizedDescription.isEmpty
                        ? "保存权益卡失败"
                        : error.localizedDescription
                }
            }
            await MainActor.run { self.isSyncing = false }
        }
    }

    // MARK: - 配送地址绑定

    func bindDelivery(address: MAddress) {
        let previous = deliveryAddress
        deliveryAddress = address
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.orderService.updateOrderDelivery(
                    orderId: self.orderId,
                    typeOrder: 1,
                    addressId: address.id,
                    receiver: address.name,
                    phone: address.mobile,
                    address: address.fullAddress
                )
                await self.refreshSettlement(showToast: "已选择收货地址")
            } catch {
                await MainActor.run {
                    self.deliveryAddress = previous
                    self.toastMessage = error.localizedDescription.isEmpty
                        ? "保存配送信息失败"
                        : error.localizedDescription
                }
            }
        }
    }

    // MARK: - Private

    private func performLoad() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            supportsExpress = false
            settlementExpressFee = 0
            hospitalDetail = nil
            fallbackHospitalName = nil
            draft = nil
            orderDetail = nil
        }

        do {
            let settlement: OrderSettlementBO
            if entry == .orderListPay {
                async let settlementTask = orderService.getOrderSettlement(
                    orderId: orderId,
                    serialNumber: serialNumber
                )
                async let detailTask = orderService.getAppOrderDetail(orderId: orderId)
                let (loadedSettlement, loadedDetail) = try await (settlementTask, detailTask)
                settlement = loadedSettlement
                await MainActor.run {
                    orderDetail = loadedDetail
                }
            } else {
                settlement = try await orderService.getOrderSettlement(
                    orderId: orderId,
                    serialNumber: serialNumber
                )
            }
            await MainActor.run {
                applySettlement(settlement)
                isLoading = false
            }
            await loadHospitalDetail(
                hospitalId: settlement.resolvedHospitalId ?? institutionStore.selectedHospitalId
            )
            _ = try? await fetchBenefitOptions()
            _ = try? await fetchCouponOptions()
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                toastMessage = error.localizedDescription.isEmpty
                    ? "获取结算信息失败"
                    : error.localizedDescription
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) { [weak self] in
                    self?.navigateBack = true
                }
            }
        }
    }

    private func refreshSettlement(showToast message: String? = nil) async {
        await MainActor.run { isSyncing = true }

        do {
            let settlement = try await orderService.getOrderSettlement(
                orderId: orderId,
                serialNumber: serialNumber
            )
            await MainActor.run {
                applySettlement(settlement)
                if let message { toastMessage = message }
                isSyncing = false
            }
        } catch {
            await MainActor.run {
                toastMessage = error.localizedDescription.isEmpty
                    ? "刷新订单信息失败"
                    : error.localizedDescription
                isSyncing = false
            }
        }
    }

    private func syncFulfillmentChange(
        from previous: OrderFulfillmentMethod,
        to method: OrderFulfillmentMethod
    ) async {
        switch method {
        case .selfPickup:
            await MainActor.run { isSyncing = true }
            do {
                try await orderService.updateOrderDelivery(
                    orderId: orderId,
                    typeOrder: 0
                )
                await refreshSettlement()
            } catch {
                await MainActor.run {
                    fulfillment = previous
                    toastMessage = error.localizedDescription.isEmpty
                        ? "切换收货方式失败"
                        : error.localizedDescription
                }
            }
            await MainActor.run { isSyncing = false }

        case .express:
            guard let addr = deliveryAddress else { return }
            await MainActor.run { isSyncing = true }
            do {
                try await orderService.updateOrderDelivery(
                    orderId: orderId,
                    typeOrder: 1,
                    addressId: addr.id,
                    receiver: addr.name,
                    phone: addr.mobile,
                    address: addr.fullAddress
                )
                await refreshSettlement()
            } catch {
                await MainActor.run {
                    fulfillment = previous
                    toastMessage = error.localizedDescription.isEmpty
                        ? "切换收货方式失败"
                        : error.localizedDescription
                }
            }
            await MainActor.run { isSyncing = false }
        }
    }

    private func performBindCoupon(takeId: Int64?) async {
        await MainActor.run { isSyncing = true }
        do {
            try await couponService.bindCouponTake(orderId: orderId, couponTakeId: takeId)
            let toast = takeId == nil ? "已取消优惠券" : "已选择优惠券"
            await refreshSettlement(showToast: toast)
        } catch {
            await MainActor.run {
                toastMessage = error.localizedDescription.isEmpty
                    ? "绑定优惠券失败"
                    : error.localizedDescription
            }
        }
        await MainActor.run { isSyncing = false }
    }

    private func applySettlement(_ settlement: OrderSettlementBO) {
        latestSettlement = settlement
        draft = Self.makeDisplayDraft(
            from: settlement,
            orderId: orderId,
            serialNumber: serialNumber
        )
        supportsExpress = settlement.supportsExpress
        settlementExpressFee = settlement.expressAmountYuan
        settlementPackageAmount = settlement.packageAmountYuan
        settlementPayable = settlement.payableAmountYuan
        settlementCouponDiscount = settlement.couponDiscountYuan
        selectedCouponTakeId = settlement.resolvedCouponTakeId
        selectedCouponName = resolveCouponName(from: settlement)
        fallbackHospitalName = settlement.resolvedHospitalName
        pruneSelectedBenefits()

        if let remarkText = settlement.description?.trimmingCharacters(in: .whitespacesAndNewlines),
           !remarkText.isEmpty {
            remark = remarkText
        }

        applyPayFlags(wechat: settlement.wechat, alipay: settlement.alipay)
        fulfillment = settlement.supportsExpress
            ? Self.fulfillment(from: settlement)
            : .selfPickup
        deliveryAddress = Self.deliveryAddress(from: settlement)
        recomputeSettlementBenefitFlag()
    }

    private func applyOrderBenefitsList(_ list: [BenefitsRedeemCardVO]) {
        availableBenefits = list
        availableBenefitCount = list.filter(\.isAvailable).count
        selectedBenefitIds = list.filter(\.isSelected).map(\.id).filter { !$0.isEmpty }
        recomputeSettlementBenefitFlag()
    }

    private func recomputeSettlementBenefitFlag() {
        let discount = selectedBenefits.reduce(0) { $0 + $1.effectiveDeduct }
        guard discount > 0.009 else {
            settlementIncludesBenefitDiscount = false
            return
        }
        let expectedWithout = max(0, packageAmount + shippingFee - couponDiscount)
        let expectedWith = max(0, expectedWithout - min(benefitCardLimit, discount))
        // 结算应付更接近「已扣权益」时，认为服务端已计入
        settlementIncludesBenefitDiscount =
            abs(settlementPayable - expectedWith) <= abs(settlementPayable - expectedWithout)
    }

    private func pruneSelectedBenefits() {
        let allowed = Set(availableBenefits.map(\.id))
        selectedBenefitIds = selectedBenefitIds.filter { allowed.contains($0) }
        recomputeSettlementBenefitFlag()
    }

    private func resolveCouponName(from settlement: OrderSettlementBO) -> String {
        let fromList = settlement.appOrderDetailBO?.couponTakeList?
            .first(where: { $0.id == settlement.resolvedCouponTakeId })?
            .name?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !fromList.isEmpty { return fromList }
        return settlementCouponDiscount > 0 ? "优惠券" : ""
    }

    private func loadHospitalDetail(hospitalId: String?) async {
        let rawId = hospitalId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard let id = Int64(rawId), id > 0 else { return }

        do {
            let hospital = try await hospitalService.getById(id: id)
            await MainActor.run {
                hospitalDetail = hospital
                if var current = self.draft {
                    let name = hospital.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if !name.isEmpty { current.hospitalName = name }
                    let address = hospital.fullAddress
                    if !address.isEmpty { current.hospitalAddress = address }
                    current.hospitalId = hospital.id ?? rawId
                    self.draft = current
                }
            }
        } catch {
            print("[OrderConfirm] hospital getById failed: \(error.localizedDescription)")
        }
    }

    private func applyPayFlags(wechat: Bool?, alipay: Bool?) {
        let w = wechat ?? true
        let a = alipay ?? true
        supportsWechat = w || (!w && !a)
        supportsAlipay = a || (!w && !a)
        if payMethod == .wechat, !supportsWechat, supportsAlipay {
            payMethod = .alipay
        } else if payMethod == .alipay, !supportsAlipay, supportsWechat {
            payMethod = .wechat
        }
    }

    private static func fulfillment(from settlement: OrderSettlementBO) -> OrderFulfillmentMethod {
        guard settlement.supportsExpress, settlement.resolvedTypeOrder == 1 else {
            return .selfPickup
        }
        return .express
    }

    private static func deliveryAddress(from settlement: OrderSettlementBO) -> MAddress? {
        guard let order = settlement.appOrderDetailBO, order.hasDeliveryAddress else {
            return nil
        }
        return MAddress(
            id: nil,
            name: order.receiver,
            mobile: order.phone,
            address: order.address
        )
    }

    private static func makeDisplayDraft(
        from settlement: OrderSettlementBO,
        orderId: Int64,
        serialNumber: Int?
    ) -> PackageOrderDraft {
        let name = settlement.packageName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let items = (settlement.details ?? []).map { $0.toDraftItem() }
        let amount = settlement.packageAmountYuan
        let packageId = settlement.resolvedPackageId
        return PackageOrderDraft(
            packageId: packageId.isEmpty ? String(orderId) : packageId,
            packageName: name.isEmpty ? "套餐" : name,
            subtitle: settlement.resolvedSubtitle,
            amount: amount,
            selectedItems: items.isEmpty
                ? [PackageOrderDraftItem(name: name.isEmpty ? "套餐" : name, qty: "1", unit: "份", price: amount)]
                : items,
            hospitalId: settlement.resolvedHospitalId,
            hospitalName: settlement.resolvedHospitalName,
            hospitalAddress: nil,
            categoryServiceId: settlement.categoryServiceId,
            contractedFulfillmentMethod: nil,
            hasPhysicalGoods: settlement.supportsExpress,
            orderId: String(orderId),
            serialNumber: serialNumber,
            updatedAt: Date().timeIntervalSince1970
        )
    }
}
