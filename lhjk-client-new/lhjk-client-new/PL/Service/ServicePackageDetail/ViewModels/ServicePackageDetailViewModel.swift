import Foundation
import Combine

/// 套餐详情 ViewModel — 数字 id 走 `getHospitalPackageDetail`；否则本地原型降级
final class ServicePackageDetailViewModel: ObservableObject {

    @Published private(set) var package: ServicePackageDetail?
    @Published private(set) var isLoading = false
    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String?

    private let packageId: String
    private let hospitalId: String?
    private let categoryServiceId: String?
    private let hospitalPackageService: HospitalPackageService
    private let catalogService: ServiceCatalogService
    private let shoppingCartService: ShoppingCartService
    private let institutionStore: InstitutionSelectionStore
    private var loadTask: Task<Void, Never>?

    init(
        packageId: String,
        hospitalId: String? = nil,
        categoryServiceId: String? = nil,
        hospitalPackageService: HospitalPackageService = AppContainer.shared.hospitalPackageService,
        catalogService: ServiceCatalogService = AppContainer.shared.serviceCatalogService,
        shoppingCartService: ShoppingCartService = AppContainer.shared.shoppingCartService,
        institutionStore: InstitutionSelectionStore = AppContainer.shared.institutionSelectionStore
    ) {
        self.packageId = packageId
        self.hospitalId = hospitalId
        self.categoryServiceId = categoryServiceId
        self.hospitalPackageService = hospitalPackageService
        self.catalogService = catalogService
        self.shoppingCartService = shoppingCartService
        self.institutionStore = institutionStore
    }

    deinit { loadTask?.cancel() }

    /// 是否走服务端加购/下单（数字 packageId）
    var usesRemoteCartAPI: Bool {
        HospitalPackageService.apiHospitalId(package?.id ?? packageId) != nil
    }

    func load() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    /// 加入购物车：`flag = 2`（仅服务端，不写本地缓存）
    func addToCart(selectedDetails: [PackageHospitalDetailSubmitItem]) async throws {
        try await submit(flag: .addToCart, selectedDetails: selectedDetails)
    }

    /// 立即下单：`flag = 1`，返回订单 id（供确认页拉结算）
    @discardableResult
    func purchaseNow(selectedDetails: [PackageHospitalDetailSubmitItem]) async throws -> Int64 {
        try await submit(flag: .purchaseNow, selectedDetails: selectedDetails)
    }

    // MARK: - Private

    @discardableResult
    private func submit(
        flag: ShoppingCartActionFlag,
        selectedDetails: [PackageHospitalDetailSubmitItem]
    ) async throws -> Int64 {
        guard !selectedDetails.isEmpty else {
            throw ShoppingCartServiceError.emptyDetails
        }
        guard let pkgId = Int64(HospitalPackageService.apiHospitalId(package?.id ?? packageId) ?? "") else {
            throw ShoppingCartServiceError.invalidPackageId
        }
        guard let hid = Int64(resolvedHospitalId()) else {
            throw ShoppingCartServiceError.invalidHospitalId
        }
        guard let categoryRaw = resolvedCategoryServiceId(),
              let categoryId = Int64(categoryRaw) else {
            throw ShoppingCartServiceError.invalidCategoryServiceId
        }

        await MainActor.run { isSubmitting = true }
        do {
            let request = SaveShoppingCartRequest(
                hospitalId: hid,
                packageId: pkgId,
                categoryServiceId: categoryId,
                flag: flag.rawValue,
                packageHospitalDetailList: selectedDetails
            )
            let orderId = try await shoppingCartService.saveShoppingCartOrPurchase(request)
            await MainActor.run { isSubmitting = false }
            if flag == .purchaseNow {
                guard let orderId, orderId > 0 else {
                    throw ShoppingCartServiceError.missingOrderId
                }
                return orderId
            }
            return orderId ?? 0
        } catch {
            await MainActor.run { isSubmitting = false }
            throw error
        }
    }

    /// 已选机构 → 入参 → 临时常量
    private func resolvedHospitalId() -> String {
        if let selected = institutionStore.selectedHospitalId {
            return selected
        }
        return HospitalPackageService.resolvedHospitalId(hospitalId)
    }

    /// 详情 packageInfo → 路由入参
    private func resolvedCategoryServiceId() -> String? {
        if let fromPackage = HospitalPackageService.apiHospitalId(package?.categoryServiceId) {
            return fromPackage
        }
        return HospitalPackageService.apiHospitalId(categoryServiceId)
    }

    private func performLoad() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        // 有效数字 id → 真实详情接口
        if HospitalPackageService.apiHospitalId(packageId) != nil {
            do {
                let detail = try await hospitalPackageService.fetchPackageDetail(
                    packageId: packageId,
                    hospitalId: hospitalId ?? institutionStore.selectedHospitalId
                )
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    package = detail
                    isLoading = false
                }
                return
            } catch {
                guard !Task.isCancelled else { return }
                // API 失败时若有本地原型同 id 则降级，否则展示错误
                if let local = catalogService.packageDetail(id: packageId),
                   HospitalPackageService.apiHospitalId(local.id) == nil {
                    await MainActor.run {
                        package = local
                        isLoading = false
                        errorMessage = nil
                    }
                    return
                }
                await MainActor.run {
                    package = nil
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
                return
            }
        }

        // 德系原型等非数字 id
        let local = catalogService.packageDetail(id: packageId)
        await MainActor.run {
            package = local
            isLoading = false
            if local == nil {
                errorMessage = "套餐不存在"
            }
        }
    }
}
