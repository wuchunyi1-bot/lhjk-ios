import UIKit

/// 隐私设置页
/// 参考 funde-client: prototype/src/views/me/settings/PrivacySettingsView.vue
/// PRD: 02_用户_我的设置_v1.0 §5.7
///
/// Notice 提示条 + 系统权限卡片 + 业务授权卡片：
///   Card 1: 位置信息 / 相机权限 / 相册权限（系统权限引导）
///   Card 2: 健管师服务授权 / 个性化内容推荐（toggle switches）
final class PrivacySettingsViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let storageKeys = (
        advisor: "priv_advisor",
        personalized: "priv_personalized"
    )

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = "隐私设置"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        // MARK: Notice Banner

        let noticeBanner: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hexString: "#FFF3EE")
            v.layer.cornerRadius = 12
            v.layer.borderWidth = 1
            v.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.18).cgColor
            let lbl = UILabel()
            lbl.text = "富德健康将严格保护您的隐私。您可以在此管理相关权限："
            lbl.font = .fdCaption
            lbl.textColor = .fdPrimary
            lbl.numberOfLines = 0
            v.addSubview(lbl)
            lbl.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
            return v
        }()
        contentView.addSubview(noticeBanner)
        noticeBanner.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        // MARK: Card 1 — System Permissions

        let sysItems: [(label: String, icon: String)] = [
            ("位置信息", "location"),
            ("相机权限", "camera"),
            ("相册权限", "photo"),
        ]
        let card1 = buildCard()
        let stack1 = UIStackView(); stack1.axis = .vertical
        card1.addSubview(stack1); stack1.snp.makeConstraints { $0.edges.equalToSuperview() }
        for (i, item) in sysItems.enumerated() {
            let row = makeLinkRow(label: item.label, value: "已开启", showDivider: i < sysItems.count - 1)
            row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSystemPermissionTap(_:))))
            row.accessibilityLabel = item.label
            stack1.addArrangedSubview(row)
        }

        contentView.addSubview(card1)
        card1.snp.makeConstraints { make in
            make.top.equalTo(noticeBanner.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        // MARK: Card 2 — Business Authorization Toggles

        let advisorOn = UserDefaults.standard.object(forKey: storageKeys.advisor) as? Bool ?? true
        let personalizedOn = UserDefaults.standard.object(forKey: storageKeys.personalized) as? Bool ?? true

        let card2 = buildCard()
        let stack2 = UIStackView(); stack2.axis = .vertical
        card2.addSubview(stack2); stack2.snp.makeConstraints { $0.edges.equalToSuperview() }

        let advisorToggle = SettingsToggleCell(
            model: SettingsToggleCell.Model(
                title: "健管师服务授权",
                subtitle: "允许服务团队查看履约所需的健康信息",
                isOn: advisorOn
            ),
            showDivider: true
        )
        advisorToggle.onToggle = { [weak self] val in
            if !val {
                self?.showAdvisorConfirmDialog { confirmed in
                    if confirmed {
                        UserDefaults.standard.set(false, forKey: self?.storageKeys.advisor ?? "")
                        self?.showToast("已关闭健管师服务授权")
                    } else {
                        advisorToggle.isOn = true
                    }
                }
            } else {
                UserDefaults.standard.set(true, forKey: self?.storageKeys.advisor ?? "")
                self?.showToast("已开启健管师服务授权")
            }
        }
        stack2.addArrangedSubview(advisorToggle)

        let personalizedToggle = SettingsToggleCell(
            model: SettingsToggleCell.Model(
                title: "个性化内容推荐",
                subtitle: "基于您的行为和健康偏好展示相关内容",
                isOn: personalizedOn
            ),
            showDivider: false
        )
        personalizedToggle.onToggle = { [weak self] val in
            UserDefaults.standard.set(val, forKey: self?.storageKeys.personalized ?? "")
            self?.showToast(val ? "已开启个性化内容推荐" : "已关闭个性化内容推荐")
        }
        stack2.addArrangedSubview(personalizedToggle)

        contentView.addSubview(card2)
        card2.snp.makeConstraints { make in
            make.top.equalTo(card1.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    // MARK: - Builders

    private func buildCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        return card
    }

    private func makeLinkRow(label: String, value: String, showDivider: Bool) -> UIView {
        let row = UIView(); row.isUserInteractionEnabled = true

        let titleLbl = UILabel()
        titleLbl.text = label
        titleLbl.font = .fdBody
        titleLbl.textColor = .fdText

        let valueLbl = UILabel()
        valueLbl.text = value
        valueLbl.font = .fdCaption
        valueLbl.textColor = .fdSubtext

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .fdMuted; arrow.contentMode = .scaleAspectFit

        [titleLbl, valueLbl, arrow].forEach(row.addSubview)
        arrow.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview(); $0.size.equalTo(16) }
        valueLbl.snp.makeConstraints { $0.trailing.equalTo(arrow.snp.leading).offset(-4); $0.centerY.equalToSuperview() }
        titleLbl.snp.makeConstraints { $0.leading.equalToSuperview().inset(16); $0.centerY.equalToSuperview(); $0.trailing.lessThanOrEqualTo(valueLbl.snp.leading).offset(-8) }

        if showDivider {
            let divider = UIView(); divider.backgroundColor = .fdBorder
            row.addSubview(divider)
            divider.snp.makeConstraints { $0.leading.equalTo(titleLbl); $0.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
        }
        row.snp.makeConstraints { $0.height.equalTo(48) }
        return row
    }

    // MARK: - Actions

    @objc private func handleSystemPermissionTap(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view?.accessibilityLabel else { return }
        showToast("请在系统设置中修改「\(label)」权限")
    }

    private func showAdvisorConfirmDialog(completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: "关闭健管师服务授权？",
            message: "关闭后，健管师将无法查看您的健康档案、指标趋势和体检报告，可能影响健康建议的准确性。您仍可继续使用基础服务。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "暂不关闭", style: .cancel) { _ in completion(false) })
        alert.addAction(UIAlertAction(title: "确认关闭", style: .destructive) { _ in completion(true) })
        present(alert, animated: true)
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
