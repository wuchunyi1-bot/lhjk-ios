import Foundation

/// 设备选择 / 我的设备页的展示卡片
struct ScaleDeviceCardItem: Equatable {
    enum Kind: Equatable {
        case bound
        case catalog
    }

    let id: String
    let kind: Kind
    let name: String
    let code: String
    let imageURL: String?
    /// 解绑用 `equipmentUserId`
    let equipmentUserId: Int64?
    /// 型号主键，跳转测量页
    let equipmentTypeId: String?
    /// `getEquipmenByApp.bluetoothName`，用于识别 OKOK
    let bluetoothName: String?

    var showsUnbind: Bool { kind == .bound }
    var isSelectable: Bool { kind == .catalog }

    static func bound(from device: EquipmentUserVO) -> ScaleDeviceCardItem? {
        let userId = parseInt64(device.id)
        let typeId = firstNonEmpty(device.equipmentTypeId, device.equipmentId)
        let identity = firstNonEmpty(device.id, device.mac, device.equipmentId, typeId)
        guard let identity, !identity.isEmpty else { return nil }
        return ScaleDeviceCardItem(
            id: "bound-\(identity)",
            kind: .bound,
            name: firstNonEmpty(device.name, device.commodityName, device.bluetoothName, device.model) ?? "体脂秤",
            code: firstNonEmpty(device.equipmentId, device.mac, device.model) ?? "",
            imageURL: device.imgUrl,
            equipmentUserId: userId,
            equipmentTypeId: typeId,
            bluetoothName: device.bluetoothName
        )
    }

    static func catalog(from item: EquipmentCatalogItemVO) -> ScaleDeviceCardItem {
        ScaleDeviceCardItem(
            id: "catalog-\(item.id)",
            kind: .catalog,
            name: firstNonEmpty(item.name, item.bluetoothName, item.model) ?? "体脂秤",
            code: firstNonEmpty(item.model, item.bluetoothName) ?? "",
            imageURL: item.imgUrl,
            equipmentUserId: nil,
            equipmentTypeId: item.id,
            bluetoothName: item.bluetoothName
        )
    }

    var isOKOKCatalog: Bool {
        bluetoothName?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "OKOK"
    }

    private static func firstNonEmpty(_ values: String?...) -> String? {
        for value in values {
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }

    private static func parseInt64(_ raw: String?) -> Int64? {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return Int64(trimmed)
    }
}
