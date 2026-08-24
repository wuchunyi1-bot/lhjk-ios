import Combine
import SnapKit
import UIKit

/// 体重 H5 顶部体脂秤蓝牙横条 — 安装、状态刷新与会话生命周期
final class WeightScaleBleStatusCoordinator {

    static var topContentInset: CGFloat {
        WeightScaleBleStatusBarView.preferredHeight + 8
    }

    private weak var hostViewController: UIViewController?
    private let bleStatusBar = WeightScaleBleStatusBarView()
    private var cancellables = Set<AnyCancellable>()
    private let scaleService = ScaleBleSessionService.shared
    private let equipmentBindService: EquipmentBindService
    private var appearTask: Task<Void, Never>?
    private var lastNavigatedMonitorId: String?
    private(set) var isVisible: Bool = true

    init(equipmentBindService: EquipmentBindService = AppContainer.shared.equipmentBindService) {
        self.equipmentBindService = equipmentBindService
    }

    func install(in host: UIViewController) {
        hostViewController = host
        guard let hostView = host.view else { return }

        hostView.addSubview(bleStatusBar)
        bleStatusBar.isHidden = !isVisible
        bleStatusBar.snp.makeConstraints { make in
            make.top.equalTo(hostView.safeAreaLayoutGuide)
            make.leading.trailing.equalTo(hostView).inset(16)
            make.height.equalTo(WeightScaleBleStatusBarView.preferredHeight)
        }
        bleStatusBar.onPrimaryAction = { [weak self] in
            self?.handleStatusBarTap()
        }

        scaleService.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, self.isVisible else { return }
                self.refreshBleStatusBar()
            }
            .store(in: &cancellables)

        AppContainer.shared.bluetoothManager.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, self.isVisible else { return }
                self.refreshBleStatusBar()
            }
            .store(in: &cancellables)

        scaleService.syncedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payload in
                guard let self, self.isVisible else { return }
                self.handleBleSynced(payload)
            }
            .store(in: &cancellables)

        if isVisible {
            refreshBleStatusBar()
            bringStatusBarToFront(on: hostView)
        }
    }

    func setVisible(_ visible: Bool) {
        guard isVisible != visible else { return }
        isVisible = visible
        bleStatusBar.isHidden = !visible
        if visible {
            bringStatusBarToFront()
            onAppear()
        } else {
            onDisappear(isLeaving: false)
        }
    }

    func bringStatusBarToFront(on hostView: UIView? = nil) {
        guard isVisible else { return }
        let container = hostView ?? hostViewController?.view
        container?.bringSubviewToFront(bleStatusBar)
    }

    func onAppear() {
        guard isVisible else { return }
        appearTask?.cancel()
        appearTask = Task { @MainActor [weak self] in
            guard let self, self.isVisible else { return }
            await self.scaleService.prepareWeightHostSession()
            guard !Task.isCancelled, self.isVisible else { return }
            self.refreshBleStatusBar()
        }
    }

    func onDisappear(isLeaving: Bool) {
        appearTask?.cancel()
        appearTask = nil
        scaleService.stopSession()
        guard isLeaving else { return }
        lastNavigatedMonitorId = nil
        scaleService.clearAutoScanPause()
    }

    // MARK: - Private

    private func handleBleSynced(_ payload: [String: Any]) {
        guard let monitorId = payload["monitorId"] as? String else { return }
        let trimmed = monitorId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != lastNavigatedMonitorId else { return }
        lastNavigatedMonitorId = trimmed

        let hasImpedance = Self.impedanceValue(from: payload) > 0
        let route = hasImpedance
            ? "/health/metrics/weight/scale/result"
            : "/health/metrics/weight/detail"

        Task { @MainActor [weak self] in
            guard let self, let host = self.hostViewController else { return }
            if !hasImpedance {
                do {
                    _ = try await self.equipmentBindService.fetchWeightHomePageData(monitorId: trimmed)
                    print("[Weight-BLE] getWeightHomePageData ok monitorId=\(trimmed)")
                } catch {
                    print("[Weight-BLE] getWeightHomePageData failed — \(error.localizedDescription)")
                }
            }
            print("[Weight-BLE] open result hasImpedance=\(hasImpedance) route=\(route) monitorId=\(trimmed)")
            Router.shared.push(
                route,
                params: ["monitorId": trimmed],
                from: host
            )
        }
    }

    private static func impedanceValue(from payload: [String: Any]) -> Double {
        if let value = payload["impedance"] as? Double { return value }
        if let value = payload["impedance"] as? NSNumber { return value.doubleValue }
        if let value = payload["impedance"] as? Int { return Double(value) }
        if let value = payload["impedance"] as? String,
           let parsed = Double(value.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return parsed
        }
        return 0
    }

    private func refreshBleStatusBar() {
        let bluetooth = AppContainer.shared.bluetoothManager
        let status = scaleService.currentStatus(metric: "weight")

        switch bluetooth.state {
        case .poweredOff:
            bleStatusBar.configure(
                style: .bluetoothUnavailable,
                message: "请打开手机蓝牙后使用体脂秤",
                actionTitle: nil
            )
        case .unauthorized, .unsupported:
            bleStatusBar.configure(
                style: .bluetoothUnavailable,
                message: "请在系统设置中允许使用蓝牙",
                actionTitle: nil
            )
        case .poweredOn:
            if !status.bound {
                bleStatusBar.configure(
                    style: .unbound,
                    message: "您尚未绑定体脂秤",
                    actionTitle: " 去绑定 "
                )
            } else if status.connected {
                bleStatusBar.configure(
                    style: .listening,
                    message: "正在连接，请轻踩唤醒设备",
                    actionTitle: nil
                )
            } else {
                let name = status.deviceName.isEmpty ? "体脂秤" : status.deviceName
                bleStatusBar.configure(
                    style: .disconnected,
                    message: "\(name) · 未连接",
                    actionTitle: "点击重试"
                )
            }
        default:
            bleStatusBar.configure(
                style: .bluetoothUnavailable,
                message: "蓝牙暂不可用",
                actionTitle: nil
            )
        }
    }

    private func handleStatusBarTap() {
        guard isVisible else { return }
        guard let host = hostViewController else { return }
        let status = scaleService.currentStatus(metric: "weight")
        let bluetooth = AppContainer.shared.bluetoothManager

        guard bluetooth.state == .poweredOn else { return }

        if !status.bound {
            Router.shared.push("/health/scale/devices", from: host)
            return
        }

        if status.connected {
            Router.shared.push("/health/scale/devices", from: host)
            return
        }

        appearTask?.cancel()
        appearTask = Task { @MainActor [weak self] in
            guard let self, self.isVisible else { return }
            await self.scaleService.resumeScanAfterUserRetry()
            guard !Task.isCancelled, self.isVisible else { return }
            self.refreshBleStatusBar()
        }
    }
}
