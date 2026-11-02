import Combine
import Foundation

@MainActor
final class WellnessCabinDetailViewModel: ObservableObject {

    let hospitalId: String
    /// 列表带入的距离文案。详情接口不传坐标，本页不重新定位。
    let passedDistanceLabel: String?

    @Published private(set) var store: CabinStoreVO?
    @Published private(set) var categories: [CabinCategoryVO] = []
    @Published private(set) var selectedCategoryId: String?
    @Published private(set) var services: [CabinConfigItemVO] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingServices = false
    @Published private(set) var isMissing = false
    @Published private(set) var errorMessage: String?

    private let cabinService: CabinService
    private var serviceCache: [String: [CabinConfigItemVO]] = [:]
    private var serviceRequest = 0
    private var didStart = false

    init(
        hospitalId: String,
        distanceLabel: String? = nil,
        cabinService: CabinService = AppContainer.shared.cabinService
    ) {
        self.hospitalId = hospitalId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmed = distanceLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.passedDistanceLabel = trimmed.isEmpty ? nil : trimmed
        self.cabinService = cabinService
        load()
    }

    var distanceText: String? {
        if let passedDistanceLabel { return passedDistanceLabel }
        return store?.distanceLabel
    }

    var selectedCategory: CabinCategoryVO? {
        categories.first { $0.id == selectedCategoryId }
    }

    func load() {
        guard !didStart else { return }
        didStart = true
        let id = hospitalId
        guard !id.isEmpty else {
            isMissing = true
            return
        }
        isLoading = true
        isMissing = false
        let service = cabinService
        // 不挂在主线程任务上。详情页布局若卡住主线程，请求仍会发出。
        Task.detached {
            async let storeCall = service.storeDetail(hospitalId: id)
            async let categoryCall = service.categories(hospitalId: id)

            let store: CabinStoreVO?
            let detailFailed: Bool
            do {
                store = try await storeCall
                detailFailed = false
            } catch {
                store = nil
                detailFailed = true
            }

            let categories: [CabinCategoryVO]
            let categoryMessage: String?
            do {
                categories = try await categoryCall
                categoryMessage = nil
            } catch {
                categories = []
                categoryMessage = (error as? LocalizedError)?.errorDescription ?? "获取服务分类失败"
            }

            await self.finishLoad(
                store: store,
                detailFailed: detailFailed,
                categories: categories,
                categoryMessage: categoryMessage
            )
        }
    }

    func selectCategory(_ id: String) {
        guard selectedCategoryId != id else { return }
        selectedCategoryId = id
        Task { await loadServices(parentId: id) }
    }

    func clearError() {
        errorMessage = nil
    }

    private func finishLoad(
        store: CabinStoreVO?,
        detailFailed: Bool,
        categories: [CabinCategoryVO],
        categoryMessage: String?
    ) {
        isLoading = false
        if detailFailed || store == nil {
            self.store = nil
            isMissing = true
        } else {
            self.store = store
            isMissing = false
        }
        self.categories = categories
        if let categoryMessage, !categoryMessage.isEmpty {
            errorMessage = categoryMessage
        }
        guard store != nil, let first = categories.first else {
            selectedCategoryId = nil
            services = []
            return
        }
        selectedCategoryId = first.id
        Task { await loadServices(parentId: first.id) }
    }

    private func loadServices(parentId: String) async {
        if let cached = serviceCache[parentId] {
            services = cached
            isLoadingServices = false
            return
        }
        serviceRequest += 1
        let token = serviceRequest
        isLoadingServices = true
        defer {
            if token == serviceRequest { isLoadingServices = false }
        }
        do {
            let items = try await cabinService.serviceItems(hospitalId: hospitalId, parentId: parentId)
            guard token == serviceRequest else { return }
            serviceCache[parentId] = items
            services = items
        } catch {
            guard token == serviceRequest else { return }
            services = []
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "获取服务项目失败"
        }
    }
}
