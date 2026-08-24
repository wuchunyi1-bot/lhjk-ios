# Design: 体重 H5 体脂秤状态横条

## 文档来源（只读）

| 文档 | 路径（funde-client） | iOS 采纳 |
|------|---------------------|----------|
| 体重 PRD | `docs/v0.1/pages/health/metrics/weight.md` §6.6 | 横条文案、未绑定/连接中视觉 |
| SCALE PRD v1.1 | `docs/.archive/app健康prd/智能体脂秤设备连接与测量_PRD_v1.1.md` §5.1–5.2 | 绑定≠连接≠测量；离开模块断连 |
| 健康模块 | `docs/v0.1/modules/health.md` | 体重模块边界 |
| OKOK 管道 | 本仓库 `openspec/changes/ble-device-pipeline-okok-scale/` | 广播扫描、无 GATT |

**冲突处理**：v1.1 禁止进页自动 GATT 连接；OKOK 为广播秤无连接步骤。iOS 将「连接中/已连接」统一映射为**广播监听会话**（`ScaleBleSessionService.isActive`），横条文案沿用 weight.md「正在连接，请轻踩唤醒设备」。

## 概念映射（PRD → iOS）

| PRD 概念 | iOS 实现 |
|----------|----------|
| 绑定 `BOUND` | `UserDefaults` `fd_okok_bound_mac` / 首次锁定写入 |
| 未绑定 `UNBOUND` | 无绑定 MAC 且无锁定历史 |
| 连接 `CONNECTED` | `ScaleBleSessionService` 会话活跃 + 系统蓝牙 `poweredOn` |
| 未连接 `DISCONNECTED` | 会话未启动或已 `stopSession` |
| 搜索/连接动画 | 会话活跃时横条转圈（广播扫描中） |
| 离开体重模块断连 | `WebViewController` `viewWillDisappear` → `WeightScaleBleStatusCoordinator.onDisappear` → `stopSession()` |
| 测量锁定 | `OKOKScaleEvent.locked` → `saveOrUpdateMonitorData` 开始时 `stopSession()` + `ble.synced`（含 `monitorId`） |
| 设备管理入口 | 横条「去绑定」与已绑定点击 → `/health/scale/devices` |

## 架构

```
WebViewController (enablesWeightBle=true)
  ├── WeightScaleBleStatusCoordinator → WeightScaleBleStatusBarView
  └── WKWebView (H5 #/weight…)
        └── FundeNativeBridge (enablesWeightBle=true)
              └── ScaleBleSessionService (BLL)
                    └── OKOKBroadcastScaleHandler (DAL)
```

- **PL** 只调 BLL `ScaleBleSessionService`；不直连 `BluetoothManager`
- **设备绑定/上报** 由 `EquipmentBindService`（`BLL/Health`）封装 Apifox 已发布 path；流程图新 path 待文档后再接
- **其它 H5** 仍用 `WebViewController(enablesWeightBle: false)`：注册 `FundeNative` 供套餐 Bridge 共存，但**不**订阅 `statusPublisher`

## 横条 UI 状态

| 条件 | 展示 | 点击 |
|------|------|------|
| 蓝牙不可用 | 提示开启蓝牙/权限 | 无跳转 |
| `!bound` | 您尚未绑定体脂秤 · 去绑定（蓝底） | `/health/scale/devices` |
| `bound && connected` | 转圈 + 正在连接，请轻踩唤醒设备（橙底） | `/health/scale/devices` |
| `bound && !connected` | 设备名 + 未连接，点此重试 | `startSession()` |

## Bridge 约定（不变字段）

`ble.getStatus` / `ble.statusChange` payload：

```json
{
  "metric": "weight",
  "bound": true,
  "connected": true,
  "deviceName": "OKOK体脂秤",
  "lastSyncAt": "今天 08:30"
}
```

- `connected`：**监听会话中**，非 GATT 链路
- `ble.getStatus`：**不再**调用 `startSession()`；会话由体重宿主 VC 生命周期管理
- `ble.openManager`：跳转 `/health/scale/devices`，不隐式开扫

## 路由

`HealthRoutes` 在 `metricKey == "weight"` 时返回 `WebViewController(..., enablesWeightBle: true)`，其余指标仍 `enablesWeightBle: false`。

`/health/scale/devices` → `ScaleDeviceSelectViewController`（体重设备选择 / 我的设备）。

## 设备选择 / 我的设备

对齐 funde-client 选择设备 + 我的设备两页，用同一原生页按接口数据切换。

```
WeightScaleBleStatusCoordinator（去绑定 / 已绑定点击）
        ↓
ScaleDeviceSelectViewController
        ↓ ViewModel
EquipmentBindService
  ├── GET  getEquipmentUserByParam  type=3
  └── POST getEquipmenByApp         type=3
```

| 绑定列表 | UI |
|----------|-----|
| 空 | 标题「选择设备」；只展示可绑定型号（`status != 0`）；无添加按钮 |
| 非空 | 标题「我的设备」；当前设备 +「添加设备」；展开后「更多设备」（型号减去已绑类型）+「收起设备列表」 |

点击型号卡：`bluetoothName=OKOK` → `/health/scale/bind`；其它 Toast「暂不支持该设备」。选择页不扫描。解绑走 `deleteEquipmentUserById`。

## 设备绑定（OKOK）

```
ScaleDeviceSelectViewController  点击 OKOK
        ↓
ScaleDeviceBindViewController
        ↓ 第一帧 OKOK 广播（停扫）
EquipmentBindService
  ├── GET  checkEquipmentVaild     equipmentType + mac
  ├── GET  checkEquipmentBind      mac（isSuccess=true 已绑定）
  └── POST bindEquipment           未绑定时
        ↓ 成功
pop 体重 H5 主页（不上报；锁定后才 saveWeightBluetoothMonitor）
```

## 原生体重报告页（有阻抗）

锁定且 `impedance > 0` 后进入 `WeightScaleResultViewController`。记录已由 `saveOrUpdateMonitorData` 入库。

| 按钮 | 行为 |
|------|------|
| 保存 | 不再次保存；不删除；不清除 `autoScanPausedUntilUserRetry`；`pop` 回体重 H5 |
| 重新测量 | `EquipmentBindService.deleteMonitorData` → 成功则 `clearAutoScanPause` 并 `pop`；失败 Toast 并停留 |

```
WeightScaleResultViewController
        ↓ ViewModel
EquipmentBindService.deleteMonitorData(monitorId)
        DELETE /v1/monitor/delMonitorDataByMonitorId?monitorId=
```

## Risks

- H5 若仍自绘横条可能重复 → 本期原生横条叠在 WebView 上方，H5 可后续隐藏自绘层
- 体重子页（detail/add）各推一层 VC 时会短暂停扫再开扫 → 可接受；同模块内 hash 导航无影响
