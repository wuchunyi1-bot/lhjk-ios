import SnapKit
import UIKit

/// 长辈模式。背景铺满 `settings_big_bg`，底部按钮按当前开关切换文案。
final class AccessibilitySettingsViewController: BaseViewController {

    private let backgroundView = UIImageView()
    private let actionButton = UIButton(type: .custom)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        applyTransparentNavigationBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        restoreNavigationBar()
    }

    override func setupUI() {
        title = ""
        view.backgroundColor = .white

        backgroundView.image = UIImage(named: "settings_big_bg")
        backgroundView.contentMode = .scaleAspectFill
        backgroundView.clipsToBounds = true
        view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { $0.edges.equalToSuperview() }

        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        actionButton.backgroundColor = .fdPrimary
        actionButton.layer.cornerRadius = 24
        actionButton.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
        view.addSubview(actionButton)
        actionButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(32)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
            $0.height.equalTo(48)
        }
        applyButtonTitle()
    }

    override func refreshForSeniorMode() {
        super.refreshForSeniorMode()
        applyButtonTitle()
    }

    @objc private func toggleTapped() {
        UIFont.isSeniorMode.toggle()
        applyButtonTitle()
    }

    private func applyButtonTitle() {
        let title = UIFont.isSeniorMode ? "关闭长辈模式" : "开启长辈模式"
        actionButton.setTitle(title, for: .normal)
    }

    private func applyTransparentNavigationBar() {
        guard let navigationController else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.clear]
        let backImage = UIImage.fdNavBack
        appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        backButtonAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.backButtonAppearance = backButtonAppearance
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.isTranslucent = true
    }

    private func restoreNavigationBar() {
        guard let navigationController else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .fdBg
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.fdText,
            .font: UIFont.fdFont(ofSize: 20, weight: .medium)
        ]
        let backImage = UIImage.fdNavBack
        appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        backButtonAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.backButtonAppearance = backButtonAppearance
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = .fdText
        navigationController.navigationBar.isTranslucent = false
    }
}
