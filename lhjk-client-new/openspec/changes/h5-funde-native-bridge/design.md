## Context

文档约定：

- H5 → Native：`window.webkit.messageHandlers.FundeNative.postMessage({ action, params, callbackId })`
- Native → H5：`__fundeBridge.respond / reject / emit`
- 首期 BLE：仅 `metric=weight`；扫描/解析/上报原生负责；H5 只展示横条与刷新

## Goals / Non-Goals

**Goals:** Bridge 通道 + 体重 ble.getStatus / openManager + statusChange / synced / error 推送。  
**Non-Goals:** 血压等其它 metric 蓝牙；完整设备管理 UI 重做；体脂算法；改 H5 工程。

## Decisions

1. **注入范围**：所有 `WebViewController` 注册 `FundeNative`（无害；非 H5 页不会调用）。
2. **Handler 防循环**：`WeakScriptMessageHandler` 转发，避免 WKUserContentController 强引用 VC。
3. **Status 来源**：`ScaleBleSessionService.currentStatus(metric:)`；`bound`=本地有绑定 mac/最近锁定设备；`connected`=测量会话活跃或近期收到广播；`deviceName`/`lastSyncAt` 来自缓存。
4. **openManager**：`Router.push("/me/devices")`（已有设备页）。
5. **synced**：锁定落库成功后 `emit("ble.synced", …)`；当前本地缓存成功即视为可推送（HTTP 恢复后仍在同一点 emit）。
6. **JSON**：`JSONSerialization` + `evaluateJavaScript`；payload 用 JSON 对象字面量传入。

## Risks / Trade-offs

- [H5 未挂载 `__fundeBridge`] → respond/emit 前探测，失败则 debug log
- [广播秤无 GATT 连接] → `connected` 语义为「会话中/可收数」，与文档横条文案对齐即可

## Open Questions

- 无
