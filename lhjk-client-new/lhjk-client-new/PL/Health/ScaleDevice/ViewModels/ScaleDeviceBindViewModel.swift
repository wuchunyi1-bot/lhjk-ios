import Combine
import Foundation

/// 设备绑定页 — OKOK 第一帧广播后走校验 / 绑定接口
final class ScaleDeviceBindViewModel: ObservableObject {

    enum Phase: Equatable {
        case searching
        case binding
        case failed
    }

    @Published private(set) var phase: Phase = .searching
    @Published private(set) var statusText: String = "蓝牙搜索中，请耐心等待"
    @Published private(set) var hintText: String = "请尽量将手机靠近设备，轻踩唤醒体脂秤"

    let toastPublisher = PassthroughSubject<String, Never>()
    let finishedPublisher = PassthroughSubject<Void, Never>()

    private let equipmentTypeId: String
    private let bluetoothName: String
    private let displayName: String

    private let session: ScaleBleSessionService
    private let equipmentBindService: EquipmentBindService
    private let userManager: UserManager
    private var cancellables = Set<AnyCancellable>()
    private var scanTimeoutTask: Task<Void, Never>?
    private var didHandleFirstFrame = false

    init(
        equipmentTypeId: String,
        bluetoothName: String,
        displayName: String,
        session: ScaleBleSessionService = AppContainer.shared.scaleBleSessionService,
        equipmentBindService: EquipmentBindService = AppContainer.shared.equipmentBindService,
        userManager: UserManager = AppContainer.shared.userManager
    ) {
        self.equipmentTypeId = equipmentTypeId
        self.bluetoothName = bluetoothName
        self.displayName = displayName
        self.session = session
        self.equipmentBindService = equipmentBindService
        self.userManager = userManager
    }

    func start() {
        startSearching()
    }

    func retry() {
        startSearching()
    }

    func onLeave() {
        scanTimeoutTask?.cancel()
        scanTimeoutTask = nil
        cancellables.removeAll()
        session.stopSession()
    }

    // MARK: - Private

    private func startSearching() {
        scanTimeoutTask?.cancel()
        cancellables.removeAll()
        didHandleFirstFrame = false
        phase = .searching
        statusText = "蓝牙搜索中，请耐心等待"
        hintText = "请尽量将手机靠近设备，轻踩唤醒体脂秤"

        session.realtimePublisher
            .merge(with: session.lockedPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] packet in
                self?.handleFirstFrame(packet)
            }
            .store(in: &cancellables)

        session.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payload in
                guard let self, self.phase == .searching else { return }
                let message = (payload["message"] as? String) ?? "蓝牙异常"
                self.fail(message)
            }
            .store(in: &cancellables)

        session.startSession(context: .deviceBind, restart: true)

        scanTimeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard let self, !Task.isCancelled, self.phase == .searching else { return }
            self.fail("未发现体脂秤，请轻踩唤醒后重试")
        }
    }

    private func handleFirstFrame(_ packet: OKOKScalePacket) {
        guard !didHandleFirstFrame else { return }
        didHandleFirstFrame = true
        scanTimeoutTask?.cancel()
        scanTimeoutTask = nil
        cancellables.removeAll()
        session.stopSession()

        let mac = packet.macString
        guard ScaleBleSessionService.normalizeMac(mac) != nil else {
            fail("未读取到设备 MAC")
            return
        }

        phase = .binding
        statusText = "正在绑定设备…"
        hintText = displayName

        Task { @MainActor [weak self] in
            await self?.bind(mac: mac)
        }
    }

    @MainActor
    private func bind(mac: String) async {
        do {
            try await equipmentBindService.checkEquipmentValid(
                equipmentType: equipmentTypeId,
                mac: mac
            )
        } catch {
            fail(error.localizedDescription)
            return
        }

        let check: EquipmentBindCheckResult
        do {
            check = try await equipmentBindService.checkEquipmentBind(mac: mac)
        } catch {
            fail(error.localizedDescription)
            return
        }

        if check.isAlreadyBound {
            toastPublisher.send(nonEmptyMessage(check.message, fallback: "该设备已绑定"))
            _ = await session.refreshBindingState()
            finishedPublisher.send(())
            return
        }

        do {
            let userId = userManager.resolvedUserId.flatMap { Int64($0) }
            let typeId = Int64(equipmentTypeId)
            try await equipmentBindService.bindEquipment(
                BindEquipmentRequest(
                    businessId: MonitorBusinessId.weight.rawValue,
                    userId: userId,
                    equipmentType: typeId,
                    bluetoothName: bluetoothName,
                    mac: mac
                )
            )
            toastPublisher.send("设备绑定成功")
            _ = await session.refreshBindingState()
            finishedPublisher.send(())
        } catch {
            fail(error.localizedDescription)
        }
    }

    private func fail(_ message: String) {
        scanTimeoutTask?.cancel()
        session.stopSession()
        phase = .failed
        statusText = message
        hintText = "请确认体脂秤已开机并靠近手机"
        toastPublisher.send(message)
    }

    private func nonEmptyMessage(_ raw: String?, fallback: String) -> String {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? fallback : trimmed
    }
}
