import UIKit
import SnapKit
import Kingfisher

/// 设置主页 — 对齐 Figma 3826:32412
final class SettingsViewController: BaseViewController {

    private let cacheSizeKey = "fd_settings_cache_size"
    private let defaultCacheSize = "12.8 MB"

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var generalSection: SettingsSectionCard?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        generalSection?.updateSubtitle(at: 0, text: currentCacheSizeText())
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if navigationController?.viewControllers.last is MyViewController {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }

    override func setupUI() {
        title = "设置"
        view.backgroundColor = UIColor(hexString: "#FDF6F3")

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24)
        }

        stack.addArrangedSubview(makeSection(
            title: "账号与安全",
            icon: "settings_section_account",
            items: [
                .init(
                    title: "安全中心",
                    subtitle: "手机号、密码与账号管理",
                    action: { Router.shared.push("/me/settings/security") }
                ),
            ]
        ))

        stack.addArrangedSubview(makeSection(
            title: "地址与设备",
            icon: "settings_section_address",
            items: [
                .init(
                    title: "我的地址",
                    subtitle: "收货地址管理",
                    action: { Router.shared.push("/me/settings/addresses") }
                ),
                .init(
                    title: "智能设备",
                    subtitle: "已绑定的健康监测设备",
                    action: { Router.shared.push("/me/devices") }
                ),
            ]
        ))

        stack.addArrangedSubview(makeSection(
            title: "消息提醒",
            icon: "settings_section_message",
            items: [
                .init(
                    title: "通知设置",
                    subtitle: "服务、健康与预约提醒",
                    action: { Router.shared.push("/me/settings/notifications") }
                ),
            ]
        ))

        stack.addArrangedSubview(makeSection(
            title: "隐私与协议",
            icon: "settings_section_privacy",
            items: [
                .init(
                    title: "隐私设置",
                    subtitle: "系统权限与业务授权",
                    action: { Router.shared.push("/me/settings/privacy") }
                ),
                .init(
                    title: "协议与说明",
                    subtitle: "协议、清单与权益卡规则",
                    action: { Router.shared.push("/me/settings/agreement-center") }
                ),
            ]
        ))

        let general = makeSection(
            title: "通用与支持",
            icon: "settings_section_general",
            items: [
                .init(
                    title: "清理缓存",
                    subtitle: currentCacheSizeText(),
                    action: { [weak self] in self?.handleClearCache() }
                ),
                .init(
                    title: "关于富德健康",
                    subtitle: "品牌、版本与客服信息",
                    action: { Router.shared.push("/me/settings/about") }
                ),
            ]
        )
        generalSection = general
        stack.addArrangedSubview(general)

        let logoutRow = SettingsLogoutRow { [weak self] in
            self?.handleLogout()
        }
        stack.addArrangedSubview(logoutRow)
    }

    private func makeSection(
        title: String,
        icon: String,
        items: [SettingsSectionCard.Item]
    ) -> SettingsSectionCard {
        SettingsSectionCard(sectionTitle: title, iconImageName: icon, items: items)
    }

    // MARK: - Cache

    private func currentCacheSizeText() -> String {
        UserDefaults.standard.string(forKey: cacheSizeKey) ?? defaultCacheSize
    }

    private func handleClearCache() {
        UserDefaults.standard.set("0 B", forKey: cacheSizeKey)
        generalSection?.updateSubtitle(at: 0, text: "0 B")
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache()
        URLCache.shared.removeAllCachedResponses()
        showToast("清理成功")
    }

    private func showToast(_ message: String) {
        showToastAlert(message, duration: 1.5)
    }

    // MARK: - Logout

    private func handleLogout() {
        let alert = UIAlertController(
            title: "确认退出登录",
            message: "退出后需要重新登录才能使用富德健康。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "退出登录", style: .destructive) { _ in
            Task {
                await LoginService.shared.logout()
                LoginService.shared.clearSession()
                IMService.shared.clear()
                await ServiceHubCacheService.shared.clear()
                await ColumnContentCacheService.shared.clear()
                await HealthPageCacheService.shared.clear()
                InstitutionSelectionStore.shared.clear()
                RongCloudManager.shared.disconnect()
                UserManager.shared.clear()
                await MainActor.run {
                    Router.shared.setRoot("/login")
                }
            }
        })
        present(alert, animated: true)
    }
}
