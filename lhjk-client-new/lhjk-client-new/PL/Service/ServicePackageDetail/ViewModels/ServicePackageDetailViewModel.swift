import Foundation
import Combine

/// 套餐详情 ViewModel — 数字 id 走 `getHospitalPackageDetail`；否则本地原型降级
final class ServicePackageDetailViewModel: ObservableObject {

    @Published private(set) var package: ServicePackageDetail?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let packageId: String
    private let hospitalId: String?
    private let hospitalPackageService: HospitalPackageService
    private let catalogService: ServiceCatalogService
    private var loadTask: Task<Void, Never>?

    init(
        packageId: String,
        hospitalId: String? = nil,
        hospitalPackageService: HospitalPackageService = AppContainer.shared.hospitalPackageService,
        catalogService: ServiceCatalogService = AppContainer.shared.serviceCatalogService
    ) {
        self.packageId = packageId
        self.hospitalId = hospitalId
        self.hospitalPackageService = hospitalPackageService
        self.catalogService = catalogService
    }

    deinit { loadTask?.cancel() }

    func load() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
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
                    hospitalId: hospitalId
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
