## ADDED Requirements

### Requirement: 用药 / 营养补剂 / 血氧进入宿主路由表

系统 SHALL 将用药、营养补剂、血氧登记为需登录 H5：hash 分别为 `#/medication`、`#/supplement`、`#/spo2`；iOS 分别以 `/medication`、`/supplement`、`/spo2`（血氧另有 `/health/metrics/spo2`）打开。打开时 MUST 拼接 `platform=ios`，有登录态时 MUST 拼接 `token`。

#### Scenario: CMS FundeH5 用药

- **WHEN** `pageUrl` 为 `FundeH5:/medication`
- **THEN** 打开 `{base}/#/medication?token=…&platform=ios`

#### Scenario: 原生短链营养补剂

- **WHEN** `Router.push("/supplement")` 或 `FundeApp:/supplement`
- **THEN** 打开标题为「营养补剂」的 `WebViewController`，URL 为营养补剂鉴权 H5

#### Scenario: 血氧短链与体征卡等价

- **WHEN** 打开 `/spo2` 或 `/health/metrics/spo2`
- **THEN** 两者均加载 `#/spo2` 鉴权 URL
