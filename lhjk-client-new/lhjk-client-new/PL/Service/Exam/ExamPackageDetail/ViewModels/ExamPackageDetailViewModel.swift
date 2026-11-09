import Combine
import Foundation

@MainActor
final class ExamPackageDetailViewModel: ObservableObject {

    @Published private(set) var detail: ServiceItemDetailVO?
    @Published private(set) var isLoading = false
    @Published private(set) var isMissing = false
    @Published private(set) var errorMessage: String?

    let configId: String
    /// 列表带入的标价。详情接口没有价格。
    let listPriceText: String?

    private let service: ServiceItemService

    init(
        configId: String,
        listPriceText: String?,
        service: ServiceItemService = AppContainer.shared.serviceItemService
    ) {
        self.configId = configId
        let trimmed = listPriceText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.listPriceText = trimmed.isEmpty ? nil : trimmed
        self.service = service
    }

    var priceText: String? {
        guard let listPriceText else { return nil }
        return listPriceText.hasPrefix("¥") ? listPriceText : "¥\(listPriceText)"
    }

    func load() {
        let configId = configId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !configId.isEmpty else {
            isMissing = true
            detail = nil
            return
        }
        isLoading = true
        isMissing = false
        let service = service
        Task {
            do {
                let detail = try await service.detail(configId: configId)
                self.detail = detail
                self.isLoading = false
                self.isMissing = false
            } catch {
                self.detail = nil
                self.isLoading = false
                self.isMissing = true
                self.errorMessage = (error as? LocalizedError)?.errorDescription ?? "未找到该项目"
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }

    /// 免费直接预约没有提交接口。需购买时进入已有套餐详情。
    func purchaseTarget() -> (packageId: String, hospitalId: String)? {
        guard let detail, detail.needsPurchase else { return nil }
        guard let packageId = detail.packageId, !packageId.isEmpty else { return nil }
        return (packageId, detail.hospitalId)
    }
}
