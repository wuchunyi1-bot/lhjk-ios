## Why

预约体检列表已经接到 `medicalConfigList`，卡片仍是名称加价格。线上返回里已经有封面、HTML 简介、价格和购买方式，页面应对齐 Vue 可预约套餐卡片。

## What Changes

- 预约体检列表按 Vue `ExamPackageCard` 的 bookable 版式渲染 `medicalConfigList` 列表项。
- 点卡片进入项目预约详情；点「去预约」先确认。`payType = 2` 且有套包 id 时去购买套包。
- 就医协助首页复用同一张卡片。

## Capabilities

### New Capabilities

- `exam-appointment`: 预约体检列表的数据字段和可预约卡片。

### Modified Capabilities

## Impact

- `ServiceItemService` 的列表模型、`ExamPackageCell`、预约体检与就医协助列表。
- 使用记录和群聊分配仍没有接口，本变更不接。
