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
    private var appearTask: Task<Void, Never>?

    func install(in host: UIViewController) {
        hostViewController = host
        guard let hostView = host.view else { return }

        hostView.addSubview(bleStatusBar)
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
                self?.refreshBleStatusBar()
            }
            .store(in: &cancellables)

        AppContainer.shared.bluetoothManager.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshBleStatusBar()
            }
            .store(in: &cancellables)

        refreshBleStatusBar()
        bringStatusBarToFront(on: hostView)
    }

    func bringStatusBarToFront(on hostView: UIView? = nil) {
        let container = hostView ?? hostViewController?.view
        container?.bringSubviewToFront(bleStatusBar)
    }

    func onAppear() {
        appearTask?.cancel()
        appearTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.scaleService.prepareWeightHostSession()
            guard !Task.isCancelled else { return }
            self.refreshBleStatusBar()
        }
    }

    func onDisappear(isLeaving: Bool) {
        appearTask?.cancel()
        appearTask = nil
        guard isLeaving else { return }
        scaleService.stopSession()
    }

    // MARK: - Private

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
            guard let self else { return }
            await self.scaleService.prepareWeightHostSession()
            guard !Task.isCancelled else { return }
            self.refreshBleStatusBar()
        }
    }
}
