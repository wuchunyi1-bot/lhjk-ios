## Context

funde-client 商城页结构：

1. NavBar「富德优选」
2. 横向滚动分类 Tab（`全部` + 业务二级分类）
3. 双栏套餐网格（封面 1:1、角标、名称、卖点、价格、购买）
4. 底部「正品保障 · 德好健康监制 · 7天无忧退换」

原型阶段 funde 用 mock 本地过滤；iOS 改为**切换 Tab 请求接口**。

## API

| 用途 | 接口 | 文档 |
|------|------|------|
| Tab 栏目 | `GET /v1/hospitalPackage/getCategoryServiceListByType?type=2` | [487882771e0](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/487882771e0) |
| 商品列表 | `GET /v1/hospitalPackage/getEnabledRetailHospitalPackagePage` | [487882770e0](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/487882770e0) |

**Tab 请求**：`type=2`（零售类），`hospitalId` 不传。

**商品请求**：

- 「全部」：`categoryServiceId=""`，`pageNum=1`，`pageSize=50`
- 指定分类：`categoryServiceId={Tab.id}`

## Decisions

### 1. Tab 模型 `MallCategoryTab`

```swift
struct MallCategoryTab: Equatable {
    let id: String?   // nil = 全部
    let title: String
}
```

首屏 tabs = `[.all] + apiCategories.map { MallCategoryTab(id: $0.id, title: $0.serviceName) }`

### 2. 切换 Tab 重新拉取

与 funde mock「本地过滤」不同，iOS 每次切换 Tab 调用零售分页接口（首版不分页，单页 `pageSize=50`）。

### 3. UI 组件

- `MallCategoryTabBar`：横向 `UIScrollView` + 胶囊按钮，激活态 `fdPrimary` 底
- `MallProductCell`：封面 1:1（Kingfisher）、单行名称/卖点、价格 + 购买
- 空态：「该分类暂无商品，敬请期待」

## Non-Goals

- 商城内无限滚动（后续可复用 Hub `loadMore`）
- 商品搜索、排序
