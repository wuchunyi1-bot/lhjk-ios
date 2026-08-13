## 1. BLL / Apifox 对齐

- [x] 1.1 扩展 `ColumnContentDTO`：`pageUrl` / `param` / `detail`（含 authorName、clickCount、labelName、contentUrl 等）
- [x] 1.2 `toHubBanner` 带上资讯可选字段；`homeNewsCode` + 预拉 + inventory

## 2. 首页 PL

- [x] 2.1 `HomeViewModel` 拉取映射；删 mock；空隐藏 section
- [x] 2.2 `HomeArticleCell` 远程图 + 接口字段；保留「更多」独立回调
- [x] 2.3 条目点击打开 H5 `#/content/detail?id=`（`H5Config.contentDetailPageURL`）；不走 pageUrl
