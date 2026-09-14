import Foundation
import Combine

/// 安全中心 · 登录密码 — 验证当前注册手机号
@MainActor
final class ChangeLoginPasswordViewModel: ObservableObject {

    @Published private(set) var maskedPhone: String
    @Published private(set) var isBusy = false

    let toast = PassthroughSubject<String, Never>()
    let codeSent = PassthroughSubject<Void, Never>()
    let didVerify = PassthroughSubject<String, Never>()

    let phone: String

    private let loginService: LoginService

    init(
        phone: String? = nil,
        loginService: LoginService = AppContainer.shared.loginService,
        userManager: UserManager = AppContainer.shared.userManager
    ) {
        let resolved = (phone ?? userManager.currentUser?.mobile
            ?? UserDefaults.standard.string(forKey: "current_user_mobile")
            ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.phone = resolved
        self.maskedPhone = Self.maskPhone(resolved)
        self.loginService = loginService
    }

    func sendCode() {
        guard Self.isValidPhone(phone) else {
            toast.send("请输入正确的手机号")
            return
        }
        guard !isBusy else { return }
        isBusy = true
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await loginService.sendVerificationCode(to: phone, type: .resetPassword)
                isBusy = false
                codeSent.send(())
                toast.send("验证码已发送")
            } catch {
                isBusy = false
                toast.send(error.localizedDescription)
            }
        }
    }

    func verify(code raw: String) {
        let code = raw.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        guard Self.isValidPhone(phone) else {
            toast.send("请输入正确的手机号")
            return
        }
        guard code.count == 6 else {
            toast.send("请输入6位验证码")
            return
        }
        guard !isBusy else { return }
        isBusy = true
        Task { [weak self] in
            guard let self else { return }
            do {
                try await loginService.checkSmsCode(
                    mobile: phone,
                    checkCode: code,
                    type: .resetPassword
                )
                isBusy = false
                didVerify.send(code)
            } catch {
                isBusy = false
                toast.send(error.localizedDescription)
            }
        }
    }

    static func maskPhone(_ phone: String) -> String {
        let digits = phone.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        guard digits.count == 11 else { return phone.isEmpty ? "—" : phone }
        return "\(digits.prefix(3))****\(digits.suffix(4))"
    }

    static func isValidPhone(_ phone: String) -> Bool {
        phone.range(of: "^1[3-9]\\d{9}$", options: .regularExpression) != nil
    }
}
