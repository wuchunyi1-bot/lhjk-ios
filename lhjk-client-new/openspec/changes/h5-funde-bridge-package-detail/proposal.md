# Change: H5 FundeBridge 套餐详情跳转

## Why

最新《H5 宿主接入文档》约定套餐 CMS 统一走 `#/package/bridge`，用户点击「查看套餐」后通过 **`FundeBridge`** 通知宿主打开原生套餐详情。现有 `WebViewController` 只注册了 `FundeNative`（体重 BLE），未注册 `FundeBridge`，点击无反应。

## What Changes

- 主规格：新增 `openspec/specs/h5-host/spec.md`（App WebView ↔ H5 打开方式、路由表、双通道 Bridge）
- `WebViewController` 注册 `FundeBridge` messageHandler
- 处理 `navigatePackageDetail`：`openPackageDetail` → 原生 `/services/pkg`
- 保留既有 `FundeNative` BLE 通道

## Capabilities

### New Capabilities

- `h5-host`: App WebView 与 H5 的 URL / FundeBridge 交互

### Modified Capabilities

- （无已归档 specs 行为回退）

## Impact

- `WebViewController`、`FundeNativeBridge`
- 原生套餐详情：`ServiceRoutes` `/services/pkg`
