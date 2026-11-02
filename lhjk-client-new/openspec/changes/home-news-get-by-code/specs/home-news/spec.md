## ADDED Requirements

### Requirement: 首页健康陪伴使用 home_news_code

系统 SHALL 通过 `GET /v1/columnContent/getByCode` 加载首页「健康陪伴」，Query `code` MUST 为 `home_news_code`（Apifox：栏位内容 getByCode）。MUST NOT 在接入后继续使用 `defaultArticles` mock。

客户端 SHALL 解码 `ColumnContentBo.detail`（若有），用于作者、浏览次数、标签等展示字段。

#### Scenario: 成功有数据

- **WHEN** 接口返回可展示资讯条目（status 允许且具备标题或图片）
- **THEN** 首页 SHALL 展示「健康陪伴」列表；缩略图使用远程 `imageUrl`；标题取 `name`；标签/作者/阅读数优先取自 `detail`

#### Scenario: 空或失败

- **WHEN** 接口失败或过滤后为空
- **THEN** 首页 MUST 隐藏该 section，MUST NOT 用本地假文章填充

#### Scenario: 缓存

- **WHEN** 冷启动预拉或首页再次加载
- **THEN** SHALL 经 `ColumnContentCacheService` 按既有 getByCode 策略处理 `home_news_code`

### Requirement: 健康陪伴条目点击打开资讯详情 H5

健康陪伴（`home_news_code`）列表条目点击 MUST NOT 走栏位 `pageUrl` / `FundePageURL`。

系统 SHALL 打开 H5 资讯详情页：

- Hash 路径：`#/content/detail`
- Query **必填** `id`：内容 ID（优先 `ColumnContentBo.contentId`，其次 `param` / `detail.param`）
- 本页接口无需登录；`token` 可不传（有则仍可附带；`platform=ios` 可按既有 H5 约定附带）

实现上 SHALL 经 `H5Config.contentDetailPageURL(contentId:)`（或等价）构建 URL，并用 `WebViewController` 打开。

#### Scenario: 有内容 ID

- **WHEN** 用户点击健康陪伴条目且能解析出非空内容 ID
- **THEN** 打开 `#/content/detail?id={内容ID}` 对应 H5

#### Scenario: 无内容 ID

- **WHEN** 用户点击条目但内容 ID 为空
- **THEN** MUST NOT 崩溃（可 no-op）

### Requirement: 资讯详情分享到微信

从健康陪伴或搜索结果打开的资讯详情 SHALL 在导航栏右侧展示功能按钮。点击后底部弹出「分享」和「复制链接」。卡片标题和封面用打开详情的那条列表 item，不向小程序传 `shareId`。

#### Scenario: 打开功能菜单

- **WHEN** 用户点击导航栏右侧功能按钮
- **THEN** 底部弹出「分享」和「复制链接」
- **AND** 此时不得调用 `POST /v1/content/share`

#### Scenario: 复制文章链接

- **WHEN** 用户点击「复制链接」
- **THEN** 将不含登录 token 的资讯详情链接写入剪贴板
- **AND** 提示「链接已复制」
- **AND** 不得调用 `POST /v1/content/share`

#### Scenario: 分享给个人

- **WHEN** 用户在菜单中点击「分享」且已安装微信
- **THEN** 拉起微信会话分享小程序卡片
- **AND** 原始 id 为 `gh_2b2bf2033426`
- **AND** 非生产环境打开体验版小程序，生产环境打开正式版
- **AND** 页面为 `pkg-common/webview/index?articleId={内容ID}`
- **AND** 不发朋友圈

#### Scenario: 记录分享次数

- **WHEN** 用户在菜单中点击「分享」且已安装微信
- **THEN** 立刻调用 `POST /v1/content/share`，Query `contentId` 为该文章 ID
- **AND** 不等微信分享回调，也不等用户回到 App
- **WHEN** 未安装微信
- **THEN** 不调用该接口
- **WHEN** 已发起分享后回到 App，且微信没有再回调
- **THEN** 导航栏功能按钮恢复可点，不得一直保持禁用

### Requirement: 健康陪伴「更多」打开列表 H5

健康陪伴区块 MUST 展示「更多 ›」。该按钮点击 MUST 走独立回调，MUST NOT 与条目资讯详情点击共用同一处理逻辑。

系统 SHALL 打开 H5 健康陪伴列表页：

- Hash 路径：`#/companion`
- 需登录；打开时 MUST 拼接 `platform=ios`，有登录态时 MUST 拼接 `token`
- 实现上 SHALL 经 `H5Config.companionPageURL` 构建 URL，并用 `WebViewController` 打开；原生路由 `/companion` 与 CMS `FundeH5:/companion` 等价

#### Scenario: 标题区

- **WHEN** 健康陪伴区块可见
- **THEN** 展示标题「健康陪伴」与「更多 ›」；点击「更多 ›」打开 `#/companion` H5（导航栏标题「健康陪伴」）

#### Scenario: 深链与 CMS

- **WHEN** `Router.push("/companion")` 或 `pageUrl` 为 `FundeH5:/companion`
- **THEN** 打开与首页「更多 ›」相同的鉴权 H5 URL
