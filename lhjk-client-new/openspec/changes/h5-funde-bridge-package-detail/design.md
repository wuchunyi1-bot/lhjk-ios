# Design: H5 FundeBridge 套餐详情

## Context

文档约定：

- CMS：`FundeH5:/package/bridge?packageId=&hospitalId=`
- H5 → iOS：`webkit.messageHandlers.FundeBridge.postMessage({ action, packageId, hospitalId })`
- Handler 名必须为 **`FundeBridge`**（与 H5 `IOS_BRIDGE_HANDLER` 一致）
- `openPackageDetail` 打开 **原生** 套餐详情，不是再开 H5

既有 `FundeNative` 是另一套通道（`{ action, params, callbackId }` + `__fundeBridge` 回包），用于体重 BLE，继续并存。

## Goals / Non-Goals

**Goals:** 注册 FundeBridge；`navigatePackageDetail` → `/services/pkg`；主规格整理 URL + Bridge。  
**Non-Goals:** 改 H5 工程；Android / 小程序；体重 BLE；新增套餐详情 UI。

## Decisions

1. **双 handler**：同一 `WebViewController` 注册 `FundeBridge` 与 `FundeNative`，共用 `WeakScriptMessageHandler` 转发。
2. **消息体**：按文档读顶层 `packageId` / `hospitalId`；若 H5 误包进 `params` 则兼容读取。
3. **openPackageDetail**：`Router.push("/services/pkg", params: ["id": packageId, "hospitalId": …], from: hostVC)`，与列表进详情同一页。
4. **空 packageId**：不跳转、不崩溃。
5. **未知 action**：FundeBridge 静默忽略（无 callbackId）；FundeNative 仍 reject。

## Risks / Trade-offs

- [H5 未带 platform] → App 打开时已拼 `platform=ios`
- [hospitalId 空] → 只传 `id`，详情页按现有逻辑拉套餐
