import Foundation

/// 阿里云 OSS 文件上传管理器
///
/// 两步上传流程：
/// 1. 通过后端 `GET /v1/cos/getCosSign` 获取 OSS 预签名 URL
/// 2. 使用签名 URL 直接 PUT 文件到阿里云 OSS
///
/// 不依赖阿里云 SDK，签名 URL 中已包含所有认证信息。
final class OSSManager {

    // MARK: - Singleton

    static let shared = OSSManager()

    private init() {}

    // MARK: - Upload

    /// 上传文件到阿里云 OSS
    /// - Parameters:
    ///   - data: 文件二进制数据
    ///   - folderName: OSS 文件夹名称（`"common"` 公共 / `"school"` 学习平台 / `"im"` 聊天文件）
    ///   - ext: 文件扩展名（不含点，如 `"jpg"`, `"png"`, `"mp4"`）
    ///   - mimeType: 文件 MIME 类型（如 `"image/jpeg"`），必须与后端签名时一致
    /// - Returns: 上传后的可访问 URL（优先 CDN 域名）
    func upload(data: Data, folderName: String, ext: String, mimeType: String) async throws -> String {
        // Step 1: 从后端获取 OSS 预签名上传 URL
        print("[OSSManager] → getting signed URL, folder=\(folderName) ext=\(ext)")

        let response: APIResponse<CosSignVo> = try await APIManager.shared
            .getAsync(
                path: "/mobile/v1/cos/getCosSign",
                parameters: ["folderName": folderName, "ext": ext],
                responseType: APIResponse<CosSignVo>.self
            )

        guard response.isSuccess, let signData = response.data else {
            let msg = response.msg ?? "获取上传签名失败"
            print("[OSSManager] ✗ sign failed: \(msg)")
            throw OSSError.signFailed(msg)
        }

        guard let signUrl = signData.signUrl, !signUrl.isEmpty else {
            print("[OSSManager] ✗ signUrl is empty")
            throw OSSError.signFailed("签名 URL 为空")
        }

        print("[OSSManager] ✓ got signed URL, fundeUrl=\(signData.fundeUrl ?? "nil")")

        // Step 2: PUT 文件到 OSS（签名 URL 已含认证，无需额外 Header）
        print("[OSSManager] ↑ uploading \(data.count) bytes to OSS")

        guard let url = URL(string: signUrl) else {
            throw OSSError.invalidURL(signUrl)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.timeoutInterval = 60
        // 不设置 Content-Type：后端签名时未指定，客户端带任何 Content-Type
        // 都会导致签名不匹配 → HTTP 403 SignatureDoesNotMatch

        let (respData, httpResponse) = try await URLSession.shared.data(for: request)

        guard let statusResponse = httpResponse as? HTTPURLResponse,
              (200...299).contains(statusResponse.statusCode) else {
            let code = (httpResponse as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: respData, encoding: .utf8) ?? ""
            print("[OSSManager] ✗ upload failed, HTTP \(code) body=\(body)")
            throw OSSError.uploadFailed(code)
        }

        // 返回可访问 URL：优先 CDN 域名，降级为 signUrl 去参
        let finalUrl = signData.fundeUrl
            ?? signUrl.components(separatedBy: "?").first
            ?? signUrl
        print("[OSSManager] ✓ upload success, url=\(finalUrl)")
        return finalUrl
    }
}

// MARK: - Error

enum OSSError: Error, LocalizedError {
    case signFailed(String)
    case invalidURL(String)
    case uploadFailed(Int)

    var errorDescription: String? {
        switch self {
        case .signFailed(let msg):
            return "获取上传凭证失败: \(msg)"
        case .invalidURL(let url):
            return "上传地址无效: \(url)"
        case .uploadFailed(let code):
            return "文件上传失败 (HTTP \(code))"
        }
    }
}
