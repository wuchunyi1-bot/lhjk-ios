## ADDED Requirements

### Requirement: 冷启动预拉 getByCode 已知栏位

系统 SHALL 在用户进入主界面后的冷启动预拉阶段，对已知栏位 code（至少包含 `home_banner_code` 与 `mall_advertisement`）调用 `GET /v1/columnContent/getByCode` 并将成功结果写入内存缓存。缓存 MUST NOT 使用 TTL；进程重启后 MUST 重新预拉。

#### Scenario: 冷启动预拉

- **WHEN** App 以已登录态进入 `RootTabBarController` 并触发 Hub 预拉
- **THEN** 系统 MUST 请求上述已知 code 的栏位内容并缓存成功响应

#### Scenario: 预拉失败不占位

- **WHEN** 某一 code 预拉网络失败
- **THEN** 该 code MUST NOT 被标记为已缓存，以便后续界面读取时重试

### Requirement: 界面优先读缓存

首页与服务 Hub 读取运营 Banner 时，SHALL 通过统一缓存服务按 `code` 获取：若该 code 已有成功缓存则 MUST 直接返回缓存且 MUST NOT 再发网；若无缓存则 MUST 请求服务端，成功后写入缓存再返回。

#### Scenario: 缓存命中

- **WHEN** 冷启动已成功缓存 `home_banner_code`
- **THEN** 首页再次 `loadBanners` MUST 使用缓存数据，MUST NOT 重复请求该 code

#### Scenario: 缓存未命中

- **WHEN** 某 code 尚未成功缓存（含预拉失败）
- **THEN** 界面读取 MUST 触发一次网络拉取；并发读取同一 code MUST 合并为同一 in-flight 请求

#### Scenario: 登出清空

- **WHEN** 用户登出或会话失效清理本地态
- **THEN** 系统 MUST 清空 getByCode 内存缓存
