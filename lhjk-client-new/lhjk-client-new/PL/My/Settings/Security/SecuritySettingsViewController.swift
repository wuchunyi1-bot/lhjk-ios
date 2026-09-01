import UIKit
import SnapKit

/// 安全中心 — 对齐 Figma 4449:12093
final class SecuritySettingsViewController: BaseViewController {

    private let passwordSetKey = "fd_login_password_set"
    private let wechatNicknameKey = "fd_wechat_nickname"

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private var phoneRow: SecuritySettingsRow?
    private var passwordRow: SecuritySettingsRow?
    private var wechatRow: SecuritySettingsRow?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        refreshValues()
        loadWechatBindStatus()
    }

    override func setupUI() {
        title = "安全中心"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }

        stackView.axis = .vertical
        stackView.spacing = 12
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24)
        }

        stackView.addArrangedSubview(makeStatusCard())
        stackView.addArrangedSubview(makeSecurityCard())
        stackView.addArrangedSubview(makeAccountCard())

        refreshValues()
    }

    // MARK: - Cards

    private func makeStatusCard() -> UIView {
        let card = SecuritySectionCard(sectionTitle: "账号状态", iconImageName: "security_section_status")
        card.setBodyViews([SecurityAccountStatusTipView()])
        return card
    }

    private func makeSecurityCard() -> UIView {
        let phone = SecuritySettingsRow(
            title: "修改手机号",
            value: "—",
            showDivider: true
        ) { [weak self] in
            self?.openChangePhone()
        }
        phoneRow = phone

        let password = SecuritySettingsRow(
            title: "登录密码",
            value: "去设置",
            showDivider: true
        ) { [weak self] in
            self?.openPassword()
        }
        passwordRow = password

        let wechat = SecuritySettingsRow(
            title: "微信授权",
            value: "未绑定",
            showDivider: false
        ) { [weak self] in
            self?.openWechat()
        }
        wechatRow = wechat

        let card = SecuritySectionCard(sectionTitle: "安全设置", iconImageName: "security_section_settings")
        card.setBodyViews([phone, password, wechat])
        return card
    }

    private func makeAccountCard() -> UIView {
        let cancel = SecuritySettingsRow(
            title: "注销账号",
            value: "谨慎操作",
            valueWarn: true,
            showDivider: false
        ) { [weak self] in
            self?.openCancelAccount()
        }

        let card = SecuritySectionCard(sectionTitle: "账号管理", iconImageName: "security_section_account")
        card.setBodyViews([cancel])
        return card
    }

    // MARK: - Navigation

    private func openChangePhone() {
        Router.shared.push("/me/settings/security/change-phone")
    }

    private func openPassword() {
        Router.shared.push("/me/settings/security/password")
    }

    private func openWechat() {
        Router.shared.push("/me/settings/security/wechat")
    }

    private func openCancelAccount() {
        Router.shared.push("/me/settings/security/cancel-account")
    }

    // MARK: - Data

    private func refreshValues() {
        let mobile = UserManager.shared.currentUser?.mobile
            ?? UserDefaults.standard.string(forKey: "current_user_mobile")
        phoneRow?.valueText = maskPhone(mobile)

        let passwordSet = UserDefaults.standard.bool(forKey: passwordSetKey)
            || !(UserManager.shared.currentUser?.pwd ?? "").isEmpty
        passwordRow?.valueText = passwordSet ? "已设置" : "去设置"

        if let nick = UserDefaults.standard.string(forKey: wechatNicknameKey), !nick.isEmpty {
            wechatRow?.valueText = nick
        } else if let openId = UserManager.shared.currentUser?.openIdWechat, !openId.isEmpty {
            wechatRow?.valueText = "已绑定"
        } else {
            wechatRow?.valueText = "未绑定"
        }
    }

    /// 查询微信绑定状态：`GET /v1/users/getWechatBindStatus`
    private func loadWechatBindStatus() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let status = try await UserService.shared.getWechatBindStatus()
                let isBound = status.bound ?? false
                await MainActor.run {
                    self.wechatRow?.valueText = isBound ? "已绑定" : "未绑定"
                }
            } catch {
                print("[SecuritySettings] loadWechatBindStatus ✗ \(error.localizedDescription)")
            }
        }
    }

    private func maskPhone(_ phone: String?) -> String {
        guard let phone, phone.count >= 7 else { return phone?.isEmpty == false ? phone! : "未绑定" }
        let digits = phone.filter(\.isNumber)
        guard digits.count == 11 else { return phone }
        return "\(digits.prefix(3))****\(digits.suffix(4))"
    }
}
