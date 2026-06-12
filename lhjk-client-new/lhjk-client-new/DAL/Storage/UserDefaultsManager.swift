import Foundation

// MARK: - @UserDefault 属性包装器

/// UserDefaults 类型安全属性包装器
///
/// 使用方式：
/// ```
/// enum Settings {
///     @UserDefault("theme_mode", defaultValue: "light")
///     static var themeMode: String
///
///     @UserDefault("enable_notification", defaultValue: true)
///     static var enableNotification: Bool
/// }
/// ```
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    let storage: UserDefaults

    init(_ key: String, defaultValue: T, storage: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
    }

    var wrappedValue: T {
        get { storage.object(forKey: key) as? T ?? defaultValue }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                storage.removeObject(forKey: key)
            } else {
                storage.set(newValue, forKey: key)
            }
        }
    }
}

// MARK: - @UserDefaultCodable 属性包装器

/// UserDefaults Codable 类型属性包装器（JSON 编解码）
///
/// 使用方式：
/// ```
/// @UserDefaultCodable("user_settings", defaultValue: UserSettings())
/// static var userSettings: UserSettings
/// ```
@propertyWrapper
struct UserDefaultCodable<T: Codable> {
    let key: String
    let defaultValue: T
    let storage: UserDefaults

    init(_ key: String, defaultValue: T, storage: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
    }

    var wrappedValue: T {
        get {
            guard let data = storage.data(forKey: key) else { return defaultValue }
            return (try? JSONDecoder().decode(T.self, from: data)) ?? defaultValue
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                storage.set(data, forKey: key)
            }
        }
    }
}

// MARK: - AnyOptional (用于 Optional 类型支持)

private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool {
        self == nil
    }
}

// MARK: - UserDefaultsManager (DAL)

/// UserDefaults 统一管理器
///
/// 提供批量清除、迁移等全局操作。
/// 日常读写优先使用 `@UserDefault` / `@UserDefaultCodable` 属性包装器。
final class UserDefaultsManager {

    // MARK: - Singleton

    static let shared = UserDefaultsManager()

    private let storage = UserDefaults.standard

    /// 应用写入的所有键前缀（用于登出清除时识别）
    private let appKeyPrefixes: [String] = [
        "auth_",
        "user_",
        "settings_",
        "app_",
    ]

    private init() {}

    // MARK: - Remove All

    /// 清除所有应用写入的 UserDefaults 键值（登出时调用）
    func removeAll() {
        for (key, _) in storage.dictionaryRepresentation() {
            if appKeyPrefixes.contains(where: { key.hasPrefix($0) }) {
                storage.removeObject(forKey: key)
            }
        }
    }

    // MARK: - Keychain Proxy

    /// Keychain 存取命名空间
    ///
    /// 使用方式：
    /// ```
    /// UserDefaultsManager.shared.keychain.set("token_value", forKey: "access_token")
    /// let token = UserDefaultsManager.shared.keychain.get("access_token")
    /// ```
    var keychain: KeychainProxy { KeychainProxy() }
}

// MARK: - Keychain Proxy

/// Keychain 轻量级代理（占位实现，后续可集成 KeychainSwift 或原生 Security.framework）
struct KeychainProxy {

    /// 存储字符串到 Keychain
    func set(_ value: String, forKey key: String) {
        // TODO: 使用 Security.framework 或 KeychainSwift 实现
        // KeychainSwift().set(value, forKey: key)
        UserDefaults.standard.set(value, forKey: "kc_\(key)")
    }

    /// 从 Keychain 读取字符串
    func get(_ key: String) -> String? {
        // TODO: 使用 Security.framework 或 KeychainSwift 实现
        // return KeychainSwift().get(key)
        return UserDefaults.standard.string(forKey: "kc_\(key)")
    }

    /// 从 Keychain 删除
    func remove(_ key: String) {
        // TODO: KeychainSwift().delete(key)
        UserDefaults.standard.removeObject(forKey: "kc_\(key)")
    }

    /// 清除所有 Keychain 数据（登出时调用）
    func removeAll() {
        // TODO: KeychainSwift().clear()
    }
}
