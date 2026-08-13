## Context

Apifox（只读）：[根据栏位code查询已绑定的展示位内容列表](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/484052032e0.md)

- Path：`GET /v1/columnContent/getByCode`，Query 必填 `code`
- `data[]`：`ColumnContentBo`（id、contentId、contentType、name、imageUrl、categoryName、status、pageUrl、param、**detail**…）
- `detail`：`ColumnContentDetailBo`（authorName、clickCount、likeCount、labelName、categoryName、contentUrl、pageUrl、description、recommend、adContentType…）
- `adContentType`：1 banner / 2 单品 / 3 套餐 / 4 活动 / **5 资讯内容**

首页 Banner / 金刚区 / 推荐套餐已走同一 path + 缓存；健康陪伴仍为 mock。

## Goals / Non-Goals

**Goals:**

- `code=home_news_code`，缓存/预拉/空态对齐其它首页栏位
- 解码 `detail`，列表展示标题、标签、作者、阅读数、远程缩略图
- 点击：打开 H5 `#/content/detail?id={内容ID}`（不走 pageUrl）；见宿主资讯详情约定
- 删除 mock；保留「更多 ›」并独立回调


**Non-Goals:**

- 不新增独立资讯列表 API
- 不实现点赞等互动
- 不改 Apifox

## Decisions

### 1. Code

```swift
static let homeNewsCode = "home_news_code"
```

### 2. DTO 对齐 Apifox

扩展 `ColumnContentDTO`：

- 顶层：`pageUrl`、`param`（灵活 String/Int）
- 嵌套：`detail: ColumnContentDetailDTO?`

`toHubBanner` 将资讯相关字段写入 `ServiceHubBanner` 扩展可选属性（authorName、clickCount、labelName、pageUrl、contentUrl），供 Home 映射且不破坏既有 Banner/金刚区用法。

### 3. UI 映射

| 来源 | 列表行 |
|------|--------|
| name | title |
| imageUrl | 缩略图 Kingfisher |
| detail.labelName ?? detail.categoryName ?? categoryName | tag（空则隐藏标签） |
| detail.authorName | author |
| detail.clickCount | reads（格式化，如 `1234` → `1.2K 阅读` / `128 阅读`） |
| contentId（或 param） | 点击 → H5 `#/content/detail?id=` |
| pageUrl | 健康陪伴条目点击 **不使用** |
| contentType | 健康陪伴条目点击 **不使用** |

### 3.1 资讯详情 H5

```
H5Config.contentDetailPageURL(contentId:)
→ {origin}/#/content/detail?id={id}&platform=ios[&token=…]
```

本页接口无需登录，token 可选。

### 4. 空态与更多

- 过滤后无标题且无图 → 不展示该行；整表空 → 隐藏 section
- 「更多 ›」保留，点击走 `onMoreTapped`（与条目 pageUrl 分离）

## Risks

- [detail 为空] → 仅展示 name + 图；作者/阅读数为空串或隐藏
- [无 contentId] → 点击 no-op

## Migration Plan

1. OpenSpec
2. DTO + Banner 字段 + code/预拉/inventory
3. Home VM + Cell + VC 点击

## Open Questions

无。
