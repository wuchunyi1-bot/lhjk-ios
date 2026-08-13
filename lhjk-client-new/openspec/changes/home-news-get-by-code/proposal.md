## Why

首页「健康陪伴」仍用 `defaultArticles` 本地假数据。运营约定通过 `GET /v1/columnContent/getByCode` + `code=home_news_code` 配置资讯列表。Apifox `ColumnContentBo` 含 `detail`（作者、浏览次数、标签等），需解码并映射到列表行。

## What Changes

- `ColumnContentService` 增加 `homeNewsCode = "home_news_code"`；冷启动预拉纳入缓存。
- 按 Apifox 扩展 `ColumnContentDTO`：解码 `pageUrl` / `param` / `detail`（`ColumnContentDetailBo`：`authorName`、`clickCount`、`labelName`、`categoryName`、`contentUrl` 等）。
- `HomeViewModel` 经 `ColumnContentCacheService` 拉取；删除 mock；空/失败隐藏 section。
- `HomeArticleCell`：缩略图用远程 `imageUrl`；标题/标签/作者/阅读数来自接口；条目点击打开 H5 `#/content/detail?id={内容ID}`（不走 pageUrl）。
- 「更多 ›」保留，独立 `onMoreTapped`（跳转另定）。
- `docs/api-inventory.md` 注明 `home_news_code`。

## Capabilities

### New Capabilities

- `home-news`：首页健康陪伴通过 `getByCode` + `home_news_code` 加载。

### Modified Capabilities

- （无）

## Impact

- `ColumnContentModels` / `ColumnContentService` / `ColumnContentCacheService` / `ServiceHubBanner`（可选资讯字段）
- `HomeViewModel` / `HomeArticleCell` / `HomeViewController`
- `docs/api-inventory.md`
