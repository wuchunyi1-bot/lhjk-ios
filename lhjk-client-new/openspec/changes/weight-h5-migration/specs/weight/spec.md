# Weight Module Delta — weight-h5-migration

## MODIFIED Requirements

### Requirement: 体重模块入口（H5）

体重模块 SHALL 以 WebView 加载 H5 页面 `#/weight`，App 不再承载原生录入 / 展示 / 详情页。

#### Scenario: 健康页 / 体征网格进入体重

- **WHEN** 用户从健康 Hub 或体征监测页点击「体重」卡片
- **THEN** 跳转 `/health/metrics/weight`
- **AND** 打开 `WebViewController`，加载 `H5Config.weightPageURL`（development: `http://192.168.15.249:5181/#/weight`）
- **AND** 导航标题为「体重」

#### Scenario: 子路由兼容

- **WHEN** App 内部触发 `/health/metrics/weight/manual`、`/history`、`/service`、`/detail`
- **THEN** 同样打开 H5 `#/weight`（H5 内部管理其子流程）

#### Scenario: 录入入口

- **WHEN** 用户从 `/health/metrics/add?key=weight` 进入
- **THEN** 打开 H5 `#/weight`

### Requirement: H5 环境配置

系统 SHALL 通过 `H5Config` 按环境提供 H5 base URL。

| 环境 | base URL |
|------|----------|
| development | `http://192.168.15.249:5181` |
| staging | `https://staging-h5.lhjk.com`（待定） |
| production | `https://h5.lhjk.com`（待定） |

#### Scenario: 体重 H5 URL

- **WHEN** 构造体重 H5 入口
- **THEN** `H5Config.weightPageURL = baseURL + "#/weight"`

## REMOVED Requirements

### Requirement: 体重原生录入 / 展示 / 详情接口调用

**Reason**: 体重模块整体迁移 H5，App 不再调用 `WeightService` 接口、不再渲染原生页面。

**Migration**: 原生代码（`WeightService`、`WeightViewController` 等）暂保留不删，仅断开路由引用，便于回退。
