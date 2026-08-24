import Foundation

/// OKOK V3 解析后的一帧测量数据
struct OKOKScalePacket: Equatable {
    let version: UInt8
    let serial: UInt8
    let weightRaw: UInt16
    let resistanceRaw: UInt16
    let productId: UInt16
    let attributes: UInt8
    let macBytes: [UInt8]
    /// 换算后的 kg
    let weightKg: Double
    let isLocked: Bool
    let deviceTypeIsBodyFat: Bool

    var macString: String {
        macBytes.map { String(format: "%02X", $0) }.joined(separator: ":")
    }

    /// 调试日志摘要
    var debugDescription: String {
        "mac=\(macString) weight=\(String(format: "%.2f", weightKg))kg " +
            "raw=\(weightRaw) R=\(resistanceRaw) serial=\(serial) " +
            "productId=\(productIdHex) attr=0x\(String(format: "%02X", attributes)) " +
            "locked=\(isLocked) bodyFat=\(deviceTypeIsBodyFat)"
    }

    var productIdHex: String {
        String(format: "0x%04X", productId)
    }

    // MARK: - 属性位解码（与 `parseDataDomain` 一致）

    /// bit0：锁定
    var attributeIsLocked: Bool { isLocked }

    /// bit1–2：小数位
    var decimalBits: UInt8 { (attributes >> 1) & 0b11 }

    /// bit3–4：重量单位
    var unitBits: UInt8 { (attributes >> 3) & 0b11 }

    /// bit5：体脂秤类型
    var attributeIsBodyFatScale: Bool { deviceTypeIsBodyFat }

    var decimalDivisor: Double {
        switch decimalBits {
        case 0b01: return 1
        case 0b10: return 100
        default: return 10
        }
    }

    var decimalLabel: String {
        switch decimalBits {
        case 0b01: return "0位小数"
        case 0b10: return "2位小数"
        default: return "1位小数"
        }
    }

    var unitLabel: String {
        switch unitBits {
        case 0b01: return "斤"
        case 0b10: return "磅(lb)"
        case 0b11: return "英石(st:lb)"
        default: return "千克(kg)"
        }
    }

    var macBytesHex: String {
        macBytes.map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    var attributesBinary: String {
        String(attributes, radix: 2).padding(toLength: 8, withPad: "0", startingAt: 0)
    }

    /// 上报 `monitorData.data.impedance`（Ω）；`resistanceRaw` 为 0 或未测到则为 0
    var impedance: Double {
        guard resistanceRaw > 0 else { return 0 }
        return Double(resistanceRaw) / 10.0
    }

    /// 控制台打印本帧解析出的全部测量字段（调试用）
    func printFullMeasurementLog(
        phase: String,
        discovery: OKOKScaleDiscovery? = nil,
        peripheralId: UUID? = nil,
        rawManufacturerHex: String? = nil
    ) {
        var lines: [String] = [
            "[OKOK-Measure] ══ \(phase) ══",
            "version: 0x\(String(format: "%02X", version))",
            "serial: \(serial)",
            "weightRaw: \(weightRaw) (0x\(String(format: "%04X", weightRaw)))",
            "weightKg: \(String(format: "%.3f", weightKg))",
            "resistanceRaw: \(resistanceRaw) (0x\(String(format: "%04X", resistanceRaw)))",
            "impedance: \(String(format: "%.1f", impedance))",
            "productId: \(productId) (\(productIdHex))",
            "attributes: 0x\(String(format: "%02X", attributes)) (0b\(attributesBinary))",
            "  locked(bit0): \(attributeIsLocked)",
            "  decimalBits(bit1-2): \(decimalBits) → \(decimalLabel), divisor=\(decimalDivisor)",
            "  unitBits(bit3-4): \(unitBits) → \(unitLabel)",
            "  bodyFatScale(bit5): \(attributeIsBodyFatScale)",
            "mac: \(macString)",
            "macBytes: [\(macBytesHex)]",
        ]
        if let discovery {
            lines.append("bluetoothName: \(discovery.resolvedBluetoothName)")
            lines.append("broadcastLocalName: \(discovery.bluetoothName ?? "-")")
            lines.append("rssi: \(discovery.rssi)")
            lines.append("modelName: \(discovery.modelName)")
            lines.append("modelCode: \(discovery.modelCode)")
        }
        if let peripheralId {
            lines.append("peripheralId: \(peripheralId.uuidString)")
        }
        if let rawManufacturerHex {
            lines.append("rawManufacturerData: [\(rawManufacturerHex)]")
        }
        lines.append("[OKOK-Measure] ════════════════")
        print(lines.joined(separator: "\n"))
    }
}

/// OKOK 产品 ID → 展示型号（厂商未给全量表时，先回退 productId）
enum OKOKScaleProductCatalog {

    static func displayName(productId: UInt16) -> String {
        switch productId {
        default:
            return "OKOK体脂秤"
        }
    }

