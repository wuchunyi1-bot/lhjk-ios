import Combine
import Foundation

@MainActor
final class MyBenefitsViewModel: ObservableObject {

    @Published private(set) var items: [CabinEntitlementVO] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: CabinService
    private var requestID = 0

    init(service: CabinService = .shared) {
        self.service = service
    }

    func reload() {
        requestID += 1
        let token = requestID
        isLoading = items.isEmpty
        Task {
            do {
                let list = try await service.entitlements()
                guard token == requestID else { return }
                items = list
                isLoading = false
            } catch {
                guard token == requestID else { return }
                isLoading = false
                errorMessage = (error as? LocalizedError)?.errorDescription ?? "获取权益失败"
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
