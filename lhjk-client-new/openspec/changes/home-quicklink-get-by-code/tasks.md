## 1. BLL / 缓存

- [x] 1.1 `ColumnContentService` 增加 `homeQuickLinkCode = "home_quickLink_code"`（可选薄封装 `fetchHomeQuickLinks`）
- [x] 1.2 `ColumnContentCacheService.knownPreloadCodes` 纳入 `home_quickLink_code`
- [x] 1.3 `docs/api-inventory.md` 注明该 code

## 2. 首页 PL

- [x] 2.1 `HomeViewModel` 经缓存拉取金刚区；映射为 UI Action；空则隐藏 section
- [x] 2.2 删除 `defaultQuickActions` mock
- [x] 2.3 `HomeQuickActionsCell` 支持远程 `imageUrl`（Kingfisher）
