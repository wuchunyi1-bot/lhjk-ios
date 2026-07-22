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
    @Published private(set) var errorMessage: String?
    @Published private(set) var toastMessage: String?
    @Published var contentExpanded = false
    /// 默认机构自提
    @Published var fulfillment: OrderFulfillmentMethod = .selfPickup
    @Published var payMethod: OrderPayMethod = .wechat
    @Published var remark = ""
    @Published private(set) var deliveryAddress: MAddress?
    @Published private(set) var supportsExpress = false
    @Published private(set) var supportsWechat = true
    @Published private(set) var supportsAlipay = true
    @Published private(set) var settlementExpressFee = 0
    @Published private(set) var settlementPayable = 0
    @Published private(set) var settlementPackageAmount = 0
    @Published private(set) var hospitalDetail: OHospital?
    @Published var navigateBack = false
    @Published var navigateToOrders = false

    private let orderId: Int64
    private let serialNumber: Int?
    private let hospitalService: HospitalService
    private let orderService: OrderService
    private let institutionStore: InstitutionSelectionStore
    private var loadTask: Task<Void, Never>?
    private var fallbackHospitalName: String?

    init(
        orderId: Int64,
        serialNumber: Int? = nil,
        hospitalService: HospitalService = AppContainer.shared.hospitalService,
        orderService: OrderService = AppContainer.shared.orderService,
        institutionStore: InstitutionSelectionStore = AppContainer.shared.institutionSelectionStore
    ) {
        self.orderId = orderId
        self.serialNumber = serialNumber
        self.hospitalService = hospitalService
        self.orderService = orderService
        self.institutionStore = institutionStore
    }

    deinit { loadTask?.cancel() }

    /// 始终展示收货方式
    var showsFulfillment: Bool { true }

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

    var packageAmount: Int { settlementPackageAmount }

    var shippingFee: Int {
        fulfillment == .express ? settlementExpressFee : 0
    }

    var couponDiscount: Int { 0 }
    var benefitDiscount: Int { 0 }

    var payableAmount: Int {
        max(0, settlementPayable)
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
        fulfillment = method
        // 切换收货方式不调用后端；仅在选择收货地址后才调用 updateOrderDelivery
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self else { return }
            self.isSubmitting = false
            self.toastMessage = "订单已提交，支付功能即将开放"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) { [weak self] in
                self?.navigateToOrders = true
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
            fulfillment = .selfPickup
        }

        let settlement: OrderSettlementBO
        do {
            settlement = try await orderService.getOrderSettlement(
                orderId: orderId,
                serialNumber: serialNumber
            )
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
            return
        }

        let display = Self.makeDisplayDraft(from: settlement, orderId: orderId, serialNumber: serialNumber)

        await MainActor.run {
            draft = display
            supportsExpress = settlement.supportsExpress
            settlementExpressFee = settlement.expressAmountYuan
            settlementPackageAmount = settlement.packageAmountYuan
            settlementPayable = settlement.payableAmountYuan
            fallbackHospitalName = settlement.resolvedHospitalName
            if let remarkText = settlement.description?.trimmingCharacters(in: .whitespacesAndNewlines),
               !remarkText.isEmpty {
                remark = remarkText
            }
            applyPayFlags(wechat: settlement.wechat, alipay: settlement.alipay)
            fulfillment = .selfPickup
            deliveryAddress = Self.deliveryAddress(from: settlement)
            isLoading = false
        }

        await loadHospitalDetail(
            hospitalId: settlement.resolvedHospitalId ?? institutionStore.selectedHospitalId
        )
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

    // MARK: - 配送地址绑定

    /// 选择地址后绑定到订单（typeOrder=1 快递）
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
                await MainActor.run {
                    self.toastMessage = "已选择收货地址"
                }
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

    /// 从结算 `appOrderDetailBO` 构造展示用快递地址；仅 `typeOrder=1`（快递）且带地址信息时返回
    /// 机构自提地址不在 `appOrderDetailBO`，由 `hospital/getById` 单独获取
    private static func deliveryAddress(from settlement: OrderSettlementBO) -> MAddress? {
        guard let order = settlement.appOrderDetailBO,
              order.typeOrder == 1,
              order.hasDeliveryAddress else {
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
