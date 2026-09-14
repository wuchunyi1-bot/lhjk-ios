import UIKit

/// App 版本检查展示（PL）：关于页手动检查 + 首页展示后自动检查
enum AppVersionCheckCoordinator {

    private static let lastOptionalPromptAtKey = "lhjk.appVersion.lastOptionalPromptAt"
    private static var isPresenting = false
    private static var isChecking = false

    /// 标记当前活跃前台会话中是否已经触发过首页自动检查，避免 Tab 切换频繁请求
    private static var hasCheckedInCurrentForegroundSession = false

    enum Mode {
        /// 关于页点击：有更新必弹；已最新 Toast
        case manual
        /// 首页展示后自动检查：强制必弹；可选更新尊重 `isRemind` + `remindTime`
        case automatic
    }

    /// 应用回到前台时重置会话标记，若当前正停留在首页则顺延触发检查
    static func notifyWillEnterForeground() {
        hasCheckedInCurrentForegroundSession = false
        if topViewController() is HomeViewController {
            checkOnHomeAppeared(delay: 0.8)
        }
    }

    /// 在打开 App 首页（HomeViewController viewDidAppear）之后延迟执行自动版本检查
    static func checkOnHomeAppeared(delay: TimeInterval = 0.8) {
        guard !hasCheckedInCurrentForegroundSession else { return }
        hasCheckedInCurrentForegroundSession = true

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            Task {
                await check(mode: .automatic)
            }
        }
    }

    @discardableResult
    static func check(
        mode: Mode,
        service: AppVersionService = AppContainer.shared.appVersionService
    ) async -> String? {
        if isChecking { return nil }
        isChecking = true
        defer { isChecking = false }

        do {
            let outcome = try await service.checkLatestVersion()
            switch outcome {
            case .upToDate:
                return mode == .manual ? "当前已经是最新版本" : nil
            case .available(let info):
                if mode == .automatic, shouldSkipOptionalPrompt(info) {
                    return nil
                }
                await MainActor.run {
                    presentUpdate(info)
                    if !info.isForce {
                        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastOptionalPromptAtKey)
                    }
                }
                return nil
            }
        } catch {
            return mode == .manual
                ? (error.localizedDescription.isEmpty ? "检查更新失败" : error.localizedDescription)
                : nil
        }
    }

    private static func shouldSkipOptionalPrompt(_ info: AppVersionCheckInfo) -> Bool {
        if info.isForce { return false }
        if !info.version.shouldRemind { return true }
        let hours = max(0, info.version.remindTime ?? 0)
        guard hours > 0 else { return false }
        let last = UserDefaults.standard.double(forKey: lastOptionalPromptAtKey)
        guard last > 0 else { return false }
        return Date().timeIntervalSince1970 < last + Double(hours) * 3600
    }

    private static func presentUpdate(_ info: AppVersionCheckInfo) {
        guard let host = topViewController() else { return }
        if host.presentedViewController is AppUpdateDialogViewController, isPresenting { return }

        isPresenting = true
        let dialog = AppUpdateDialogViewController(info: info)
        dialog.onDismiss = {
            isPresenting = false
        }
        dialog.onConfirmUpdate = {
            isPresenting = false
            openStore(info.version.storeURL, from: host)
        }
        host.present(dialog, animated: false)
    }

    private static func openStore(_ url: URL?, from host: UIViewController) {
        guard let url else {
            host.showToastAlert("暂无法打开应用市场")
            return
        }
        UIApplication.shared.open(url)
    }

    private static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let base = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
