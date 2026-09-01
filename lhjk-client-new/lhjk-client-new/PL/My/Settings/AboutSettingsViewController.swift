import UIKit
import SnapKit

/// 关于富德健康 — 对齐 Figma 4540:7866
final class AboutSettingsViewController: BaseViewController {

    private let scrollView = UIScrollView()

    private var appVersionText: String {
        let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return "V\(ver)"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = "关于富德健康"
        view.backgroundColor = .fdBg

        let footer = buildFooter()
        view.addSubview(footer)
        footer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(SettingsStyle.horizontalInset)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
        }

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(footer.snp.top).offset(-16)
        }

        let card = buildInfoCard()
        scrollView.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(SettingsStyle.horizontalInset)
            $0.width.equalTo(scrollView).offset(-SettingsStyle.horizontalInset * 2)
            $0.bottom.equalToSuperview()
        }
    }

    // MARK: - Card

    private func buildInfoCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = SettingsStyle.cardRadius
        card.clipsToBounds = true

        let brandImageView = UIImageView(image: UIImage(named: "settings_about"))
        brandImageView.contentMode = .scaleAspectFit
        brandImageView.accessibilityLabel = "富德联好健康"

        let brandDivider = SettingsDivider.make()

        let versionRow = SettingsInfoRow(
            title: "当前版本",
            value: appVersionText,
            showChevron: true,
            showDivider: true
        ) { [weak self] in
            self?.handleVersionTap()
        }

        let ratingRow = SettingsInfoRow(
            title: "去应用市场评分",
            value: "去评分",
            showChevron: true,
            showDivider: true
        ) { [weak self] in
            self?.handleRatingTap()
        }

        let contactRow = SettingsInfoRow(
            title: "联系我们",
            value: "400-999-6520",
            showChevron: true,
            showDivider: false
        ) { [weak self] in
            self?.handleContactTap()
        }

        let rowsStack = UIStackView(arrangedSubviews: [versionRow, ratingRow, contactRow])
        rowsStack.axis = .vertical
        rowsStack.spacing = 0

        card.addSubview(brandImageView)
        card.addSubview(brandDivider)
        card.addSubview(rowsStack)

        brandImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(SettingsStyle.cardPadding)
            make.trailing.lessThanOrEqualToSuperview().offset(-SettingsStyle.cardPadding)
            make.height.equalTo(52)
        }

        brandDivider.snp.makeConstraints { make in
            make.top.equalTo(brandImageView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(SettingsStyle.cardPadding)
        }

        rowsStack.snp.makeConstraints { make in
            make.top.equalTo(brandDivider.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(SettingsStyle.cardPadding)
            make.bottom.equalToSuperview().offset(-SettingsStyle.cardPadding)
        }

        return card
    }

    // MARK: - Footer

    private func buildFooter() -> UIView {
        let copyright = UILabel()
        copyright.text = "Copyright © 2026 富德健康"
        copyright.font = SettingsStyle.footerFont
        copyright.textColor = SettingsStyle.valueColor
        copyright.textAlignment = .center

        let icp = UILabel()
        icp.text = "粤ICP备2023016723号-1"
        icp.font = SettingsStyle.footerFont
        icp.textColor = SettingsStyle.valueColor
        icp.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [copyright, icp])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .fill
        return stack
    }

    // MARK: - Actions

    private func handleVersionTap() {
        showToast("当前已经是最新版本")
    }

    private func handleRatingTap() {
        showToast("暂无法打开应用市场")
    }

    private func handleContactTap() {
        guard let url = URL(string: "tel://4009996520") else { return }
        UIApplication.shared.open(url)
    }

    private func showToast(_ message: String) {
        showToastAlert(message, duration: 1.5)
    }
}
