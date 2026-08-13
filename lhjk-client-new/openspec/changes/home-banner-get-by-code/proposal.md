## Why

首页 Banner 仍使用本地资源图（`home_banner_1/2/3`）。运营需通过栏位内容接口配置首页轮播；服务 Tab 已用 `GET /v1/columnContent/getByCode` + `code=mall_advertisement`，首页需增加独立 code：`home_banner_code`。

## What Changes

- `ColumnContentService` 增加首页栏位常量 `home_banner_code` 与拉取方法（复用同一 path）。
- `HomeViewModel` 拉取首页 Banner；空列表隐藏 Banner 区，**不再**用本地假图顶替。
- `HomeBannerCarouselCell` 改为展示远程 `imageUrl`（Kingfisher）。
- 更新 `docs/api-inventory` 注明该 path 的两处 code。

## Capabilities

### New Capabilities

- `home-banner`：首页运营 Banner 通过 `getByCode` + `home_banner_code` 加载。

### Modified Capabilities

- （无归档主 spec；行为以本 change 为准。）

## Impact

- `BLL/Service/ColumnContentService.swift`
- `PL/Home/ViewModels/HomeViewModel.swift`
- `PL/Home/Cells/HomeBannerCarouselCell.swift`
- `PL/Home/HomeViewController.swift`
- `docs/api-inventory.md`
