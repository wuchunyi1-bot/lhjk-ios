## ADDED Requirements

### Requirement: pageUrl 前缀解析规则

系统 SHALL 对 `getByCode` 的栏位 `pageUrl`，以及 `getCmsConfig` 的 **`quickEntryList[].pageUrl`**（及任何复用同一约定的字段）按以下规则解析（前缀大小写敏感）：

- 以 `FundeH5:` 开头：去掉该前缀后的字符串为 **H5 路由**。
- 以 `FundeApp:` 开头：去掉该前缀后的字符串为 **本地 App 路由**。
- 其他或不识别：视为无法解析（调用方可 no-op 或使用业务兜底）。

解析与打开 MUST 经公共 API（如 `FundePageURL`），MUST NOT 在各 PL 页面复制前缀字符串判断。

#### Scenario: FundeH5

- **WHEN** `pageUrl` 为 `FundeH5:/blood-pressure`（或等价后缀）
- **THEN** 系统打开 H5：使用后缀作为 H5 path，经 `H5Config` 鉴权 URL 进入 `WebViewController`

#### Scenario: FundeApp

- **WHEN** `pageUrl` 为 `FundeApp:/messages` 或带 query（如 `FundeApp:/services/pkg?id=1`）
- **THEN** 系统 `Router.push` 到对应本地 path，并将 query 作为参数传递

#### Scenario: 无法解析

- **WHEN** `pageUrl` 为空或不含上述前缀
- **THEN** 公共解析返回「无目标」；MUST NOT 崩溃

### Requirement: 首页 getByCode 点击使用公共解析

首页栏位（Banner / 金刚区 / 推荐健康套餐）点击传入的 `pageUrl` SHALL 调用公共 `FundePageURL.open`（或等价）。

**例外**：健康陪伴（`home_news_code`）条目点击 MUST NOT 走 `pageUrl`，改走资讯详情 H5 `#/content/detail?id=`（见 `home-news-get-by-code`）。

#### Scenario: 栏位点按

- **WHEN** 用户点击 Banner / 金刚区 / 推荐套餐且 `pageUrl` 非空
- **THEN** 按 FundeH5 / FundeApp 规则跳转

### Requirement: 健康 getCmsConfig 点击使用公共解析

`getCmsConfig` 中 `quickEntryList[].pageUrl` 以及体征监测卡（`monitorCardMeta` / 监测列表）的 `pageUrl` SHALL 在合法时经 `FundePageURL` 打开。

合法指可解析为 `FundeH5:` 或 `FundeApp:`。体征卡无合法 `pageUrl` 时 SHALL 按 `cardType` → `/health/metrics/{key}` 兜底。

#### Scenario: 快捷入口

- **WHEN** 用户点击快捷入口且 `pageUrl` 为 FundeH5 / FundeApp
- **THEN** 按规则打开 H5 或本地路由

#### Scenario: 体征卡有合法 pageUrl

- **WHEN** 用户点击体征监测卡且 `pageUrl` 为 `FundeH5:` 或 `FundeApp:`
- **THEN** 系统经 `FundePageURL.open` 打开

#### Scenario: 体征卡无合法 pageUrl

- **WHEN** 用户点击体征监测卡且 `pageUrl` 为空或无法解析
- **THEN** 系统按 `cardType` 打开对应指标页
