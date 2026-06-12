import CoreBluetooth

// MARK: - 蓝牙设备模型

/// 外围设备模型
struct Peripheral {
    /// 外围设备标识
    let identifier: UUID
    /// 设备名称
    let name: String?
    /// 信号强度
    let rssi: Int
    /// 是否已连接
    var isConnected: Bool = false
}

// MARK: - 蓝牙服务模型

/// 蓝牙服务模型
struct BLEService {
    /// 服务 UUID
    let uuid: CBUUID
    /// 特征列表
    var characteristics: [BLECharacteristic] = []
}

// MARK: - 蓝牙特征模型

/// 蓝牙特征模型
struct BLECharacteristic {
    /// 特征 UUID
    let uuid: CBUUID
    /// 属性：Read / Write / Notify
    let properties: CBCharacteristicProperties
    /// 是否正在被监听
    var isNotifying: Bool = false
}
