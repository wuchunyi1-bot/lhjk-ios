import Combine
import Foundation

/// 体重蓝牙状态 — 与 H5 `ble.getStatus` / `ble.statusChange` 字段一致
struct BleWeightStatus: Equatable {
    var metric: String = "weight"
    var bound: Bool
    var connected: Bool
    var deviceName: String
    var lastSyncAt: String

    var dictionary: [String: Any] {
        [
            "metric": metric,
            "bound": bound,
            "connected": connected,
            "deviceName": deviceName,
            "lastSyncAt": lastSyncAt,
        ]
    }
}

/// 会话场景 — 体重 H5 / 测量 / 设备绑定行为不同
enum ScaleSessionContext {
    /// 体重 H5：服务端已绑才上报，锁定不写入本地绑定
    case weightH5Host
    /// 测量页：仅称重 UI，锁定可写本地绑定，不上报
    case measurePage
    /// 设备绑定页：无 MAC 过滤；第一帧即交给绑定链；不上报
    case deviceBind
}

/// 服务端绑定设备快照（`getEquipmentByOne`）
private struct ServerWeightBindingState {
    let device: EquipmentUserVO

    var preferredMac: String? {
        ScaleBleSessionService.normalizeMac(device.mac)
    }

    var deviceName: String? {
        let candidates: [String?] = [
            device.bluetoothName,
            device.name,
            device.commodityName,
            device.model,
        ]
        for raw in candidates {
            let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }

    var equipmentType: String? {
        let trimmed = device.model?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

/// 体脂秤 / 体重秤 BLE 测量会话（Health BLL）
///
/// 启停 OKOK 广播 Handler；转发实时/锁定事件；向 H5 Bridge 提供 Status / synced / error。
final class ScaleBleSessionService {

    static let shared = ScaleBleSessionService()

    let realtimePublisher = PassthroughSubject<OKOKScalePacket, Never>()
    let lockedPublisher = PassthroughSubject<OKOKScalePacket, Never>()
    let statusPublisher = PassthroughSubject<BleWeightStatus, Never>()
    /// `ble.synced` payload
    let syncedPublisher = PassthroughSubject<[String: Any], Never>()
    /// `ble.error` payload
    let errorPublisher = PassthroughSubject<[String: Any], Never>()

    private(set) var lastLockedPacket: OKOKScalePacket?
    private(set) var lastDiscovery: OKOKScaleDiscovery?

    private let bluetooth: BluetoothManager
    private let equipmentBindService: EquipmentBindService
    private var handler: OKOKBroadcastScaleHandler?
    private var cancellables = Set<AnyCancellable>()
    private var isActive = false
    private var sessionContext: ScaleSessionContext = .weightH5Host
    private var preferredMacFilter: String?
    private var serverBindingState: ServerWeightBindingState?
    private var bluetoothStateCancellable: AnyCancellable?
    private var isReportingMonitor = false

    private let lastLockedStorageKey = "fd_okok_last_locked_scale"
    private let boundMacStorageKey = "fd_okok_bound_mac"
    private let boundNameStorageKey = "fd_okok_bound_name"
    private let boundProductIdStorageKey = "fd_okok_bound_product_id"

    init(
        bluetooth: BluetoothManager = AppContainer.shared.bluetoothManager,
        equipmentBindService: EquipmentBindService = AppContainer.shared.equipmentBindService
    ) {
        self.bluetooth = bluetooth
        self.equipmentBindService = equipmentBindService
        bluetoothStateCancellable = bluetooth.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                if state == .unauthorized || state == .poweredOff {
                    self.emitError(code: "bluetooth_unavailable", message: self.errorMessage(for: state))
                }
                self.publishStatus()
            }
    }

    // MARK: - 服务端绑定态

    /// 拉取最近绑定设备（`getEquipmentByOne`）；有设备返回 `true`，无设备或失败返回 `false`
    @discardableResult
    func refreshBindingState() async -> Bool {
        do {
            let device = try await equipmentBindService.fetchLastUsedDevice(category: .weight)
            guard Self.hasBoundDevice(device) else {
                applyServerBindingState(nil)
                print("[Scale-BLL] refreshBindingState — no device from getEquipmentByOne")
                return false
            }
            applyServerBindingState(device)
            let mac = serverBindingState?.preferredMac ?? "-"
            print("[Scale-BLL] refreshBindingState ok mac=\(mac)")
            return true
        } catch {
            print("[Scale-BLL] refreshBindingState failed — \(error.localizedDescription)")
            return serverBindingState != nil
        }
    }

    /// 体重 H5 进页：先查绑定设备，仅在有设备时启扫
    func prepareWeightHostSession() async {
        let hasDevice = await refreshBindingState()
        if hasDevice {
            startSession(context: .weightH5Host)
        } else {
            stopSession()
        }
    }

    /// 开始测量会话（扫描广播，不连接）
    /// - Parameter restart: `true` 时若已在扫则先停再开（绑定页需去掉 MAC 过滤）
    func startSession(context: ScaleSessionContext = .weightH5Host, restart: Bool = false) {
        if restart, isActive {
            stopSession()
        }
        sessionContext = context
        handler?.stopOnLock = (context == .weightH5Host)
        guard !isActive else {
            print("[Scale-BLL] startSession ignored — already active context=\(context) stopOnLock=\(handler?.stopOnLock == true)")
            publishStatus()
            return
        }
        guard bluetooth.state == .poweredOn else {
            print("[Scale-BLL] startSession failed — bluetooth=\(bluetooth.state)")
            emitError(code: "bluetooth_unavailable", message: errorMessage(for: bluetooth.state))
            publishStatus()
            return
        }

        isActive = true

        guard let h = BLEDeviceRegistry.shared.handler(for: .okokBroadcastScale) as? OKOKBroadcastScaleHandler else {
            isActive = false
            print("[Scale-BLL] startSession failed — OKOK handler missing")
            emitError(code: "handler_missing", message: "体重秤协议未注册")
            return
        }
        handler = h
        cancellables.removeAll()

        h.onEvent = { [weak self] event in
            self?.handle(event)
        }

        let macHint = preferredMacFilter ?? "none"
        h.stopOnLock = (context == .weightH5Host)
        print("[Scale-BLL] startSession context=\(context) macFilter=\(macHint) stopOnLock=\(h.stopOnLock) — begin broadcast scan")
        h.start(bluetooth: bluetooth)
        publishStatus()
    }

    func stopSession() {
        guard isActive else { return }
        print("[Scale-BLL] stopSession")
        isActive = false
        cancellables.removeAll()
        handler?.onEvent = nil
        handler?.stop()
        handler = nil
        publishStatus()
    }

    /// 供 Bridge `ble.getStatus`
    func statusDictionary(metric: String = "weight") -> [String: Any] {
        currentStatus(metric: metric).dictionary
    }

    func currentStatus(metric: String = "weight") -> BleWeightStatus {
        let bound = serverBindingState != nil

        let deviceName: String
        if let serverName = serverBindingState?.deviceName, !serverName.isEmpty {
            deviceName = serverName
        } else if let name = UserDefaults.standard.string(forKey: boundNameStorageKey), !name.isEmpty {
            deviceName = name
        } else if let mac = serverBindingState?.preferredMac, !mac.isEmpty {
            deviceName = "体脂秤 \(mac.suffix(5))"
        } else if let last = lastLockedPacket {
            deviceName = "体脂秤 \(last.macString.suffix(5))"
        } else {
            deviceName = ""
        }

        return BleWeightStatus(
            metric: metric,
            bound: bound,
            connected: isActive && bluetooth.state == .poweredOn,
            deviceName: deviceName,
            lastSyncAt: formattedLastSyncAt()
        )
    }

    func publishStatus() {
        statusPublisher.send(currentStatus())
    }

    // MARK: - Private

    private func applyServerBindingState(_ device: EquipmentUserVO?) {
        if let device, Self.hasBoundDevice(device) {
            serverBindingState = ServerWeightBindingState(device: device)
            preferredMacFilter = serverBindingState?.preferredMac
            if let mac = preferredMacFilter {
                UserDefaults.standard.set(mac, forKey: boundMacStorageKey)
            }
            if let name = serverBindingState?.deviceName {
                UserDefaults.standard.set(name, forKey: boundNameStorageKey)
            }
        } else {
            serverBindingState = nil
            preferredMacFilter = nil
            UserDefaults.standard.removeObject(forKey: boundMacStorageKey)
            UserDefaults.standard.removeObject(forKey: boundNameStorageKey)
            UserDefaults.standard.removeObject(forKey: boundProductIdStorageKey)
        }
        publishStatus()
    }

    private func handle(_ event: OKOKScaleEvent) {
        switch event {
        case .realtime(let discovery):
            guard acceptsDiscovery(discovery, phase: "realtime") else { return }
            lastDiscovery = discovery
            let packet = discovery.packet
            print("[Scale-BLL] 体脂秤[实时] \(discovery.identityLogLine)")
            print("[Scale-BLL] realtime \(packet.debugDescription)")
            realtimePublisher.send(packet)
            publishStatus()
        case .locked(let discovery):
            print("[Scale-BLL] incoming locked context=\(sessionContext) filter=\(preferredMacFilter ?? "none") mac=\(discovery.packet.macString)")
            guard acceptsDiscovery(discovery, phase: "locked") else { return }
            lastDiscovery = discovery
            let packet = discovery.packet
            print("[Scale-BLL] 体脂秤[锁定] \(discovery.identityLogLine)")
            print("[Scale-BLL] locked \(packet.debugDescription)")
            lastLockedPacket = packet
            lockedPublisher.send(packet)

            if sessionContext == .deviceBind {
                publishStatus()
                return
            }

            persistLocally(discovery)
            if sessionContext == .measurePage {
                bindDeviceLocally(from: discovery)
            }
            let shouldStopScanAfterLock = sessionContext == .weightH5Host
            publishStatus()
            emitSynced(for: discovery)
            if shouldStopScanAfterLock {
                print("[Scale-BLL] weight H5 locked — stop broadcast scan")
                stopSession()
            }
        }
    }

    private func acceptsDiscovery(_ discovery: OKOKScaleDiscovery, phase: String) -> Bool {
        if sessionContext == .deviceBind { return true }
        // 体重 H5 锁定帧就是本次测量，不再因 MAC 格式差异丢掉上报
        if sessionContext == .weightH5Host, phase == "locked" { return true }
        guard let filter = preferredMacFilter else { return true }
        let packetMac = Self.normalizeMac(discovery.packet.macString)
        let matched = Self.macsMatch(packetMac, filter)
        if !matched {
            print("[Scale-BLL] drop \(phase) packetMac=\(packetMac ?? "-") filter=\(filter)")
        }
        return matched
    }

    private func emitSynced(for discovery: OKOKScaleDiscovery) {
        let packet = discovery.packet
        let context = sessionContext
        // 体重 H5 锁定后保存监测数据；绑定页 / 测量页不上报
        let shouldReportToServer = context == .weightH5Host
        print("[Scale-BLL] emitSynced context=\(context) willSave=\(shouldReportToServer) weight=\(packet.weightKg)")

        Task { @MainActor [weak self] in
            guard let self else { return }
            var payload = self.makeSyncedPayload(discovery: discovery)

            if shouldReportToServer {
                if self.isReportingMonitor {
                    print("[Scale-BLL] skip saveOrUpdateMonitorData — already reporting")
                } else {
                    self.isReportingMonitor = true
                    defer { self.isReportingMonitor = false }
                    do {
                        print("[Scale-BLL] POST /v1/monitor/saveOrUpdateMonitorData weight=\(packet.weightKg) mac=\(packet.macString)")
                        let monitorId = try await self.reportLockedMeasurement(discovery: discovery)
                        if !monitorId.isEmpty {
                            payload["monitorId"] = monitorId
                        }
                        print("[Scale-BLL] saveOrUpdateMonitorData ok monitorId=\(monitorId)")
                    } catch {
                        print("[Scale-BLL] saveOrUpdateMonitorData failed — \(error.localizedDescription)")
                        self.emitError(code: "sync_failed", message: error.localizedDescription)
                    }
                }
            }

            payload["weightKg"] = packet.weightKg
            self.syncedPublisher.send(payload)
            self.publishStatus()
        }
    }

    private func makeSyncedPayload(discovery: OKOKScaleDiscovery) -> [String: Any] {
        let packet = discovery.packet
        var payload = currentStatus().dictionary
        payload["metric"] = "weight"
        payload["mac"] = packet.macString
        payload["modelCode"] = discovery.modelCode
        payload["modelName"] = discovery.modelName
        payload["bluetoothName"] = discovery.resolvedBluetoothName
        return payload
    }

    private func reportLockedMeasurement(discovery: OKOKScaleDiscovery) async throws -> String {
        let packet = discovery.packet
        let equipmentName = resolvedEquipmentName(from: discovery)
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let payload = WeightBluetoothMonitorData(
            recordTimeMs: now,
            weightKg: packet.weightKg,
            bmi: nil,
            bodyFatScaleMonitor: packet.deviceTypeIsBodyFat,
            bodyFat: nil,
            muscle: nil,
            bodyWater: nil,
            basalMetabolism: nil,
            fatVolume: nil,
            bone: nil
        )
        return try await equipmentBindService.saveWeightBluetoothMonitor(
            mac: packet.macString,
            equipmentName: equipmentName,
            payload: payload,
            equipmentType: serverBindingState?.equipmentType
        )
    }

    private func resolvedEquipmentName(from discovery: OKOKScaleDiscovery) -> String {
        if let serverName = serverBindingState?.deviceName, !serverName.isEmpty {
            return serverName
        }
        let bluetoothName = discovery.resolvedBluetoothName
        if !bluetoothName.hasPrefix("(") {
            return bluetoothName
        }
        return discovery.modelName
    }

    private func bindDeviceLocally(from discovery: OKOKScaleDiscovery) {
        let packet = discovery.packet
        UserDefaults.standard.set(packet.macString, forKey: boundMacStorageKey)
        UserDefaults.standard.set(Int(packet.productId), forKey: boundProductIdStorageKey)

        let trimmedName = discovery.resolvedBluetoothName
        if !trimmedName.hasPrefix("(") {
            UserDefaults.standard.set(trimmedName, forKey: boundNameStorageKey)
        } else if UserDefaults.standard.string(forKey: boundNameStorageKey)?.isEmpty != false {
            UserDefaults.standard.set(discovery.modelName, forKey: boundNameStorageKey)
        }
    }

    private func persistLocally(_ discovery: OKOKScaleDiscovery) {
        let packet = discovery.packet
        var payload: [String: Any] = [
            "weightKg": packet.weightKg,
            "resistanceRaw": packet.resistanceRaw,
            "mac": packet.macString,
            "productId": packet.productId,
            "modelCode": discovery.modelCode,
            "modelName": discovery.modelName,
            "serial": packet.serial,
            "measuredAt": ISO8601DateFormatter().string(from: Date()),
        ]
        if !discovery.resolvedBluetoothName.hasPrefix("(") {
            payload["bluetoothName"] = discovery.resolvedBluetoothName
        }
        UserDefaults.standard.set(payload, forKey: lastLockedStorageKey)
    }

    private func formattedLastSyncAt() -> String {
        guard let dict = UserDefaults.standard.dictionary(forKey: lastLockedStorageKey),
              let iso = dict["measuredAt"] as? String,
              let date = ISO8601DateFormatter().date(from: iso) else {
            return ""
        }
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "今天 HH:mm"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "昨天 HH:mm"
        } else {
            formatter.dateFormat = "MM-dd HH:mm"
        }
        return formatter.string(from: date)
    }

    private func emitError(code: String, message: String) {
        print("[Scale-BLL] error code=\(code) message=\(message)")
        errorPublisher.send([
            "metric": "weight",
            "code": code,
            "message": message,
        ])
    }

    private func errorMessage(for state: BluetoothState) -> String {
        switch state {
        case .poweredOff: return "请打开手机蓝牙"
        case .unauthorized: return "请在系统设置中允许蓝牙权限"
        case .unsupported: return "当前设备不支持蓝牙"
        default: return "蓝牙暂不可用"
        }
    }

    /// 统一成 `AA:BB:CC:DD:EE:FF`，兼容无分隔符 / 横线 / 小写
    static func normalizeMac(_ raw: String?) -> String? {
        guard let hex = macHex(raw) else { return nil }
        var parts: [String] = []
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            parts.append(String(hex[index..<next]))
            index = next
        }
        return parts.joined(separator: ":")
    }

    static func macsMatch(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let a = macHex(lhs), let b = macHex(rhs) else { return false }
        return a == b
    }

    private static func macHex(_ raw: String?) -> String? {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        let hex = trimmed.uppercased().filter(\.isHexDigit)
        guard hex.count >= 12 else { return nil }
        return String(hex.suffix(12))
    }

    /// `getEquipmentByOne` 返回有效设备：至少含 MAC 或 deviceId
    static func hasBoundDevice(_ device: EquipmentUserVO?) -> Bool {
        guard let device else { return false }
        if normalizeMac(device.mac) != nil { return true }
        let deviceId = device.deviceId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !deviceId.isEmpty
    }
}
