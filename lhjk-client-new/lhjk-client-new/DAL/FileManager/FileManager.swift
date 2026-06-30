import Foundation

// MARK: - 沙盒目录类型

/// 沙盒基础目录类型
enum SandboxFolderType {
    case documents
    case library
    case libraryCache
    case temp

    var path: String {
        switch self {
        case .documents:
            return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        case .library:
            return NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first ?? ""
        case .libraryCache:
            return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
        case .temp:
            return NSTemporaryDirectory()
        }
    }
}

// MARK: - 通用文件管理器

/// 通用文件管理器，提供沙盒目录下文件/文件夹的 CRUD 操作
/// 调用方式：`let fm = MediaFileManager()`，实例化保证线程安全
final class MediaFileManager {

    private let fileManager = FileManager.default

    // MARK: - 路径

    /// 获取沙盒基础目录路径
    func basePath(_ type: SandboxFolderType) -> String {
        type.path
    }

    // MARK: - 存在性

    /// 文件/文件夹是否存在
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>? = nil) -> Bool {
        guard !path.isEmpty else { return false }
        return fileManager.fileExists(atPath: path, isDirectory: isDirectory)
    }

    // MARK: - 创建

    /// 创建文件/文件夹（自动建中间目录）
    @discardableResult
    func createFile(atPath path: String, isDirectory: Bool) -> Bool {
        guard !path.isEmpty else { return false }
        if fileExists(atPath: path) { return true }
        if isDirectory {
            return (try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)) != nil
        } else {
            return fileManager.createFile(atPath: path, contents: nil)
        }
    }

    /// 在 Documents 下创建文件夹
    @discardableResult
    func createDocumentsDirectory(_ dirName: String) -> Bool {
        guard !dirName.isEmpty else { return false }
        let path = basePath(.documents) + "/\(dirName)"
        return createFile(atPath: path, isDirectory: true)
    }

    /// 多级目录创建，如 ["IM", "Audio"] → Documents/IM/Audio
    @discardableResult
    func createDirectories(_ names: [String], baseType: SandboxFolderType) -> Bool {
        guard !names.isEmpty else { return false }
        var path = basePath(baseType)
        for name in names {
            path = (path as NSString).appendingPathComponent(name)
            guard createFile(atPath: path, isDirectory: true) else { return false }
        }
        return true
    }

    // MARK: - 删除

    /// 删除文件/文件夹
    @discardableResult
    func deleteFile(atPath path: String) -> Bool {
        guard !path.isEmpty, fileExists(atPath: path) else { return false }
        do {
            try fileManager.removeItem(atPath: path)
            return true
        } catch {
            print("[MediaFileManager] delete error: \(error)")
            return false
        }
    }

    // MARK: - 大小

    /// 文件夹大小（字节）— 递归遍历
    func sizeOfDirectory(atPath path: String) -> Int64 {
        guard let enumerator = fileManager.enumerator(atPath: path) else { return 0 }
        var total: Int64 = 0
        while let file = enumerator.nextObject() as? String {
            let fullPath = (path as NSString).appendingPathComponent(file)
            if let attrs = try? fileManager.attributesOfItem(atPath: fullPath),
               let type = attrs[.type] as? FileAttributeType,
               type != .typeDirectory,
               let size = attrs[.size] as? Int64 {
                total += size
            }
        }
        return total
    }

    /// 单文件大小（字节）
    func fileSize(atPath path: String) -> Int64 {
        guard let attrs = try? fileManager.attributesOfItem(atPath: path),
              let size = attrs[.size] as? Int64 else { return 0 }
        return size
    }

    // MARK: - 属性

    /// 文件属性字典
    func fileAttributes(atPath path: String) -> [FileAttributeKey: Any]? {
        guard !path.isEmpty, fileExists(atPath: path) else { return nil }
        return try? fileManager.attributesOfItem(atPath: path)
    }

    // MARK: - 复制

    /// 复制文件到目标路径
    @discardableResult
    func copyFile(fromPath: String, toPath: String) -> Bool {
        guard !fromPath.isEmpty, !toPath.isEmpty else { return false }
        do {
            try fileManager.copyItem(atPath: fromPath, toPath: toPath)
            return true
        } catch {
            print("[MediaFileManager] copy error: \(error)")
            return false
        }
    }

    // MARK: - 写入

    /// 将 Data 写入文件
    @discardableResult
    func writeFile(_ data: Data, to path: String, fileName: String) -> Bool {
        let finalPath = (path as NSString).appendingPathComponent(fileName)
        return (try? data.write(to: URL(fileURLWithPath: finalPath), options: .atomic)) != nil
    }
}
