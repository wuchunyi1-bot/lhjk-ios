## Why

首页「推荐健康套餐」仍用 `defaultMembershipPackages` mock，且 UI 为「一主二副」+「更多套餐」。运营需通过 `getByCode` + `home_healthService_code` 配置；布局改为全部主卡纵向排列，并去掉更多入口。

## What Changes

- `ColumnContentService` 增加 `homeHealthServiceCode = "home_healthService_code"`；冷启动预拉纳入 `ColumnContentCacheService`。
- `HomeViewModel` 经缓存加载推荐套餐；删除 mock；空/失败隐藏 section。
- UI：**移除「更多套餐」**；子项全部使用与首卡相同的主卡样式，**纵向依次排列**（不再一排 1 + 一排 2）。
- 点击走栏位 `contentType/contentId` 解析出的路由（默认套餐 `/services/pkg`）。
- `docs/api-inventory.md` 注明该 code。

## Capabilities

### New Capabilities

- `home-health-service`：首页推荐健康套餐通过 `getByCode` + `home_healthService_code` 加载，并调整列表布局。

### Modified Capabilities

- （无）

## Impact

- `ColumnContentService` / `ColumnContentCacheService`
- `HomeViewModel` / `HomeMembershipPackagesCell` / `HomeViewController`
- `docs/api-inventory.md`
