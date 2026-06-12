import CoreBluetooth
import Combine

// MARK: - 蓝牙状态枚举

/// BLE 中心管理器状态
enum BluetoothState {
    case poweredOn
    case poweredOff
    case unauthorized
    case unsupported
    case unknown

    init(from cbState: CBManagerState) {
        switch cbState {
        case .poweredOn:  self = .poweredOn
        case .poweredOff: self = .poweredOff
        case .unauthorized: self = .unauthorized
        case .unsupported: self = .unsupported
        case .unknown, .resetting: self = .unknown
        @unknown default: self = .unknown
        }
    }
}

// MARK: - BluetoothManager (DAL)

/// 蓝牙管理器 — 封装 CoreBluetooth CBCentralManager
final class BluetoothManager: NSObject {

    // MARK: - Singleton

    static let shared = BluetoothManager()

    // MARK: - Publishers

    /// 蓝牙状态变化
    let statePublisher = PassthroughSubject<BluetoothState, Never>()
    /// 发现的设备列表
    let discoveredPeripheralsPublisher = PassthroughSubject<Peripheral, Never>()
    /// 连接状态变化
    let connectionPublisher = PassthroughSubject<(UUID, Bool), Never>()
    /// 收到的数据
    let dataReceivedPublisher = PassthroughSubject<(CBUUID, Data), Never>()

    // MARK: - Private Properties

    private var centralManager: CBCentralManager!
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    private var connectedPeripherals: [UUID: CBPeripheral] = [:]
    private var peripheralServices: [UUID: [BLEService]] = [:]
    private var connectionRetryCount: [UUID: Int] = [:]

    private let maxRetryCount = 3

    // MARK: - Initialization

    private override init() {
        super.init()
        centralManager = CBCentralManager(
            delegate: self,
            queue: DispatchQueue(label: "com.lhjk.bluetooth"),
            options: [CBCentralManagerOptionShowPowerAlertKey: true]
        )
    }
}

// MARK: - Public API: Scanning

extension BluetoothManager {
    /// 开始扫描指定服务的设备
    func startScan(serviceUUIDs: [CBUUID]? = nil) {
        guard centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(
            withServices: serviceUUIDs,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    /// 停止扫描
    func stopScan() {
        centralManager.stopScan()
    }
}

// MARK: - Public API: Connection

extension BluetoothManager {
    /// 连接设备
    func connect(_ peripheral: Peripheral) {
        guard let cbPeripheral = discoveredPeripherals[peripheral.identifier] else { return }
        connectionRetryCount[peripheral.identifier] = 0
        centralManager.connect(cbPeripheral, options: nil)
    }

    /// 断开设备
    func disconnect(_ peripheral: Peripheral) {
        guard let cbPeripheral = connectedPeripherals[peripheral.identifier] else { return }
        centralManager.cancelPeripheralConnection(cbPeripheral)
    }
}

// MARK: - Public API: Data Communication

extension BluetoothManager {
    /// 读取特征值
    func readValue(for characteristic: BLECharacteristic, peripheral identifier: UUID) {
        guard let peripheral = connectedPeripherals[identifier],
              let service = peripheral.services?.first(where: { _ in true }),
              let cbCharacteristic = service.characteristics?.first(where: { $0.uuid == characteristic.uuid })
        else { return }
        peripheral.readValue(for: cbCharacteristic)
    }

    /// 写入特征值
    func writeValue(_ data: Data, for characteristic: BLECharacteristic, peripheral identifier: UUID, withResponse: Bool = true) {
        guard let peripheral = connectedPeripherals[identifier],
              let service = peripheral.services?.first(where: { _ in true }),
              let cbCharacteristic = service.characteristics?.first(where: { $0.uuid == characteristic.uuid })
        else { return }
        let type: CBCharacteristicWriteType = withResponse ? .withResponse : .withoutResponse
        peripheral.writeValue(data, for: cbCharacteristic, type: type)
    }

    /// 订阅/取消订阅 Notify
    func setNotify(_ enabled: Bool, for characteristic: BLECharacteristic, peripheral identifier: UUID) {
        guard let peripheral = connectedPeripherals[identifier],
              let service = peripheral.services?.first(where: { _ in true }),
              let cbCharacteristic = service.characteristics?.first(where: { $0.uuid == characteristic.uuid })
        else { return }
        peripheral.setNotifyValue(enabled, for: cbCharacteristic)
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = BluetoothState(from: central.state)
        statePublisher.send(state)
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        discoveredPeripherals[peripheral.identifier] = peripheral
        let model = Peripheral(
            identifier: peripheral.identifier,
            name: peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String,
            rssi: RSSI.intValue
        )
        discoveredPeripheralsPublisher.send(model)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripherals[peripheral.identifier] = peripheral
        connectionRetryCount.removeValue(forKey: peripheral.identifier)
        connectionPublisher.send((peripheral.identifier, true))

        // 自动发现服务
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let currentRetry = connectionRetryCount[peripheral.identifier] ?? 0
        if currentRetry < maxRetryCount {
            connectionRetryCount[peripheral.identifier] = currentRetry + 1
            centralManager.connect(peripheral, options: nil)
        } else {
            connectionRetryCount.removeValue(forKey: peripheral.identifier)
            connectionPublisher.send((peripheral.identifier, false))
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        connectedPeripherals.removeValue(forKey: peripheral.identifier)
        peripheralServices.removeValue(forKey: peripheral.identifier)
        connectionPublisher.send((peripheral.identifier, false))
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        var bleServices: [BLEService] = []
        for service in services {
            bleServices.append(BLEService(uuid: service.uuid))
            peripheral.discoverCharacteristics(nil, for: service)
        }
        peripheralServices[peripheral.identifier] = bleServices
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard let characteristics = service.characteristics else { return }
        let bleCharacteristics: [BLECharacteristic] = characteristics.map {
            BLECharacteristic(uuid: $0.uuid, properties: $0.properties)
        }
        if let index = peripheralServices[peripheral.identifier]?.firstIndex(where: { $0.uuid == service.uuid }) {
            peripheralServices[peripheral.identifier]?[index].characteristics = bleCharacteristics
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard let data = characteristic.value else { return }
        dataReceivedPublisher.send((characteristic.uuid, data))
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let index = peripheralServices[peripheral.identifier]?
            .flatMap({ $0.characteristics })
            .firstIndex(where: { $0.uuid == characteristic.uuid })
        {
            // 更新 Notify 状态（通过索引遍历更新）
            for (serviceIndex, var service) in peripheralServices[peripheral.identifier]?.enumerated() ?? [].enumerated() {
                // 简化处理：标记状态
                _ = service
            }
        }
    }
}
