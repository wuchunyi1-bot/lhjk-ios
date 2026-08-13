## Why

「我的 → 健康管理」中监测方案、健康评估已有原生占位/原型页，宿主 H5 路径分别为 `#/monitoring-plan`、`#/health-assessment`。应对齐体检报告单等已有接入方式，改为鉴权 WebView 打开 H5。

## What Changes

- `H5Config` 增加监测方案、健康评估鉴权 URL（`token` + `platform=ios`）
- 原生路由 `/me/monitoring-plan`、`/me/health-assessment` 改为 `WebViewController` 打开对应 H5
- 注册文档路径别名 `/monitoring-plan`、`/health-assessment`
- 「我的」Hub 入口路由保持 `/me/monitoring-plan`、`/me/health-assessment`（无需改 `MyViewModel` 文案路径）
- 原原生 `MonitoringPlanViewController` / Placeholder 不再作为上述入口承载（文件可暂留，不强制删除）

## Capabilities

### New Capabilities

- `me-monitoring-assessment-h5`：我的健康管理 — 监测方案 / 健康评估 H5 宿主接入

### Modified Capabilities

- （无）

## Impact

- `Other/Common/H5Config.swift`
- `BLL/My/MyRoutes.swift`
- 「我的」健康管理两项入口可直达 H5
