import Foundation
import Combine

/// 注销账户 ViewModel — 注销流程、API 调用、会话清理
final class CancelAccountViewModel: ObservableObject {

    // MARK: - Published State

    @Published var isSubmitting = false
    @Published var isSuccess = false

    // MARK: - One-shot

    let toastPublisher = PassthroughSubject<String, Never>()

    // MARK: - Dependencies

    private let userService: UserService
    private let loginService: LoginService
    private let userManager: UserManager
    private let imService: IMService

    /// 拦截注销的订单状态（V1.0 默认无订单服务，预留）
    private let unfinishedOrderStatuses: Set<String> = ["pending_use", "in_progress", "pending_review"]

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

    // MARK: - Order Check

    func hasUnfinishedOrders() -> Bool {
        // V1.0: 当前无订单服务，默认无未完成订单
        return false
    }

    // MARK: - Cancel

    func cancelAccount() {
        guard !isSubmitting else { return }
        isSubmitting = true

        Task {
            do {
                // 1. 调用注销 API
                try await userService.cancelCurrentUser()

                // 2. 清理本地状态
                await MainActor.run {
                    APIManager.shared.clearCredential()
                    loginService.clearSession()
                    userManager.clear()
                    imService.clear()
                    AppContainer.shared.serviceHubCacheService.clear()
                    AppContainer.shared.institutionSelectionStore.clear()
                    isSubmitting = false
                    isSuccess = true
                }

                // 3. 调服务端登出（fire-and-forget）
//                await loginService.logout()
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    toastPublisher.send("注销失败: \(error.localizedDescription)")
                }
            }
        }
    }
}
