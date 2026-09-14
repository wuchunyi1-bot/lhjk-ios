import UIKit
import SnapKit
import CoreLocation
import AVFoundation
import Photos

/// 隐私设置 — 对齐 Figma 4522:6913
final class PrivacySettingsViewController: BaseViewController {

    private enum PrefKey {
        static let noticeDismissed = "fd_privacy_notice_dismissed"
        static let advisor = "priv_advisor"
        static let personalized = "priv_personalized"
    }

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var locationRow: SettingsPermissionRow?
    private var cameraRow: SettingsPermissionRow?
    private var photoRow: SettingsPermissionRow?
    private var foregroundObserver: NSObjectProtocol?

    /// 仅用于弹出系统定位授权框，须持有实例且设置 delegate
    private lazy var locationAuthManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        refreshPermissionStatus()
        installForegroundObserverIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeForegroundObserver()
    }

    override func setupUI() {
        title = "隐私设置"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        contentStack.axis = .vertical
        contentStack.spacing = SettingsStyle.cardSpacing
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(SettingsStyle.horizontalInset)
            $0.bottom.equalToSuperview().offset(-24)
            $0.width.equalTo(scrollView).offset(-SettingsStyle.horizontalInset * 2)
        }

        if !UserDefaults.standard.bool(forKey: PrefKey.noticeDismissed) {
            let banner = SettingsTipBannerView(
                message: "富德健康服务将严格保护您的隐私，您可以在此管理相关权限"
            )
            banner.onClose = { [weak self, weak banner] in
                UserDefaults.standard.set(true, forKey: PrefKey.noticeDismissed)
                guard let self, let banner else { return }
                self.contentStack.removeArrangedSubview(banner)
                banner.removeFromSuperview()
            }
            contentStack.addArrangedSubview(banner)
        }

        contentStack.addArrangedSubview(buildSystemCard())
        contentStack.addArrangedSubview(buildBusinessCard())

        refreshPermissionStatus()
    }

    // MARK: - Cards

    private func buildSystemCard() -> UIView {
        let card = SettingsDetailSectionCard(sectionTitle: "系统权限", iconImageName: "settings_system_access")

        let location = SettingsPermissionRow(
            title: "位置信息",
            status: "未开启",
            showDivider: true
        ) { [weak self] in self?.handleLocationPermissionTap() }
        locationRow = location

        let camera = SettingsPermissionRow(
            title: "相机权限",
            status: "未开启",
            showDivider: true
        ) { [weak self] in self?.handleCameraPermissionTap() }
        cameraRow = camera

        let photo = SettingsPermissionRow(
            title: "相册权限",
            status: "未开启",
            showDivider: false
        ) { [weak self] in self?.handlePhotoPermissionTap() }
        photoRow = photo

        card.setBodyViews([location, camera, photo])
        return card
    }

    private func buildBusinessCard() -> UIView {
        let card = SettingsDetailSectionCard(sectionTitle: "业务权限", iconImageName: "settings_bussiness_access")

        let advisorOn = UserDefaults.standard.object(forKey: PrefKey.advisor) as? Bool ?? true
        let personalizedOn = UserDefaults.standard.object(forKey: PrefKey.personalized) as? Bool ?? true

        let advisorToggle = SettingsToggleCell(
            model: .init(
                title: "健管师服务权限",
                subtitle: "允许服务团队查看履约所需健康信息",
                isOn: advisorOn
            ),
            showDivider: true,
            style: .notification
        )
        advisorToggle.onToggle = { [weak self] val in
            guard let self else { return }
            if !val {
                self.showAdvisorConfirmDialog { confirmed in
                    if confirmed {
                        UserDefaults.standard.set(false, forKey: PrefKey.advisor)
                        self.showToast("已关闭健管师服务权限")
                    } else {
                        advisorToggle.isOn = true
                    }
                }
            } else {
                UserDefaults.standard.set(true, forKey: PrefKey.advisor)
                self.showToast("已开启健管师服务权限")
            }
        }

        let personalizedToggle = SettingsToggleCell(
            model: .init(
                title: "个性化内容推荐",
                subtitle: "关闭后不影响核心服务，仅停止个性化推荐",
                isOn: personalizedOn
            ),
            showDivider: false,
            style: .notification
        )
        personalizedToggle.onToggle = { [weak self] val in
            UserDefaults.standard.set(val, forKey: PrefKey.personalized)
            self?.showToast(val ? "已开启个性化内容推荐" : "已关闭个性化内容推荐")
        }

        card.setBodyViews([advisorToggle, personalizedToggle])
        return card
    }

    // MARK: - Permission status

    private func refreshPermissionStatus() {
        locationRow?.statusText = permissionStatusText(isAuthorized: isLocationAuthorized())
        cameraRow?.statusText = permissionStatusText(isAuthorized: isCameraAuthorized())
        photoRow?.statusText = permissionStatusText(isAuthorized: isPhotoAuthorized())
    }

    private func permissionStatusText(isAuthorized: Bool) -> String {
        isAuthorized ? "已开启" : "未开启"
    }

    private func isLocationAuthorized() -> Bool {
        switch locationAuthStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }

    private var locationAuthStatus: CLAuthorizationStatus {
        locationAuthManager.authorizationStatus
    }

    private func isCameraAuthorized() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    private func isPhotoAuthorized() -> Bool {
        let readWrite = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if readWrite == .authorized || readWrite == .limited { return true }
        let addOnly = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        return addOnly == .authorized
    }

    /// 尚未询问过系统权限时弹出授权框；已被拒绝则只能去系统设置
    private func handleLocationPermissionTap() {
        switch locationAuthStatus {
        case .notDetermined:
            locationAuthManager.requestWhenInUseAuthorization()
        default:
            openSystemSettings()
        }
    }

    private func handleCameraPermissionTap() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.refreshPermissionStatus()
                }
            }
        default:
            openSystemSettings()
        }
    }

    private func handlePhotoPermissionTap() {
        let level = photoAccessLevel
        switch PHPhotoLibrary.authorizationStatus(for: level) {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: level) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.refreshPermissionStatus()
                }
            }
        default:
            openSystemSettings()
        }
    }

    /// 有读取说明则申请读写；否则仅申请写入，避免缺少 `NSPhotoLibraryUsageDescription` 时崩溃
    private var photoAccessLevel: PHAccessLevel {
        if Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryUsageDescription") != nil {
            return .readWrite
        }
        return .addOnly
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func installForegroundObserverIfNeeded() {
        guard foregroundObserver == nil else { return }
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshPermissionStatus()
        }
    }

    private func removeForegroundObserver() {
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
            foregroundObserver = nil
        }
    }

    // MARK: - Dialog

    private func showAdvisorConfirmDialog(completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: "关闭健管师服务权限？",
            message: "关闭后，健管师将无法查看您的健康档案、指标趋势和体检报告，可能影响健康建议的准确性。您仍可继续使用基础服务。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "暂不关闭", style: .cancel) { _ in completion(false) })
        alert.addAction(UIAlertAction(title: "确认关闭", style: .destructive) { _ in completion(true) })
        present(alert, animated: true)
    }

    private func showToast(_ message: String) {
        showToastAlert(message, duration: 1.5)
    }
}

extension PrivacySettingsViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        refreshPermissionStatus()
    }
}
