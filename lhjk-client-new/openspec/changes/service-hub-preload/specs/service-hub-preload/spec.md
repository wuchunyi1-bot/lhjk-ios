## ADDED Requirements

### Requirement: 服务 Hub 静态层会话内缓存（无 TTL）

系统 SHALL 在 BLL `ServiceHubCacheService` 中以内存缓存服务首页静态数据（banners、matrix、categories），并通过 `hasLoadedStatic` 标记是否已在本会话加载成功。系统 MUST NOT 使用基于时间的 TTL 过期策略。

#### Scenario: 会话内复用静态缓存

- **WHEN** 本会话已成功加载静态层（`hasLoadedStatic == true`）
- **THEN** 再次请求静态数据时 MUST 直接返回内存缓存，MUST NOT 重复发起 banners / matrix / categories 网络请求（除非 `forceReload`）

#### Scenario: 冷启动后静态层视为未加载

- **WHEN** App 冷启动进入已登录主界面，或登出后再次登录进入主界面
- **THEN** 静态缓存 MUST 为空或已被 `clear()`，`hasLoadedStatic` MUST 为 `false`，随后 SHALL 重新拉取静态层

### Requirement: 冷启动预拉静态层

系统 SHALL 在用户已登录并进入主界面后，延迟预拉服务 Hub 静态层（banners、matrix、categories），且 MUST NOT 在预拉阶段请求 packages。

#### Scenario: 冷启动延迟预拉

- **WHEN** 冷启动（或登录成功）将根视图设为 `RootTabBarController`
- **THEN** 系统 SHALL 在约 1～2 秒延迟后调用 `ServiceHubCacheService.preloadStatic()`（由 `RootTabBarController` 调度）
- **AND** 预拉 MUST 并行请求 banners、matrix、categories
- **AND** 预拉成功后 `hasLoadedStatic` MUST 为 `true`

#### Scenario: 未登录不预拉

- **WHEN** 根视图为登录页（无有效 token）
- **THEN** 系统 MUST NOT 预拉服务 Hub 数据

#### Scenario: 预拉 in-flight 去重

- **WHEN** 预拉进行中，服务 Tab 或其它调用方再次触发 `preloadStatic()`
- **THEN** 系统 MUST 复用同一 in-flight 任务，MUST NOT 并行发起两套静态层请求

### Requirement: Packages 按类目缓存且不预拉

系统 SHALL 按推荐类目 id 缓存 packages 列表；冷启动预拉 MUST NOT 包含 packages。首次需要某类目套餐时再请求，同会话同 key 复用。

#### Scenario: 首次进入服务 Tab 拉当前类目 packages

- **WHEN** 用户进入服务 Tab 且当前选中类目的 packages 尚未缓存
- **THEN** 系统 SHALL 调用套包分页接口拉取该类别目首屏 packages 并写入缓存

#### Scenario: 切换已缓存类目

- **WHEN** 用户切换到本会话已缓存过 packages 的类目
- **THEN** 系统 MUST 直接使用缓存列表，MUST NOT 重复请求该类别目 packages（除非 `forceReload`）

#### Scenario: 切换未缓存类目

- **WHEN** 用户切换到尚未缓存 packages 的类目
- **THEN** 系统 SHALL 请求并缓存该类目 packages

### Requirement: 服务首页缓存优先展示

`ServiceViewModel` SHALL 优先使用 `ServiceHubCacheService` 缓存组装 UI 快照；`viewWillAppear` / `load()` MUST NOT 在静态层已加载时无条件全量重打四个接口。

#### Scenario: 有静态缓存时立刻上屏

- **WHEN** 用户进入服务 Tab 且静态缓存已存在
- **THEN** UI MUST 先用缓存渲染 banners / matrix / categories（及已有 packages）
- **AND** 若当前类目 packages 缺失，再后台补拉并更新推荐区

#### Scenario: 无静态缓存时现场加载

- **WHEN** 用户进入服务 Tab 且 `hasLoadedStatic == false`（预拉未完成或失败）
- **THEN** ViewModel SHALL 触发 `preloadStatic()` 并等待结果后再展示静态区

### Requirement: 强制刷新与登出清空

系统 SHALL 提供绕过缓存的强制刷新，并在登出时清空服务 Hub 缓存。

#### Scenario: forceReload

- **WHEN** 调用 `ServiceHubCacheService.forceReload()`（如下拉刷新）
- **THEN** 系统 SHALL 清空静态与 packages 缓存，重新拉取静态层与当前类目 packages

#### Scenario: 登出 clear

- **WHEN** 用户登出并清除本地会话
- **THEN** 系统 SHALL 调用 `ServiceHubCacheService.clear()`，使 `hasLoadedStatic == false` 且 packages 缓存为空

#### Scenario: 热启动不自动重拉

- **WHEN** App 从后台回到前台（热启动）
- **THEN** 系统 MUST NOT 仅因回前台而自动重拉服务 Hub 数据

### Requirement: 激活 Banner 仍读本地态

激活引导 Banner 的显隐 SHALL 继续由 `VoucherService.isCardActivated` 决定，MUST NOT 因 Hub 预加载而改为网络字段。

#### Scenario: 卡激活后更新 Banner

- **WHEN** 收到 `VoucherService.cardActivationDidChange`
- **THEN** 系统 SHALL 在现有快照上更新 `showActivateBanner`，MUST NOT 因此强制全量重拉静态层
