## ADDED Requirements

### Requirement: FundeBridge 套餐跳转

iOS `WebViewController` SHALL 注册 `FundeBridge` script message handler。当 H5 发送 `action=navigatePackageDetail` 且 `packageId` 非空时，SHALL 打开原生套餐详情页。

#### Scenario: 查看套餐

- **WHEN** H5 调用 `window.webkit.messageHandlers.FundeBridge.postMessage`，body 含 `action=navigatePackageDetail` 与非空 `packageId`
- **THEN** 宿主 `openPackageDetail(packageId:hospitalId:)` push `/services/pkg`（参数 `id`、可选 `hospitalId`）
- **AND** 目标为 `ServicePackageDetailViewController`，MUST NOT 再打开 H5 套餐页

#### Scenario: packageId 为空

- **WHEN** `packageId` 缺失或空白
- **THEN** MUST NOT 导航
