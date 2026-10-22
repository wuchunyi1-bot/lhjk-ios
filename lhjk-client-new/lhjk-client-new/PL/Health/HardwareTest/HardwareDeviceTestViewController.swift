import BenecareDeviceSdk
import SnapKit
import UIKit

/// 心电仪 SDK 连接测试页。不打开监测控制器，只走 `DeviceSdk` 的扫描和连接，并把每个回调打到控制台。
final class HardwareDeviceTestViewController: BaseViewController, DeviceSdkDelegate {

    private let sdk = DeviceSdk()
    private var initializeStarted = false
    private var initializeSucceeded = false
    private var tornDown = false
    private var disposeStarted = false
    private var connectIssued = false

    private let statusLabel = UILabel()
    private let connectButton = UIButton(type: .system)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            tearDownSdk()
        }
    }

    deinit {
        tearDownSdk()
    }

    override func setupUI() {
        title = "测试硬件设备"
        view.backgroundColor = .fdBg

        statusLabel.font = .fdBody
        statusLabel.textColor = .fdSubtext
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.text = "点击连接后，SDK 会扫描心电设备并连接信号最强的一台。回调内容在控制台，前缀 [HardwareTest]。"

        connectButton.setTitle("连接", for: .normal)
        connectButton.titleLabel?.font = .fdBodySemibold
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.backgroundColor = .fdPrimary
        connectButton.layer.cornerRadius = 24
        connectButton.addTarget(self, action: #selector(handleConnectTap), for: .touchUpInside)

        view.addSubview(statusLabel)
        view.addSubview(connectButton)
        statusLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(48)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        connectButton.snp.makeConstraints {
            $0.top.equalTo(statusLabel.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(48)
            $0.height.equalTo(48)
        }
    }

    @objc private func handleConnectTap() {
        guard !initializeStarted, !tornDown else { return }
        initializeStarted = true
        connectButton.isEnabled = false
        connectButton.alpha = 0.5
        statusLabel.text = "正在初始化 SDK"
        BluetoothManager.shared.stopScan()
        HardwareDeviceTestLog.line("initialize storageNamespace=hardware_test")
        let sdk = self.sdk
        sdk.initialize(SdkConfig(storageNamespace: "hardware_test")) { [weak self] info, error in
            HardwareDeviceTestLog.sdkInfo(info, error: error)
            guard let self, !self.tornDown else {
                if info != nil {
                    sdk.dispose { HardwareDeviceTestLog.completion("dispose", $0) }
                }
                return
            }
            guard error == nil else {
                self.initializeStarted = false
                self.connectButton.isEnabled = true
                self.connectButton.alpha = 1
                self.statusLabel.text = "初始化失败，见控制台"
                return
            }
            self.initializeSucceeded = true
            self.statusLabel.text = "正在订阅设备事件"
            sdk.setDelegate(self, waveform: true) { [weak self] error in
                HardwareDeviceTestLog.completion("setDelegate waveform=true", error)
                guard let self, !self.tornDown else { return }
                guard error == nil else {
                    self.statusLabel.text = "订阅失败，见控制台"
                    return
                }
                self.startConnection()
            }
        }
    }

    private func startConnection() {
        statusLabel.text = "正在读取本地绑定"
        sdk.getBoundDevice { [weak self] identity, error in
            HardwareDeviceTestLog.identity("getBoundDevice", identity, error: error)
            guard let self, !self.tornDown else { return }
            guard error == nil else {
                self.statusLabel.text = "读取绑定失败，见控制台"
                return
            }
            if identity != nil {
                self.statusLabel.text = "已有绑定，正在连接"
                self.issueConnectBound()
            } else {
                self.statusLabel.text = "未绑定，正在扫描"
                self.issueScan()
            }
        }
    }

    private func issueConnectBound() {
        guard !connectIssued else { return }
        connectIssued = true
        HardwareDeviceTestLog.line("connectBoundDevice")
        sdk.connectBoundDevice { [weak self] error in
            HardwareDeviceTestLog.completion("connectBoundDevice", error)
            guard let self else { return }
            if error != nil {
                self.connectIssued = false
                self.statusLabel.text = "连接已绑定设备失败，见控制台"
            }
        }
    }

    private func issueScan() {
        HardwareDeviceTestLog.line("startScan")
        sdk.startScan { [weak self] error in
            HardwareDeviceTestLog.completion("startScan", error)
            guard let self, !self.tornDown else { return }
            if error != nil {
                self.statusLabel.text = "扫描失败，见控制台"
            } else {
                self.statusLabel.text = "扫描中"
            }
        }
    }

    private func tearDownSdk() {
        tornDown = true
        guard initializeSucceeded, !disposeStarted else { return }
        disposeStarted = true
        let sdk = sdk
        HardwareDeviceTestLog.line("setDelegate(nil) then dispose")
        sdk.setDelegate(nil, waveform: false) { error in
            HardwareDeviceTestLog.completion("setDelegate(nil)", error)
            sdk.dispose { HardwareDeviceTestLog.completion("dispose", $0) }
        }
    }

    func deviceSdkDidUpdateStatus(_ status: DeviceStatus) {
        statusLabel.text = "链路 \(status.linkState)"
        HardwareDeviceTestLog.status(status)
    }

    func deviceSdkDidDiscover(_ devices: [DiscoveredDevice]) {
        HardwareDeviceTestLog.devices(devices)
        guard !connectIssued, !tornDown, let device = devices.max(by: { $0.rssi < $1.rssi }) else { return }
        connectIssued = true
        statusLabel.text = "正在连接 \(device.name)"
        HardwareDeviceTestLog.line("connect deviceId=\(device.deviceId) mac=\(device.mac) name=\(device.name) rssi=\(device.rssi)")
        sdk.connect(device.deviceId) { [weak self] error in
            HardwareDeviceTestLog.completion("connect", error)
            guard let self else { return }
            if error != nil {
                self.connectIssued = false
                self.statusLabel.text = "连接失败，见控制台"
            }
        }
    }

    func deviceSdkDidChangeBinding(_ identity: DeviceIdentity?) {
        HardwareDeviceTestLog.identity("bindingChanged", identity, error: nil)
    }

    func deviceSdkDidScan(_ identity: DeviceIdentity, viewId: String) {
        HardwareDeviceTestLog.line("scanCompleted viewId=\(viewId) mac=\(identity.mac) sn=\(identity.sn ?? "nil")")
    }

    func deviceSdkDidCancelScan(viewId: String) {
        HardwareDeviceTestLog.line("scanCancelled viewId=\(viewId)")
    }

    func deviceSdkDidReceiveWaveform(_ chunk: WaveformChunk) {
        DispatchQueue.global(qos: .utility).async {
            HardwareDeviceTestLog.waveform(chunk)
        }
    }

    func deviceSdkWaveformReady(sessionId: Int64) {
        statusLabel.text = "波形就绪 session=\(sessionId)"
        HardwareDeviceTestLog.line("waveformReady sessionId=\(sessionId)")
    }

    func deviceSdkDidFail(_ error: NSError) {
        statusLabel.text = "设备错误，见控制台"
        HardwareDeviceTestLog.failure("deviceSdkDidFail", error)
    }
}

private enum HardwareDeviceTestLog {
    static func line(_ message: String) {
        print("[HardwareTest] \(message)")
    }

    static func completion(_ name: String, _ error: NSError?) {
        if let error {
            failure(name, error)
        } else {
            line("\(name) success")
        }
    }

    static func failure(_ name: String, _ error: NSError) {
        let sdkCode = error.userInfo["sdkCode"] as? String ?? "nil"
        line("\(name) error sdkCode=\(sdkCode) domain=\(error.domain) code=\(error.code) message=\(error.localizedDescription) userInfo=\(error.userInfo)")
    }

    static func sdkInfo(_ info: SdkInfo?, error: NSError?) {
        if let error {
            failure("initialize", error)
            return
        }
        guard let info else {
            line("initialize success info=nil")
            return
        }
        line("initialize success sdkVersion=\(info.sdkVersion) protocolVersion=\(info.protocolVersion) capabilities=\(info.capabilities)")
    }

    static func identity(_ name: String, _ identity: DeviceIdentity?, error: NSError?) {
        if let error {
            failure(name, error)
            return
        }
        guard let identity else {
            line("\(name) identity=nil")
            return
        }
        line("\(name) mac=\(identity.mac) sn=\(identity.sn ?? "nil")")
    }

    static func status(_ status: DeviceStatus) {
        let leads = status.leadStates
            .map { "\($0.key)=\($0.value)" }
            .sorted()
            .joined(separator: ",")
        let holter = status.holter
        line(
            "status link=\(status.linkState) battery=\(text(status.battery)) heartRate=\(text(status.heartRate)) charging=\(status.charging) family=\(status.family) sampleRate=\(status.sampleRate) firmware=\(status.firmwareVersion) deviceId=\(status.deviceId) mac=\(status.mac) leadStates={\(leads)} availableLeads=\(status.availableLeads) holter known=\(holter.known) starting=\(holter.starting) recording=\(holter.recording) elapsed=\(text(holter.elapsedSeconds)) remaining=\(text(holter.remainingSeconds))"
        )
    }

    static func devices(_ devices: [DiscoveredDevice]) {
        let body = devices.map {
            "{deviceId=\($0.deviceId) mac=\($0.mac) name=\($0.name) rssi=\($0.rssi) family=\($0.family)}"
        }.joined(separator: " ")
        line("discover count=\(devices.count) \(body)")
    }

    static func waveform(_ chunk: WaveformChunk) {
        let leads = chunk.leads.keys.sorted().map { key -> String in
            let values = chunk.leads[key]?.map(\.stringValue).joined(separator: ",") ?? ""
            return "\(key)=[\(values)]"
        }.joined(separator: " ")
        line("waveform sessionId=\(chunk.sessionId) sequence=\(chunk.sequence) sampleRate=\(chunk.sampleRate) cleared=\(chunk.cleared) unit=\(chunk.unit) processing=\(chunk.processing) leads=\(leads)")
    }

    private static func text(_ number: NSNumber?) -> String {
        number?.stringValue ?? "nil"
    }
}
