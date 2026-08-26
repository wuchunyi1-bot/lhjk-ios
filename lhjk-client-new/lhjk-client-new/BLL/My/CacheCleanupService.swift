import Foundation
import Kingfisher
import WebKit

/// 设置页「清理缓存」：可回收的磁盘/内存缓存，不含登录态、IM、机构选择与用户偏好。
final class CacheCleanupService {

    static let shared = CacheCleanupService()

    private init() {}

    /// 仅统计 Kingfisher 图片磁盘占用。
    /// `URLCache.currentDiskUsage` 含空 Cache.db 固定开销（约 100～200KB），`removeAllCachedResponses` 清不掉该文件，不能拿来展示。
    func formattedSize() async -> String {
        Self.format(await calculateBytes())
    }

    func calculateBytes() async -> Int64 {
        max(0, await kingfisherDiskBytes())
    }

    func clear() async {
        ImageCache.default.clearMemoryCache()
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            ImageCache.default.clearDiskCache {
                cont.resume()
            }
        }
        URLCache.shared.removeAllCachedResponses()

        await ColumnContentCacheService.shared.clear()
        await ServiceHubCacheService.shared.clear()
        await HealthPageCacheService.shared.clear()
        HomeService.shared.invalidateTodayTasksCache()

        // WKWebsiteDataStore 必须在主线程初始化，后台 Task 会 EXC_BREAKPOINT
        await clearWebViewHTTPCaches()
    }

    // MARK: - Private

    private func kingfisherDiskBytes() async -> Int64 {
        await withCheckedContinuation { cont in
            ImageCache.default.calculateDiskStorageSize { result in
                switch result {
                case .success(let size):
                    cont.resume(returning: Int64(size))
                case .failure:
                    cont.resume(returning: 0)
                }
            }
        }
    }

    /// 仅清 WebView HTTP/磁盘缓存，保留 Cookie / localStorage，避免 H5 登录态被清掉
    @MainActor
    private func clearWebViewHTTPCaches() async {
        let types: Set<String> = [
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeMemoryCache,
        ]
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            WKWebsiteDataStore.default().removeData(
                ofTypes: types,
                modifiedSince: Date.distantPast
            ) {
                cont.resume()
            }
        }
    }

    static func format(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 B" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return formatter.string(fromByteCount: bytes)
    }
}
