# Change: H5 保存食谱到相册

## Why

饮食方案 H5（`#/diet-plan`）提供「保存食谱到手机」。宿主需走已有 `FundeBridge` 通道，用 App 登录态请求 `GET /v1/diningScheme/downloadDietPoster`，按二进制读取海报并写入系统相册。未实现时点击无反应。

## What Changes

- `FundeBridge` 新增 `action=saveImageToAlbum`
- BLL 用登录态 GET 下载海报二进制，写入相册（`PHPhotoLibrary` `.addOnly`）
- 成功 / 失败 / 无相册权限在宿主 Toast 或引导去设置
- 同步 `h5-host` 主规格与接口清单

## Capabilities

### Modified Capabilities

- `h5-host`: FundeBridge 保存食谱到相册
- `networking`: 已认证二进制 GET

## Impact

- `FundeNativeBridge`、`APIManager+Async`、新增 `DiningSchemeService`
- `docs/api-inventory.md`
- Info.plist 需开发者手动加 `NSPhotoLibraryAddUsageDescription`（AI 不改 plist）
