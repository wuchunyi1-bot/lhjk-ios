## Context

OKOK 体脂秤走**广播扫描**（`allowDuplicates`），不建立 GATT。`ScaleBleSessionService` 已封装启停与 realtime/locked 事件；缺少原生测量 UI，用户无法主动控制「开始听广播」。

模块归属：**Health**（`PL/Health/ScaleMeasure/` + `HealthRoutes`）。

## Goals / Non-Goals

**Goals:**

- 极简测量页：中间主按钮启停广播会话
- 实时体重 + 锁定结果展示；锁定后本地缓存沿用既有 BLL
- 离开页面停止扫描
- 从「我的设备」可进入

**Non-Goals:**

- 体脂算法 / HTTP 上报（沿用既有本地缓存）
- 设备配对列表重做、GATT 连接流
- 改 H5 体重页或 Bridge 契约（可后续把 `openManager` 指到本页）

## Decisions

1. **路由** `/health/scale/measure` → `ScaleBroadcastMeasureViewController`  
   - 备选 `/me/devices/scale`：设备页属 My，但测量属 Health，选 Health 路径。

2. **会话控制** ViewModel 调 `ScaleBleSessionService.startSession()` / `stopSession()`；VC 不碰 DAL。  
   - 进入页**不**自动开扫；仅按钮点击后开扫。

3. **锁定后行为** 收到 locked → 展示结果 → **自动 stopSession**（广播已拿到定值，继续扫无必要）；主按钮文案恢复「再测一次」。

4. **UI 结构**  
   - 上方：状态文案（待开始 / 测量中请上秤 / 蓝牙不可用）  
   - 中部大号体重数字（`fdMono`）+ 单位 kg  
   - 正中大按钮：开始测量 / 停止  
   - 锁定后可显示 MAC 后缀提示

5. **入口** `DevicesViewController`「添加新设备」→ `Router.push("/health/scale/measure")`（当前按钮无 action）。

## Risks / Trade-offs

- [多页面同时 startSession] → Service 已幂等；离开页必须 stop，避免与 H5 Bridge 抢会话。  
- [蓝牙权限/关闭] → 订阅 `errorPublisher` / status，Toast + 禁用按钮态。

## Open Questions

- 是否将 H5 `ble.openManager` 改为打开本页：本期不改，保持 `/me/devices`。
