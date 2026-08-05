## Context

H5 宿主文档：

| 页面 | Hash 路由 | Query |
|------|-----------|-------|
| 体检报告单 | `#/medical-reports` | token、platform |
| 报告详情 | `#/medical-reports/detail` | **reportId** 必填 |
| 上传 | `#/medical-reports/upload` | token、platform |

原生「我的」深链保持 `/me/medical-reports*`（与现有 Me Hub 一致）；另注册 `/medical-reports*` 别名，方便与文档路径对齐。

## Goals / Non-Goals

**Goals:**

- 列表 / 上传 / 详情均走 H5 WebView
- URL 统一经 `H5Config.authenticatedPageURL`

**Non-Goals:**

- 原生体检报告 UI 重做
- 报告 OCR / 上传原生实现（由 H5 完成；若后续需相册权限桥接另立变更）

## Decisions

1. **H5 path** 使用文档字面量 `medical-reports`（非 `me/medical-reports`）。
2. **原生入口** `/me/medical-reports` → 列表 H5；上传/详情用同前缀子路径。
3. **详情** `reportId` 来自路由 params；缺失时仍打开详情页但由 H5 空态处理（原生不造假 id）。

## Risks / Trade-offs

- [H5 内再跳原生深链] → 依赖现有 Router / Bridge；本期仅打开入口页。
