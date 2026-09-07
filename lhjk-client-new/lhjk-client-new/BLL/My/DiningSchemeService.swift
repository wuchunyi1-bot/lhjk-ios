import Foundation
import UIKit
import Photos

/// 饮食方案海报 — `GET /v1/diningScheme/downloadDietPoster`
final class DiningSchemeService {

    static let shared = DiningSchemeService()

    private var isSaving = false

    private init() {}

    enum DiningSchemeServiceError: LocalizedError {
        case busy
        case invalidImage
        case photoDenied
        case requestFailed(String)

        var errorDescription: String? {
            switch self {
            case .busy:
                return "正在保存，请稍候"
            case .invalidImage:
                return "食谱图片无效，请稍后重试"
            case .photoDenied:
                return "请在系统设置中允许访问相册"
            case .requestFailed(let message):
                return message
            }
        }
    }

    /// 下载食谱海报并写入系统相册
    func saveDietPosterToAlbum(
        dateTime: String,
        schemeId: String,
        bizType: String
    ) async throws {
        guard !isSaving else { throw DiningSchemeServiceError.busy }
        isSaving = true
        defer { isSaving = false }

        var parameters: [String: Any] = [:]
        let date = dateTime.trimmingCharacters(in: .whitespacesAndNewlines)
        if !date.isEmpty { parameters["dateTime"] = date }
        let scheme = schemeId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !scheme.isEmpty { parameters["schemeId"] = scheme }
        let type = bizType.trimmingCharacters(in: .whitespacesAndNewlines)
        if !type.isEmpty { parameters["bizType"] = type }

        let data: Data
        do {
            data = try await APIManager.shared.getDataAsync(
                path: "/v1/diningScheme/downloadDietPoster",
                parameters: parameters.isEmpty ? nil : parameters
            )
        } catch {
            throw DiningSchemeServiceError.requestFailed(error.localizedDescription)
        }

        guard let image = UIImage(data: data) else {
            throw DiningSchemeServiceError.invalidImage
        }
        try await saveToPhotoAlbum(image)
    }

    private func saveToPhotoAlbum(_ image: UIImage) async throws {
        let status = await requestAddOnlyAccess()
        switch status {
        case .authorized, .limited:
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
            } catch {
                throw DiningSchemeServiceError.requestFailed("保存到相册失败")
            }
        case .denied, .restricted:
            throw DiningSchemeServiceError.photoDenied
        case .notDetermined:
            throw DiningSchemeServiceError.photoDenied
        @unknown default:
            throw DiningSchemeServiceError.photoDenied
        }
    }

    private func requestAddOnlyAccess() async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if current != .notDetermined { return current }
        return await withCheckedContinuation { cont in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                cont.resume(returning: status)
            }
        }
    }
}
