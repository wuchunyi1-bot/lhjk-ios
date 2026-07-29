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
            "productId=\(String(format: "0x%04X", productId)) attr=0x\(String(format: "%02X", attributes)) " +
            "locked=\(isLocked) bodyFat=\(deviceTypeIsBodyFat)"
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

    /// 在载荷中定位 15 字节数据域（以 0xC0 开头）
    static func locateDataDomain(in data: Data) -> Data? {
        let bytes = [UInt8](data)
        guard !bytes.isEmpty else {
            print("[OKOK-DAL] locateDataDomain miss — empty data")
            return nil
        }

        let hex = data.bleHexString
        print("[OKOK-DAL] locateDataDomain in len=\(bytes.count) hex=[\(hex)]")

        // 完整 AD：Len=0x10, Type=0xFF, 后跟 15B 数据域
        if bytes.count >= 17, bytes[0] == 0x10, bytes[1] == 0xFF, bytes[2] == versionByte {
            let domain = Data(bytes[2..<17])
            print("[OKOK-DAL] locateDataDomain hit path=AD(0x10,0xFF,C0) domain=[\(domain.bleHexString)]")
            return domain
        }

        // 在任意位置搜索以 C0 开头、其后至少 14 字节的窗口（兼容 Company ID 前缀等）
        if let idx = bytes.firstIndex(of: versionByte),
           idx + dataDomainLength <= bytes.count {
            let slice = Data(bytes[idx..<(idx + dataDomainLength)])
            if slice.first == versionByte {
                print("[OKOK-DAL] locateDataDomain hit path=scanC0 offset=\(idx) domain=[\(slice.bleHexString)]")
                return slice
            }
        }

        // 载荷本身即以 C0 开头
        if bytes.count >= dataDomainLength, bytes[0] == versionByte {
            let domain = Data(bytes[0..<dataDomainLength])
            print("[OKOK-DAL] locateDataDomain hit path=rawC0 domain=[\(domain.bleHexString)]")
            return domain
        }

        print("[OKOK-DAL] locateDataDomain miss — no C0 domain (need ≥15B from 0xC0)")
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
