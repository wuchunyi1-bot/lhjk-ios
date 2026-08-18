import UIKit
import SnapKit
import Kingfisher

/// 设置主页 — 对齐 funde-client `SettingsView.vue`
final class SettingsViewController: BaseViewController {

    private let cacheSizeKey = "fd_settings_cache_size"
    private let defaultCacheSize = "12.8 MB"

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private weak var cacheRow: SettingsHubItemRow?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        cacheRow?.descText = currentCacheSizeText()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if navigationController?.viewControllers.last is MyViewController {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }

    override func setupUI() {
        title = "设置"
        view.backgroundColor = UIColor(hexString: "#FFF8F4")

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        let groups: [(title: String, items: [SettingsItem])] = [
            ("账号与安全", [
                .link(
                    title: "安全中心",
                    desc: "手机号、密码与账号管理",
                    icon: "lock.shield",
                    route: "/me/settings/security"
                ),
            ]),
            ("地址与设备", [
                .link(
                    title: "我的地址",
                    desc: "收货地址管理",
                    icon: "mappin.and.ellipse",
                    route: "/me/settings/addresses"
                ),
                .link(
                    title: "智能设备",
                    desc: "已绑定的健康监测设备",
                    icon: "applewatch",
                    route: "/me/devices"
                ),
            ]),
            ("消息提醒", [
                .link(
                    title: "通知设置",
                    desc: "服务、健康与预约提醒",
                    icon: "bell",
                    route: "/me/settings/notifications"
                ),
            ]),
            ("隐私与协议", [
                .link(
                    title: "隐私设置",
                    desc: "系统权限与业务授权",
                    icon: "hand.raised",
                    route: "/me/settings/privacy"
                ),
                .link(
                    title: "协议与说明",
                    desc: "协议、清单与权益卡规则",
                    icon: "doc.text",
                    route: "/me/settings/agreement-center"
                ),
            ]),
            ("通用与支持", [
                .clearCache(
                    title: "清理缓存",
                    icon: "paintbrush"
                ),
                .link(
                    title: "关于富德健康",
                    desc: "品牌、版本与客服信息",
                    icon: "info.circle",
                    route: "/me/settings/about"
                ),
            ]),
        ]

        var lastBottom = contentView.snp.top

        for (idx, group) in groups.enumerated() {
            let section = buildGroup(title: group.title, items: group.items)
            contentView.addSubview(section)
            section.snp.makeConstraints { make in
                make.top.equalTo(lastBottom).offset(idx == 0 ? 12 : 14)
                make.leading.trailing.equalToSuperview()
            }
            lastBottom = section.snp.bottom
        }

        let logoutWrap = buildLogoutButton()
        contentView.addSubview(logoutWrap)
        logoutWrap.snp.makeConstraints { make in
            make.top.equalTo(lastBottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24)
        }
    }

    // MARK: - Build

    private enum SettingsItem {
        case link(title: String, desc: String, icon: String, route: String)
        case clearCache(title: String, icon: String)
    }

    private func buildGroup(title: String, items: [SettingsItem]) -> UIView {
        let wrap = UIView()

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .fdCaptionSemibold
        titleLbl.textColor = .fdSubtext
        wrap.addSubview(titleLbl)
        titleLbl.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        wrap.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalTo(titleLbl.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }

        let stack = UIStackView()
        stack.axis = .vertical
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        for (idx, item) in items.enumerated() {
            let showDivider = idx < items.count - 1
            switch item {
            case let .link(title, desc, icon, route):
                stack.addArrangedSubview(
                    SettingsHubItemRow(
                        title: title,
                        desc: desc,
                        systemImage: icon,
                        showDivider: showDivider,
                        action: { Router.shared.push(route) }
                    )
                )
            case let .clearCache(title, icon):
                let row = SettingsHubItemRow(
                    title: title,
                    desc: currentCacheSizeText(),
                    systemImage: icon,
                    showDivider: showDivider,
                    action: { [weak self] in self?.handleClearCache() }
                )
                cacheRow = row
                stack.addArrangedSubview(row)
            }
        }

        return wrap
    }

    private func buildLogoutButton() -> UIView {
        let wrap = UIView()
        let btn = UIButton(type: .system)
        btn.setTitle("退出登录", for: .normal)
        btn.setTitleColor(.fdDanger, for: .normal)
        btn.titleLabel?.font = .fdH3
        btn.backgroundColor = .fdSurface
        btn.layer.cornerRadius = 12
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 1)
        btn.layer.shadowRadius = 6
        btn.layer.shadowOpacity = 0.03
        btn.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
        wrap.addSubview(btn)
        btn.snp.makeConstraints { $0.edges.equalToSuperview(); $0.height.equalTo(48) }
        return wrap
    }

    // MARK: - Cache

    private func currentCacheSizeText() -> String {
        UserDefaults.standard.string(forKey: cacheSizeKey) ?? defaultCacheSize
    }

    private func handleClearCache() {
        UserDefaults.standard.set("0 B", forKey: cacheSizeKey)
        cacheRow?.descText = "0 B"
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache()
        URLCache.shared.removeAllCachedResponses()
        showToast("清理成功")
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }

    // MARK: - Logout

    @objc private func handleLogout() {
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
