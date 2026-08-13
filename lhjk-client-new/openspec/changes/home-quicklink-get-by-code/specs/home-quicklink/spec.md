## ADDED Requirements

### Requirement: 首页金刚区使用 home_quickLink_code

系统 SHALL 通过 `GET /v1/columnContent/getByCode` 加载首页金刚区（快捷入口），Query 参数 `code` MUST 为 `home_quickLink_code`。MUST NOT 在已接入该接口后继续使用本地写死的 `defaultQuickActions`（或等价 mock）作为数据源。

#### Scenario: 成功有数据

- **WHEN** 接口返回可展示条目（过滤规则与栏位内容一致，且具备可展示标题或图标）
- **THEN** 首页 SHALL 展示金刚区；图标优先使用远程 `imageUrl` 加载

#### Scenario: 空或失败

- **WHEN** 接口失败或过滤后列表为空
- **THEN** 首页 MUST 隐藏金刚区 section，MUST NOT 用本地 mock 快捷项填充

#### Scenario: 与 Banner / 服务栏位隔离

- **WHEN** 首页拉取 Banner 或服务 Hub 拉取运营 Banner
- **THEN** 仍分别使用 `home_banner_code` / `mall_advertisement`，MUST NOT 误用 `home_quickLink_code`

### Requirement: 经 ColumnContent 缓存读取

首页金刚区 SHALL 通过 `ColumnContentCacheService`（或等价统一缓存）按 `home_quickLink_code` 获取：冷启动 MAY 预拉该 code；有成功缓存则复用且 MUST NOT 无故重打；未命中再请求；登出 MUST 清空缓存（与既有 getByCode 缓存策略一致）。

#### Scenario: 缓存命中

- **WHEN** 冷启动已成功缓存 `home_quickLink_code`
- **THEN** 首页再次加载金刚区 MUST 使用缓存数据，MUST NOT 重复请求该 code（同 in-flight 去重规则）

#### Scenario: 进入首页拉取

- **WHEN** 用户进入首页 Tab 并触发内容刷新
- **THEN** 系统 MUST 按上述缓存规则获取 `code=home_quickLink_code` 的栏位内容