    static func modelCode(productId: UInt16) -> String {
        String(format: "0x%04X", productId)
    }
}

/// 一帧 OKOK 广播 + 周边 BLE 元数据
struct OKOKScaleDiscovery: Equatable {
    let packet: OKOKScalePacket
    let bluetoothName: String?
    let rssi: Int

    var modelName: String {
        OKOKScaleProductCatalog.displayName(productId: packet.productId)
    }

    var modelCode: String {
        OKOKScaleProductCatalog.modelCode(productId: packet.productId)
    }

    /// 型号、蓝牙名、MAC — 便于控制台对照真机
    var identityLogLine: String {
        "型号=\(modelName)(\(modelCode)) 蓝牙名=\(resolvedBluetoothName) MAC=\(packet.macString) RSSI=\(rssi)"
    }

    /// 广播 Local Name；OKOK 单向广播秤多数不带名称，用 MAC 后缀兜底
    var resolvedBluetoothName: String {
        let trimmed = bluetoothName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty { return trimmed }
        let suffix = packet.macString.split(separator: ":").suffix(2).joined(separator: ":")
        return suffix.isEmpty ? "(无广播名)" : "OKOK-\(suffix)"
    }
}

/// OKOK 单向广播体脂秤 V3 解析器
///
/// 厂商过滤：自定义广播**首字节 `0xC0`**，**第 10–15 字节（1-based）为 MAC**。
/// 与协议数据域一致：offset0=版本 C0，offset9…14=MAC。
enum OKOKV3PacketParser {

    /// 最小数据域长度（含 MAC）
    static let dataDomainLength = 15
    static let versionByte: UInt8 = 0xC0

    /// 可选产品 ID 白名单；空 = 不按产品 ID 拦截
    static var allowedProductIds: Set<UInt16> = []

    /// 从 CoreBluetooth manufacturerData 中定位并解析
    static func parse(manufacturerData: Data) -> OKOKScalePacket? {
        guard let domain = locateDataDomain(in: manufacturerData) else { return nil }
        return parseDataDomain(domain)
    }

    /// 厂商过滤：首字节 C0 且长度覆盖第 10–15 字节 MAC
    static func matchesVendorFilter(_ data: Data) -> Bool {
        locateDataDomain(in: data) != nil
    }

    // MARK: - Locate

    /// 在载荷中定位 15 字节数据域。
    /// 厂商规则：自定义数据**必须首字节 `0xC0`**，禁止把载荷中间偶然出现的 `C0` 当成体脂秤。
    static func locateDataDomain(in data: Data) -> Data? {
        let bytes = [UInt8](data)
        guard bytes.count >= dataDomainLength else { return nil }

        // 自定义数据本身以 C0 开头
        if bytes[0] == versionByte {
            return Data(bytes[0..<dataDomainLength])
        }

        // iOS manufacturerData = Company ID(2B 小端) + 自定义数据；剥离后必须以 C0 开头
        if bytes.count >= 2 + dataDomainLength, bytes[2] == versionByte {
            return Data(bytes[2..<(2 + dataDomainLength)])
        }

        // 完整 AD：Len=0x10, Type=0xFF, 后跟 15B 数据域
        if bytes.count >= 17, bytes[0] == 0x10, bytes[1] == 0xFF, bytes[2] == versionByte {
            return Data(bytes[2..<17])
        }

        return nil
    }

    // MARK: - Parse domain

    static func parseDataDomain(_ domain: Data) -> OKOKScalePacket? {
        let b = [UInt8](domain)
        guard b.count >= dataDomainLength, b[0] == versionByte else { return nil }

        let serial = b[1]
        let weightRaw = UInt16(b[2]) << 8 | UInt16(b[3])
        let resistanceRaw = UInt16(b[4]) << 8 | UInt16(b[5])
        let productId = UInt16(b[6]) << 8 | UInt16(b[7])
        let attributes = b[8]
        let macBytes = Array(b[9..<15])

        if !allowedProductIds.isEmpty, !allowedProductIds.contains(productId) {
            return nil
        }

        let decimalBits = (attributes >> 1) & 0b11
        let unitBits = (attributes >> 3) & 0b11
        let isLocked = (attributes & 0b1) == 1
        let isBodyFat = ((attributes >> 5) & 0b1) == 1

        let divisor: Double
        switch decimalBits {
        case 0b01: divisor = 1
        case 0b10: divisor = 100
        default: divisor = 10 // 默认 1 位小数
        }
        var value = Double(weightRaw) / divisor

        // 单位 → kg
        switch unitBits {
        case 0b01: // 斤
            value = value / 2.0
        case 0b10: // LB
            value = value * 0.45359237
        case 0b11: // ST:LB 延后，原样按 raw/divisor 当近似
            break
        default:
            break // kg
        }

        return OKOKScalePacket(
            version: b[0],
            serial: serial,
            weightRaw: weightRaw,
            resistanceRaw: resistanceRaw,
            productId: productId,
            attributes: attributes,
            macBytes: macBytes,
            weightKg: value,
            isLocked: isLocked,
            deviceTypeIsBodyFat: isBodyFat
        )
    }
}
