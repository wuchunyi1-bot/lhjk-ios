## Why

当前 iOS 项目的 `/health/record` 路由注册为一个空 `PlaceholderViewController`，需要实现完整的健康档案页面。平行项目 funde-client 已有完整的健康档案原型 (`HealthProfileView.vue`)，包含用户信息卡片、身体风险可视化、体征监测数据、生活习惯、健康史等 5 大模块。

本变更的目标是将 funde-client 健康档案页面的完整需求适配到 iOS UIKit 项目，替换掉当前的占位页面。

## What Changes

- 新增 `HealthRecordViewController`：健康档案主页面，UITableView 5 sections
- 新增子页面 ViewController：基础信息、健康史、生活习惯（均用 placeholder 先占位）
- 新增 3 个自定义 Cell/View 组件：`HealthRecordUserInfoCell`、`HealthRecordBodyCardCell`、`HealthRecordMetricsCell`
- 更新 `HealthRoutes.swift`：将 `/health/record` 及子路由指向新页面
- 所有实现文件放在 `PL/Health/Record/` 独立文件夹下

## Capabilities

### New Capabilities
- `health-record`: 健康档案主页面 spec，包含 5 个 section 的完整布局与交互定义

### Modified Capabilities
- `health`: 更新路由注册，将 `/health/record` 从 Placeholder 替换为 HealthRecordViewController

## Impact

- **PL/Health/Record/**: 新增文件夹，内含 HealthRecordViewController + 3 个 Cell + 数据模型
- **BLL/Health/HealthRoutes.swift**: 更新路由注册（1 行修改）
- **无工程配置变更**：不涉及 Podfile、.xcodeproj 修改
