## ADDED Requirements

### Requirement: 首页推荐套餐使用 home_healthService_code

系统 SHALL 通过 `GET /v1/columnContent/getByCode` 加载首页「推荐健康套餐」，Query `code` MUST 为 `home_healthService_code`。MUST NOT 在接入后继续使用 `defaultMembershipPackages`（或等价 mock）作为数据源。

#### Scenario: 成功有数据

- **WHEN** 接口返回带有效 `imageUrl` 的可展示条目
- **THEN** 首页 SHALL 展示「推荐健康套餐」区块，并以远程图片纵向列表呈现；MUST NOT 使用自绘价卡（价格/名称/简介/CTA）样式

#### Scenario: 空或失败

- **WHEN** 接口失败或过滤后无有效图片
- **THEN** 首页 MUST 隐藏该 section，MUST NOT 用本地假套餐填充

#### Scenario: 缓存

- **WHEN** 冷启动已缓存 `home_healthService_code` 或首页再次加载
- **THEN** SHALL 经 `ColumnContentCacheService` 按既有 getByCode 缓存策略读取（命中复用 / 未命中请求 / 登出清空）

### Requirement: 无「更多套餐」入口

推荐健康套餐区块 MUST NOT 展示「更多套餐」或等价入口；MUST NOT 再注册依赖该入口跳转 `/services/membership` 的 UI 行为（作为本区块默认交互）。

#### Scenario: 区块标题区

- **WHEN** 推荐套餐区块可见
- **THEN** 仅展示标题「推荐健康套餐」，右侧无「更多套餐 ›」

### Requirement: 条目纵向图片排列

推荐套餐列表 SHALL 将每条有图数据以远程图片纵向依次排列。MUST NOT 再使用「第一排 1 个主卡 + 第二排 2 个副卡」布局，也 MUST NOT 再使用自绘主卡文案样式。

#### Scenario: 多条数据

- **WHEN** 接口返回 N（N≥1）条带图套餐
- **THEN** UI 展示 N 张图片，自上而下排列，间距一致
