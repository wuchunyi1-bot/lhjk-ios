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
    let peripheralState: CBPeripheralState
    let advertisementData: [String: Any]
    let timestamp: Date

    var manufacturerData: Data? {
        advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
    }

    var localName: String? {
        advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? name
    }

    /// 扫描 dump 去重键：设备 + 广播载荷（不含 RSSI，避免同设备刷屏）
    var scanDumpKey: String {
        let keys = advertisementData.keys.sorted().joined(separator: ",")
        let mfg = manufacturerData?.bleHexString ?? "-"
        return "\(peripheralId.uuidString)|\(name ?? "-")|\(keys)|\(mfg)"
    }
}

// MARK: - Debug helpers

extension BLEAdvertisementEvent {

    /// CoreBluetooth `didDiscover` 能拿到的全部数据（回调参数 + advertisementData 全键）
    func printFullAdvertisementLog(tag: String = "[BLE-Advertisement]") {
        var lines: [String] = [
            "\(tag) ══ full advertisement ══",
            "— didDiscover 回调 —",
            "peripheral.identifier: \(peripheralId.uuidString)",
            "peripheral.name: \(name ?? "(nil)")",
            "peripheral.state: \(Self.peripheralStateLabel(peripheralState))",
            "rssi: \(rssi)",
            "event.timestamp: \(timestamp)",
            "— advertisementData (\(advertisementData.count) keys) —",
        ]

        for key in Self.documentedAdvertisementKeys {
            if let value = advertisementData[key] {
                lines.append("  \(key): \(Self.formatAdvertisementValue(value))")
            } else {
                lines.append("  \(key): (absent)")
            }
        }

        let extraKeys = advertisementData.keys
            .filter { !Set(Self.documentedAdvertisementKeys).contains($0) }
            .sorted()
        if extraKeys.isEmpty {
            lines.append("  (no extra undocumented keys)")
        } else {
            lines.append("— extra / undocumented keys —")
            for key in extraKeys {
                lines.append("  \(key): \(Self.formatAdvertisementValue(advertisementData[key]))")
            }
        }

        if let mfg = manufacturerData {
            let bytes = [UInt8](mfg)
            let indexed = bytes.enumerated()
                .map { String(format: "%02d:%02X", $0.offset, $0.element) }
                .joined(separator: " ")
            lines.append("manufacturerData.len: \(mfg.count)")
            lines.append("manufacturerData.hex: [\(mfg.bleHexString)]")
            lines.append("manufacturerData.indexed: \(indexed)")
            if bytes.count >= 2 {
                let companyId = UInt16(bytes[0]) | UInt16(bytes[1]) << 8
                lines.append(String(format: "manufacturerData.companyId: 0x%04X (iOS 前 2 字节，小端)", companyId))
            }
        } else {
            lines.append("manufacturerData: (nil)")
        }

        lines.append("\(tag) ════════════════════════")
        print(lines.joined(separator: "\n"))
    }

    /// Apple 文档列出的 `CBAdvertisementData*` 键（缺席也打印，避免误以为没 dump）
    private static let documentedAdvertisementKeys: [String] = [
        CBAdvertisementDataLocalNameKey,
        CBAdvertisementDataManufacturerDataKey,
        CBAdvertisementDataServiceUUIDsKey,
        CBAdvertisementDataServiceDataKey,
        CBAdvertisementDataOverflowServiceUUIDsKey,
        CBAdvertisementDataTxPowerLevelKey,
        CBAdvertisementDataIsConnectable,
        CBAdvertisementDataSolicitedServiceUUIDsKey,
    ]

    private static func peripheralStateLabel(_ state: CBPeripheralState) -> String {
        switch state {
        case .disconnected: return "disconnected"
        case .connecting: return "connecting"
        case .connected: return "connected"
        case .disconnecting: return "disconnecting"
        @unknown default: return "unknown(\(state.rawValue))"
        }
    }

    private static func formatAdvertisementValue(_ value: Any?) -> String {
        switch value {
        case let data as Data:
            return "Data(\(data.count)B) [\(data.bleHexString)]"
        case let text as String:
            return "\"\(text)\""
        case let number as NSNumber:
            return "\(number)"
        case let uuids as [CBUUID]:
            return "[\(uuids.map(\.uuidString).joined(separator: ", "))]"
        case let serviceData as [CBUUID: Data]:
            let pairs = serviceData
                .map { "\($0.key.uuidString)=Data(\($0.value.count)B)[\($0.value.bleHexString)]" }
                .sorted()
            return "{\(pairs.joined(separator: ", "))}"
        case .none:
            return "(nil)"
        default:
            return String(describing: value)
        }
    }
}

extension Data {
    /// 调试用十六进制（大写，空格分隔）
    var bleHexString: String {
        map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}
