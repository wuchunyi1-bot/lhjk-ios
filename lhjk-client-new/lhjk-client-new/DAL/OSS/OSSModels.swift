import Foundation

// MARK: - OSS 签名响应

/// 阿里云 OSS 上传签名响应（后端接口返回）
struct CosSignVo: Codable {
    /// 签名后的 OSS 上传 URL（含认证参数，一次性有效）
    let signUrl: String?
    /// 绑定域名的 CDN 访问 URL
    let fundeUrl: String?
}

// MARK: - OSS 上传结果

/// OSS 文件上传完成后的结果
struct OSSUploadResult {
    /// 最终可访问的文件 URL
    /// 优先取 CDN 域名（fundeUrl），降级取 signUrl 去参后的裸 URL
    let url: String
}
