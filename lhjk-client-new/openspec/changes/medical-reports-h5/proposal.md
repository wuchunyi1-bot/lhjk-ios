## Why

宿主文档已定义体检报告 H5（`#/medical-reports` 及 detail/upload），「我的」入口 `/me/medical-reports` 仍为 Placeholder，用户无法查看/上传报告。

## What Changes

- `H5Config` 增加体检报告列表 / 详情 / 上传鉴权 URL（`token` + `platform=ios`）
- `/me/medical-reports`、`/me/medical-reports/upload`、`/me/medical-reports/detail`（及可选别名 `/medical-reports*`）改为 `WebViewController` 打开对应 H5
- 详情页 Query 必传 `reportId`（禁止 mock 假 id）

## Capabilities

### New Capabilities

- `medical-reports-h5`: 体检报告单 H5 宿主接入（列表 / 详情 / 上传）

### Modified Capabilities

- （无）

## Impact

- `Other/Common/H5Config.swift`
- `BLL/My/MyRoutes.swift`
- 「我的」体检报告单入口可直达 H5
