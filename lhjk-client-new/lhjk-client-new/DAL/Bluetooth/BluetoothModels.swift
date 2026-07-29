import CoreBluetooth
import Foundation

// MARK: - 蓝牙设备模型

/// 外围设备模型
struct Peripheral {
    let identifier: UUID
    let name: String?
    let rssi: Int
    var isConnected: Bool = false
}

/// 蓝牙服务模型
struct BLEService {
    let uuid: CBUUID
    var characteristics: [BLECharacteristic] = []
}

/// 蓝牙特征模型
struct BLECharacteristic {
    let uuid: CBUUID
    let properties: CBCharacteristicProperties
    var isNotifying: Bool = false
}

// MARK: - 原始广播事件（基础层，不含厂商协议解析）

/// BLE 扫描发现的原始广播事件
struct BLEAdvertisementEvent {
    let peripheralId: UUID
    let name: String?
    let rssi: Int
    let advertisementData: [String: Any]
    let timestamp: Date

    var manufacturerData: Data? {
        advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
    }

    var localName: String? {
        advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? name
    }
}
