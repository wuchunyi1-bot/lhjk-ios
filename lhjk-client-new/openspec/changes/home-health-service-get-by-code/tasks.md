## 1. BLL / 缓存

- [x] 1.1 `ColumnContentService` 增加 `homeHealthServiceCode` 与可选 `fetchHomeHealthServices`
- [x] 1.2 `knownPreloadCodes` 纳入 `home_healthService_code`
- [x] 1.3 `docs/api-inventory.md` 注明该 code

## 2. 首页 PL

- [x] 2.1 `HomeViewModel` 经缓存拉取并映射；删 mock；空隐藏 section
- [x] 2.2 `HomeMembershipPackagesCell`：去掉更多；全部主卡纵向排列
- [x] 2.3 `HomeViewController`：去掉 `onMoreTapped`；点击走路由/params
