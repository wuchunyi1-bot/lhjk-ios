# OSS File Upload

## Purpose

封装阿里云 OSS 文件上传能力，通过后端签名接口获取预签名 URL，客户端直接 PUT 文件到 OSS。不依赖阿里云 SDK，使用原生 `URLSession` 完成上传。

## Flow

```
┌──────────┐  ① GET /v1/cos/getCosSign    ┌──────────┐
│  Client  │ ────────────────────────────→ │  Backend │
│  (iOS)   │ ←────── { signUrl, fundeUrl } │          │
└────┬─────┘                              └──────────┘
     │
     │  ② PUT {fileData} to signUrl
     │     (Content-Type: image/jpeg / ...)
     ▼
┌──────────┐
│ Aliyun   │
│   OSS    │
└──────────┘

Final URL = fundeUrl (CDN) ?? signUrl（去参）
```

## Requirements

### Requirement: Get Signed Upload URL
系统 SHALL 通过后端接口获取阿里云 OSS 预签名上传 URL。

#### Scenario: 正常获取
- **WHEN** 需要上传文件
- **THEN** 调用 `GET /v1/cos/getCosSign?folderName={folder}&ext={ext}`（需 Bearer Token）
- **AND** 返回 `CosSignVo`：`signUrl`（签名上传 URL）+ `fundeUrl`（CDN 域名 URL）

#### Scenario: 签名获取失败
- **WHEN** 接口返回失败
- **THEN** 抛出 `OSSError.signFailed(msg)`

---

### Requirement: Upload File to OSS
系统 SHALL 使用签名 URL 通过 HTTP PUT 方法将文件直接上传到阿里云 OSS。

#### Scenario: 上传文件
- **WHEN** 获取到签名 URL 后
- **THEN** 构建 `URLRequest`：`httpMethod = "PUT"`，`httpBody = fileData`，`Content-Type = mimeType`
- **AND** 使用 `URLSession.shared.data(for:)` 发送请求（不使用 APIManager，避免携带 Bearer Token 干扰 OSS 签名校验）

#### Scenario: 上传成功
- **WHEN** HTTP 状态码 2xx
- **THEN** 返回 `fundeUrl`（优先 CDN 域名），若 `fundeUrl` 为空则取 `signUrl` 去除 query 参数后的裸 URL

#### Scenario: 上传失败
- **WHEN** HTTP 状态码非 2xx
- **THEN** 抛出 `OSSError.uploadFailed(statusCode)`

---

## API Contract

### GET /v1/cos/getCosSign

> **Source**: Apifox `funde-api` → `GET /v1/cos/getCosSign`
> **operationId**: `getTencentCosToken`
> **Synced**: 2026-06-25

```
GET {Base URL}/v1/cos/getCosSign?folderName={folderName}&ext={ext}
Authorization: Bearer {access_token}
```

**Query Parameters**:

| 参数 | 类型 | 必填 | 描述 |
|------|------|------|------|
| `folderName` | string | 是 | 文件夹名称：`common`（公共）、`school`（学习平台）、`im`（聊天文件） |
| `ext` | string | 是 | 文件扩展名（如 `jpg`, `png`, `mp4`） |

**成功响应** (`200 OK`, `ResultCosSignVo`):

```json
{
  "code": "0",
  "data": {
    "signUrl": "https://bucket.oss-cn-hangzhou.aliyuncs.com/path/file.jpg?Expires=...&OSSAccessKeyId=...&Signature=...",
    "fundeUrl": "https://cdn.example.com/path/file.jpg"
  },
  "msg": "ok",
  "success": true
}
```

| 字段 | 类型 | 描述 |
|------|------|------|
| `signUrl` | string | 签名后的 OSS 上传 URL（含认证参数，一次性有效） |
| `fundeUrl` | string | 绑定域名的 CDN 访问 URL（用于回显/存储） |

---

## DAL Interface

```swift
/// 阿里云 OSS 文件上传管理器
final class OSSManager {
    static let shared: OSSManager

    /// 上传文件到阿里云 OSS
    /// - Parameters:
    ///   - data: 文件二进制数据
    ///   - folderName: 文件夹（"common" / "school" / "im"）
    ///   - ext: 扩展名（不含点，如 "jpg"）
    ///   - mimeType: MIME 类型（如 "image/jpeg"）
    /// - Returns: 上传后的可访问 URL
    func upload(data: Data, folderName: String, ext: String, mimeType: String) async throws -> String
}

enum OSSError: Error {
    case signFailed(String)
    case invalidURL(String)
    case uploadFailed(Int)
}
```

## File Locations

| 文件 | 说明 |
|------|------|
| `DAL/OSS/OSSModels.swift` | `CosSignVo` + `OSSUploadResult` 模型 |
| `DAL/OSS/OSSManager.swift` | OSS 上传服务实现 |

## Usage

### 头像上传（ProfileViewController）

```swift
// 用户选择头像 → JPEG 压缩 → OSS 上传 → 保存到后端 → 刷新缓存
func uploadAvatar(_ image: UIImage) {
    guard let data = image.jpegData(compressionQuality: 0.8) else { return }
    Task {
        // Step 1: 上传到 OSS
        let url = try await OSSManager.shared.upload(
            data: data, folderName: "common", ext: "jpg", mimeType: "image/jpeg"
        )
        // Step 2: 保存 imageUrl
        let payload = SUsersOnboardingPayload(imageUrl: url)
        _ = try await UserService.shared.updateCurrentProfile(payload)
        // Step 3: 刷新缓存通知 UI
        _ = await UserManager.shared.refreshUserInfo()
    }
}
```

### 通用文件上传

```swift
let imageData = avatar.jpegData(compressionQuality: 0.8)!
let url = try await OSSManager.shared.upload(
    data: imageData,
    folderName: "common",
    ext: "jpg",
    mimeType: "image/jpeg"
)
// url = "https://cdn.example.com/common/avatar_xxx.jpg"
```
