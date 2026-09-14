import Foundation
import Combine

/// 注销账户 ViewModel — 注销流程、API 调用、会话清理
final class CancelAccountViewModel: ObservableObject {

    struct UnfinishedOrderBlock {
        let orderId: Int64?
        let message: String
    }

    // MARK: - Published State

    @Published var isSubmitting = false
    @Published var isSuccess = false

    // MARK: - One-shot

    let toastPublisher = PassthroughSubject<String, Never>()
    /// `O0012`：有未完成订单，禁止注销
    let unfinishedOrderPublisher = PassthroughSubject<UnfinishedOrderBlock, Never>()

    // MARK: - Dependencies

    private let userService: UserService
    private let loginService: LoginService
    private let userManager: UserManager
    private let imService: IMService

    // MARK: - Init

    init(userService: UserService = AppContainer.shared.userService,
         loginService: LoginService = AppContainer.shared.loginService,
         userManager: UserManager = AppContainer.shared.userManager,
         imService: IMService = AppContainer.shared.imService) {
        self.userService = userService
        self.loginService = loginService
        self.userManager = userManager
        self.imService = imService
    }

    // MARK: - Cancel

    private static func unfinishedOrderBlock(from error: Error) -> UnfinishedOrderBlock? {
        if let serviceError = error as? UserServiceError {
            switch serviceError {
            case .unfinishedOrders(let orderId, let message):
                return UnfinishedOrderBlock(orderId: orderId, message: message)
            case .cancelFailed(let message)
                where UserServiceError.isUnfinishedOrderMessage(message):
                return UnfinishedOrderBlock(orderId: nil, message: message)
            default:
                break
            }
        }
        if let unfinished = UserServiceError.unfinishedOrdersIfMatched(
            code: nil,
            message: error.localizedDescription,
            orderId: nil
        ), case let .unfinishedOrders(orderId, message) = unfinished {
            return UnfinishedOrderBlock(orderId: orderId, message: message)
        }
        return nil
    }

    func cancelAccount() {
        guard !isSubmitting else { return }
        isSubmitting = true

        Task {
            do {
                try await userService.cancelCurrentUser()

                await AppContainer.shared.columnContentCacheService.clear()
                await AppContainer.shared.serviceHubCacheService.clear()
                await AppContainer.shared.healthPageCacheService.clear()
                await MainActor.run {
                    APIManager.shared.clearCredential()
                    loginService.clearSession()
                    userManager.clear()
                    imService.clear()
                    AppContainer.shared.institutionSelectionStore.clear()
                    isSubmitting = false
                    isSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    if let block = Self.unfinishedOrderBlock(from: error) {
                        unfinishedOrderPublisher.send(block)
                    } else {
                        toastPublisher.send(error.localizedDescription)
                    }
                }
            }
        }
    }
}
