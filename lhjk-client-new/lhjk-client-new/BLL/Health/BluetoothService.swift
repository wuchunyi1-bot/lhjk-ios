import Combine
import CoreBluetooth
import Foundation

/// 蓝牙业务服务 — 协调蓝牙业务逻辑，向上层暴露数据流
final class BluetoothService {

    // MARK: - Singleton

    static let shared = BluetoothService()

    // MARK: - Dependencies

    private let bluetoothManager = BluetoothManager.shared

    // MARK: - Publishers（供 PL 层订阅）

    /// 蓝牙状态
    var statePublisher: AnyPublisher<BluetoothState, Never> {
        bluetoothManager.statePublisher.eraseToAnyPublisher()
    }

    /// 发现的设备
    var discoveredDevicesPublisher: AnyPublisher<Peripheral, Never> {
        bluetoothManager.discoveredPeripheralsPublisher.eraseToAnyPublisher()
    }

    /// 连接状态
    var connectionPublisher: AnyPublisher<(UUID, Bool), Never> {
        bluetoothManager.connectionPublisher.eraseToAnyPublisher()
    }

    /// 收到的数据
    var dataReceivedPublisher: AnyPublisher<(CBUUID, Data), Never> {
        bluetoothManager.dataReceivedPublisher.eraseToAnyPublisher()
    }

    // MARK: - Public Methods

    func startScan() {
        bluetoothManager.startScan()
    }

    func stopScan() {
        bluetoothManager.stopScan()
    }

    func connect(to peripheral: Peripheral) {
        bluetoothManager.connect(peripheral)
    }

    func disconnect(from peripheral: Peripheral) {
        bluetoothManager.disconnect(peripheral)
    }

    func writeData(_ data: Data, to characteristic: BLECharacteristic, peripheral identifier: UUID) {
        bluetoothManager.writeValue(data, for: characteristic, peripheral: identifier)
    }
}
