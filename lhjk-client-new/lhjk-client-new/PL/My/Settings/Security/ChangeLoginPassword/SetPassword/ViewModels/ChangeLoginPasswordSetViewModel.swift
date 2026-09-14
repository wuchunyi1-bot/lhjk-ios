import Foundation
import Combine

/// 安全中心 · 登录密码 — 设置登录密码
@MainActor
final class ChangeLoginPasswordSetViewModel: ObservableObject {

    @Published private(set) var isBusy = false

    let toast = PassthroughSubject<String, Never>()
    let didSucceed = PassthroughSubject<Void, Never>()

    private let phone: String
    private let smsCode: String
    private let userService: UserService
    private let userManager: UserManager

    init(
        phone: String,
        smsCode: String,
        userService: UserService = AppContainer.shared.userService,
        userManager: UserManager = AppContainer.shared.userManager
    ) {
        self.phone = phone
        self.smsCode = smsCode
        self.userService = userService
        self.userManager = userManager
    }

    func submit(newPassword: String, confirmPassword: String) {
        guard !newPassword.isEmpty else {
            toast.send("请设置新密码")
            return
        }
        guard newPassword.count >= 6 else {
            toast.send("新密码至少6位")
            return
        }
        guard newPassword.count <= 20 else {
            toast.send("新密码不能超过20位")
            return
        }
        guard !confirmPassword.isEmpty else {
            toast.send("请再次输入新密码")
            return
        }
        guard newPassword == confirmPassword else {
            toast.send("两次输入的密码不一致，请重新输入")
            return
        }
        guard !isBusy else { return }
        isBusy = true

        Task { [weak self] in
            guard let self else { return }
            do {
                try await userService.resetPasswordByMobile(
                    mobile: phone,
                    newPwd: newPassword,
                    checkCode: smsCode
                )
                UserDefaults.standard.set(true, forKey: "fd_login_password_set")
                await userManager.refreshUserInfo()
                isBusy = false
                toast.send("密码设置成功")
                didSucceed.send(())
            } catch {
                isBusy = false
                toast.send(error.localizedDescription)
            }
        }
    }
}
