import UIKit
import SnapKit

/// 安全中心 — 对齐 PRD-202 / SecuritySettingsView.vue
final class SecuritySettingsViewController: BaseViewController {

    private let passwordSetKey = "fd_login_password_set"
    private let wechatNicknameKey = "fd_wechat_nickname"

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private var phoneValueLabel: UILabel?
    private var passwordValueLabel: UILabel?
    private var wechatValueLabel: UILabel?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        refreshValues()
    }

    override func setupUI() {
        title = "安全中心"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        let statusSection = buildStatusSection()
        contentView.addSubview(statusSection)
        statusSection.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview()
        }

        let phoneLbl = makeValueLabel("—")
        phoneValueLabel = phoneLbl
        let pwdLbl = makeValueLabel("去设置")
        passwordValueLabel = pwdLbl
        let wechatLbl = makeValueLabel("未绑定")
        wechatValueLabel = wechatLbl

        let securitySection = buildListSection(
            title: "安全设置",
            rows: [
                .init(label: "修改手机号", valueView: phoneLbl, valueWarn: false) {
                    Router.shared.push("/me/settings/security/change-phone")
                },
                .init(label: "登录密码", valueView: pwdLbl, valueWarn: false) {
                    Router.shared.push("/me/settings/security/password")
                },
                .init(label: "微信授权", valueView: wechatLbl, valueWarn: false) {
                    Router.shared.push("/me/settings/security/wechat")
                },
            ]
        )
        contentView.addSubview(securitySection)
        securitySection.snp.makeConstraints {
            $0.top.equalTo(statusSection.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview()
        }

        let cancelValue = makeValueLabel("谨慎操作")
        cancelValue.textColor = UIColor(hexString: "#D47A58")
        let accountSection = buildListSection(
            title: "账号管理",
            rows: [
                .init(label: "注销账号", valueView: cancelValue, valueWarn: true) {
                    Router.shared.push("/me/settings/security/cancel-account")
                },
            ]
        )
        contentView.addSubview(accountSection)
        accountSection.snp.makeConstraints {
            $0.top.equalTo(securitySection.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-24)
        }

        refreshValues()
    }

    // MARK: - Status tip card

    private func buildStatusSection() -> UIView {
        let wrap = UIView()

        let titleLbl = UILabel()
        titleLbl.text = "账号状态"
        titleLbl.font = .fdMyCaptionSemibold
        titleLbl.textColor = .fdSubtext
        wrap.addSubview(titleLbl)
        titleLbl.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        let card = UIView()
        card.backgroundColor = UIColor(hexString: "#FFF4EC")
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdPrimaryEdge.cgColor
        wrap.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalTo(titleLbl.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }

        let iconBg = UIView()
        iconBg.backgroundColor = .fdPrimarySoft
        iconBg.layer.cornerRadius = 10
        let icon = UIImageView(image: UIImage(systemName: "lock.shield.fill"))
        icon.tintColor = .fdPrimary
        icon.contentMode = .scaleAspectFit
        iconBg.addSubview(icon)
        icon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(18)
        }

        let tipTitle = UILabel()
        tipTitle.text = "账号安全状态良好"
        tipTitle.font = .fdMyBodySemibold
        tipTitle.textColor = .fdText

        let tipDesc = UILabel()
        tipDesc.text = "已绑定手机号，建议定期更新登录密码，保护账号与健康数据安全。"
        tipDesc.font = .fdFont(ofSize: 13, weight: .regular)
        tipDesc.textColor = .fdSubtext
        tipDesc.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [tipTitle, tipDesc])
        textStack.axis = .vertical
        textStack.spacing = 3

        card.addSubview(iconBg)
        card.addSubview(textStack)
        iconBg.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(14)
            $0.size.equalTo(34)
        }
        textStack.snp.makeConstraints {
            $0.leading.equalTo(iconBg.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(14)
            $0.bottom.equalToSuperview().offset(-14)
        }

        return wrap
    }

    // MARK: - List section

    private struct RowDef {
        let label: String
        let valueView: UIView
        let valueWarn: Bool
        let action: () -> Void
    }

    private func buildListSection(title: String, rows: [RowDef]) -> UIView {
        let wrap = UIView()

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .fdMyCaptionSemibold
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

        for (idx, row) in rows.enumerated() {
            stack.addArrangedSubview(makeRow(row, showDivider: idx < rows.count - 1))
        }
        return wrap
    }

    private func makeRow(_ row: RowDef, showDivider: Bool) -> UIView {
        let control = UIControl()
        control.addAction(UIAction { _ in row.action() }, for: .touchUpInside)

        let label = UILabel()
        label.text = row.label
        label.font = .fdMyBodySemibold
        label.textColor = .fdText
        label.isUserInteractionEnabled = false

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .fdMuted
        arrow.contentMode = .scaleAspectFit
        arrow.isUserInteractionEnabled = false

        row.valueView.isUserInteractionEnabled = false

        control.addSubview(label)
        control.addSubview(row.valueView)
        control.addSubview(arrow)

        arrow.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(14)
        }
        row.valueView.snp.makeConstraints {
            $0.trailing.equalTo(arrow.snp.leading).offset(-4)
            $0.centerY.equalToSuperview()
        }
        label.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(row.valueView.snp.leading).offset(-8)
        }

        if showDivider {
            let divider = UIView()
            divider.backgroundColor = .fdBorder
            control.addSubview(divider)
            divider.snp.makeConstraints {
                $0.leading.equalTo(label)
                $0.trailing.bottom.equalToSuperview()
                $0.height.equalTo(1)
            }
        }

        control.snp.makeConstraints { $0.height.equalTo(52) }
        return control
    }

    private func makeValueLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .fdMyCaption
        l.textColor = .fdSubtext
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }

    // MARK: - Data

    private func refreshValues() {
        let mobile = UserManager.shared.currentUser?.mobile
            ?? UserDefaults.standard.string(forKey: "current_user_mobile")
        phoneValueLabel?.text = maskPhone(mobile)

        let passwordSet = UserDefaults.standard.bool(forKey: passwordSetKey)
            || !(UserManager.shared.currentUser?.pwd ?? "").isEmpty
        passwordValueLabel?.text = passwordSet ? "已设置" : "去设置"

        if let nick = UserDefaults.standard.string(forKey: wechatNicknameKey), !nick.isEmpty {
            wechatValueLabel?.text = nick
        } else if let openId = UserManager.shared.currentUser?.openIdWechat, !openId.isEmpty {
            wechatValueLabel?.text = "微信用户"
        } else {
            wechatValueLabel?.text = "未绑定"
        }
    }

    private func maskPhone(_ phone: String?) -> String {
        guard let phone, phone.count >= 7 else { return phone?.isEmpty == false ? phone! : "未绑定" }
        let digits = phone.filter(\.isNumber)
        guard digits.count == 11 else { return phone }
        return "\(digits.prefix(3))****\(digits.suffix(4))"
    }
}
