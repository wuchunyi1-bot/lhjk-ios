## ADDED Requirements

### Requirement: 首页 Banner 使用 home_banner_code

系统 SHALL 通过 `GET /v1/columnContent/getByCode` 加载首页运营 Banner，Query 参数 `code` MUST 为 `home_banner_code`。MUST NOT 再以本地 Assets（如 `home_banner_1`）作为已接 API 后的数据源。

#### Scenario: 成功有数据

- **WHEN** 接口返回可展示条目（含有效 `imageUrl` 或标题，且 status 允许展示）
- **THEN** 首页 SHALL 展示轮播 Banner，图片使用远程 URL 加载

#### Scenario: 空或失败

- **WHEN** 接口失败或过滤后列表为空
- **THEN** 首页 MUST 隐藏 Banner 区域，MUST NOT 用本地假图填充

#### Scenario: 与服务 Banner 隔离

- **WHEN** 服务 Tab 拉取运营 Banner
- **THEN** 仍使用既有 `mall_advertisement`（或现行默认 code），MUST NOT 误用 `home_banner_code`

### Requirement: 首页出现时拉取

`HomeViewController` 在适当时机（如 `viewWillAppear`）SHALL 触发首页 Banner 拉取，并在数据更新后刷新列表快照。

#### Scenario: 进入首页

- **WHEN** 用户进入首页 Tab
- **THEN** 系统 MUST 请求 `code=home_banner_code` 的栏位内容（或等价封装方法）

### Requirement: Banner 画幅按图片比例

首页 Banner 宽度 MUST 为屏幕宽度；高度 MUST 为 `width × (imageHeight / imageWidth)`。图片未返回前可用 375 稿 `288/375` 作兜底，MUST NOT 把 288pt 写成所有机型的最终高度。同一轮播以第一张成功加载的图为准。

#### Scenario: 宽屏机型

- **WHEN** 在宽于 375pt 的设备（如 17 Pro Max 440pt）展示首页 Banner
- **THEN** 高度随宽度按图片（或兜底）比例放大，MUST NOT 保持 288pt 导致画幅被拉扁
