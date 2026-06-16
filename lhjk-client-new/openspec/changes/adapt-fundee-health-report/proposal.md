## Why

当前 iOS 项目的 `/health/assessment/report` 路由注册为 `PlaceholderViewController`。PL/My/ 下已有 `HealthReportViewController` 基础骨架（Tab 切换 + 报告卡片），但缺少 funde-client `HealthReportView.vue` 中「阶段小结」的**量化改善指标 grid**——即 before → after 对比卡片（如血压达标率 52% → 85%）。

本变更将：
1. 补充缺失的 metrics delta grid 组件
2. 将路由从 Placeholder 切换到完整实现
3. 沉淀完整 spec 文档

## What Changes

- 新增 `StageMetricsCardView.swift` — 阶段小结的 2×2 量化改善指标卡片
- 增强 `HealthReportViewController.swift` — 在 stageReports 卡片中嵌入 metrics grid
- 新增 mock 数据模型 `HealthReportModels.swift`
- 更新 `HealthRoutes.swift` — `/health/assessment/report` 指向 `HealthReportViewController`
- 所有增强文件记录 spec

## Capabilities

### New Capabilities
- `health-report`: 健康报告页面 spec，包含周报/阶段小结双 Tab + 量化改善指标 grid

### Modified Capabilities
- `health`: 路由 `/health/assessment/report` 从 Placeholder 替换为 HealthReportViewController

## Impact

- **PL/My/HealthReportViewController.swift**: 增强 stageReports 渲染逻辑，内嵌 metrics grid
- **PL/My/StageMetricsCardView.swift**: 新增组件
- **BLL/Health/HealthRoutes.swift**: 更新路由注册
- **无工程配置变更**
