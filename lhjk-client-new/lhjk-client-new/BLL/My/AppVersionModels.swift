import Foundation

/// 客户端类型（`GET /v1/version/getLatestVersionForApp` Query `type`）
///
/// Apifox 未写枚举说明；与同网关既有 iOS 客户端一致：`1` = iOS。
enum AppVersionClientType: Int {
    case ios = 1
}

/// Apifox `CVersion` / `VersionBo` — 移动端版本记录
struct CVersion: Decodable {
    let id: Int64?
    let sortId: Int?
    let type: Int?
    /// 版本号：V1.0.1
    let versionName: String?
    /// 版本编码，递增
    let versionCode: Int?
    /// 是否强制升级：1 强制 / 0 不强制
    let forceInstall: Int?
    let minimumCompatibleVersionId: Int64?
    /// 是否提醒：0 否 / 1 是
    let isRemind: Int?
    /// 提醒间隔时间（小时）
    let remindTime: Int?
    /// 一句话描述
    let summary: String?
    /// 是否已发布
    let status: Int?
    /// 版本更新描述
    let description: String?
    /// 下载 / 商店地址
    let addressUrl: String?

    var isForceInstall: Bool { forceInstall == 1 }

    /// 未返回时默认提醒；仅 `isRemind == 0` 时启动检查跳过可选弹窗
    var shouldRemind: Bool { isRemind != 0 }

    var displayVersionName: String {
        let raw = versionName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return raw.isEmpty ? "新版本" : raw
    }

    var updateMessage: String {
        let oneLine = summary?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !oneLine.isEmpty { return oneLine }
        let detail = description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !detail.isEmpty { return detail }
        return "发现新版本，建议立即更新以获得更好体验。"
    }

    var storeURL: URL? {
        let raw = addressUrl?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !raw.isEmpty else { return nil }
        return URL(string: raw)
    }

    private enum CodingKeys: String, CodingKey {
        case id, sortId, type, versionName, versionCode, forceInstall
        case minimumCompatibleVersionId, isRemind, remindTime, summary
        case status, description, addressUrl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.decodeInt64(c, key: .id)
        sortId = Self.decodeInt(c, key: .sortId)
        type = Self.decodeInt(c, key: .type)
        versionName = try c.decodeIfPresent(String.self, forKey: .versionName)
        versionCode = Self.decodeInt(c, key: .versionCode)
        forceInstall = Self.decodeInt(c, key: .forceInstall)
        minimumCompatibleVersionId = Self.decodeInt64(c, key: .minimumCompatibleVersionId)
        isRemind = Self.decodeInt(c, key: .isRemind)
        remindTime = Self.decodeInt(c, key: .remindTime)
        summary = try c.decodeIfPresent(String.self, forKey: .summary)
        status = Self.decodeInt(c, key: .status)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        addressUrl = try c.decodeIfPresent(String.self, forKey: .addressUrl)
    }

    static func decodeInt<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> Int? {
        if let v = try? container.decodeIfPresent(Int.self, forKey: key) { return v }
        if let v = try? container.decodeIfPresent(Int64.self, forKey: key) { return Int(v) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            return Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    static func decodeInt64<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> Int64? {
        if let v = try? container.decodeIfPresent(Int64.self, forKey: key) { return v }
        if let v = try? container.decodeIfPresent(Int.self, forKey: key) { return Int64(v) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            return Int64(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    static func decodeBool<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> Bool? {
        if let v = try? container.decodeIfPresent(Bool.self, forKey: key) { return v }
        if let v = try? container.decodeIfPresent(Int.self, forKey: key) { return v != 0 }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if t == "true" || t == "1" { return true }
            if t == "false" || t == "0" { return false }
        }
        return nil
    }
}

/// `getLatestVersionForApp` 的 `data`
///
/// OAS 的 `Result.data` 无字段；现网可能是：
/// 1. 空 / 无记录（已是最新）
/// 2. 直接返回 `CVersion`
/// 3. `{ isUpdate, isForceInstall, version }`（同网关既有 App 用法）
struct AppLatestVersionData: Decodable {
    let isUpdate: Bool?
    let isForceInstall: Bool?
    let version: CVersion?

    private enum CodingKeys: String, CodingKey {
        case isUpdate, isForceInstall, version
        case versionName, versionCode
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let wrapped = c.contains(.isUpdate) || c.contains(.isForceInstall) || c.contains(.version)
        if wrapped {
            isUpdate = CVersion.decodeBool(c, key: .isUpdate)
            isForceInstall = CVersion.decodeBool(c, key: .isForceInstall)
            version = try c.decodeIfPresent(CVersion.self, forKey: .version)
        } else if c.contains(.versionName) || c.contains(.versionCode) {
            isUpdate = nil
            isForceInstall = nil
            version = try CVersion(from: decoder)
        } else {
            isUpdate = nil
            isForceInstall = nil
            version = nil
        }
    }
}

/// 版本检查结论（BLL 计算，PL 只负责展示）
struct AppVersionCheckInfo {
    let version: CVersion
    let isForce: Bool
    let localVersionCode: Int

    var title: String { "发现新版本" }

    var localVersionDisplay: String {
        let name = AppVersionService.shared.localVersionName
        return name.hasPrefix("V") || name.hasPrefix("v") ? name : "V\(name)"
    }

    var remoteVersionDisplay: String {
        let name = version.displayVersionName
        return name.hasPrefix("V") || name.hasPrefix("v") ? name : "V\(name)"
    }

    /// 对齐 Figma：副标题显示版本比对
    var versionSubtitle: String {
        "最新 \(remoteVersionDisplay) ｜ 当前 \(localVersionDisplay)"
    }

    /// 更新内容：优先展示 summary 字段（为空时回退 description / 默认文案）
    var updateContent: String {
        version.updateMessage
    }
}

enum AppVersionCheckOutcome {
    case upToDate
    case available(AppVersionCheckInfo)
}

enum AppVersionServiceError: LocalizedError {
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let message):
            return message
        }
    }
}
