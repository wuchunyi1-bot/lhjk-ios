## ADDED Requirements

### Requirement: 体检报告 H5 URL 构建

系统 SHALL 通过 `H5Config` 构建体检报告相关鉴权 URL，拼接 `token`（若有）与 `platform=ios`。

#### Scenario: 列表页 URL

- **WHEN** 请求体检报告列表 H5
- **THEN** URL 形态为 `{base}#/medical-reports?token=…&platform=ios`（无 token 时仍带 platform）

#### Scenario: 上传页 URL

- **WHEN** 请求上传体检报告 H5
- **THEN** URL 形态为 `{base}#/medical-reports/upload?token=…&platform=ios`

#### Scenario: 详情页 URL

- **WHEN** 请求报告详情且提供 `reportId`
- **THEN** URL 含 `#/medical-reports/detail` 且 Query 含该 `reportId`
- **AND** 不得使用 mock / 硬编码假 reportId

### Requirement: 原生路由接入 WebView

系统 SHALL 将体检报告相关原生路由指向 `WebViewController` 加载上述 H5。

#### Scenario: 我的入口列表

- **WHEN** 导航至 `/me/medical-reports`（或别名 `/medical-reports`）
- **THEN** 打开标题为「体检报告单」的 WebView，加载列表 H5

#### Scenario: 上传

- **WHEN** 导航至 `/me/medical-reports/upload`（或 `/medical-reports/upload`）
- **THEN** 打开标题为「上传体检报告」的 WebView，加载上传 H5

#### Scenario: 详情

- **WHEN** 导航至 `/me/medical-reports/detail`（或 `/medical-reports/detail`）且 params 含 `reportId`
- **THEN** 打开标题为「报告详情」的 WebView，加载详情 H5 并带上 `reportId`
