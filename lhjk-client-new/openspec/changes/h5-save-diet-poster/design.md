# Design: H5 保存食谱到相册

## 来源

《H5 接入文档》iOS 接入：`saveImageToAlbum` 与套餐跳转同一 `FundeBridge` 通道。

```json
{
  "action": "saveImageToAlbum",
  "dateTime": "2026-09-04",
  "schemeId": "123",
  "fileName": "食谱清单.png",
  "bizType": "dietPoster"
}
```

字段在消息体顶层（也可落在 `params`）。缺省：`fileName=食谱清单.png`，`bizType=dietPoster`。

## 流程

```text
H5 FundeBridge.saveImageToAlbum
  → DiningSchemeService.saveDietPosterToAlbum
      → GET /v1/diningScheme/downloadDietPoster（Bearer，query: dateTime / schemeId / bizType）
      → 按二进制读 body；若为业务 JSON（如 A0230）则失败
      → UIImage 解码
      → PHPhotoLibrary.requestAuthorization(.addOnly)
      → creationRequestForAsset
  → 宿主 Toast「已保存到相册」或错误原因
```

- 空 query 不传（禁止 mock id）
- `fileName` 仅作本地展示名，系统相册不依赖文件名
- 进行中再次点击忽略，避免重复写入
- 无 callbackId 时不走 `__fundeBridge.respond`（与套餐跳转一致）

## 权限

仅申请 **添加** 相册权限（`.addOnly`）。拒绝时 Alert「去设置」。

`NSPhotoLibraryAddUsageDescription` 须由开发者写入 `Info.plist`（本仓库 AI 不改 plist）。

## 非目标

- H5 自己下海报（必须走 App 登录态）
- 保存到 Files / 分享面板
- 修改 Apifox
