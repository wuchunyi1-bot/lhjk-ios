## 1. BLL

- [x] 1.1 `ColumnContentService` 增加 `homeBannerCode = "home_banner_code"` 与 `fetchHomeBanners()`（复用 getByCode）
- [x] 1.2 抽取共用 `fetchBanners(code:)`，服务端 `fetchHospitalBanners` 行为不变

## 2. Home PL

- [x] 2.1 `HomeViewModel` 增加 `banners` + `loadBanners()`；空则去掉 banner section
- [x] 2.2 `HomeBannerCarouselCell` 改为 `configure` 远程图（Kingfisher），去掉本地假图源
- [x] 2.3 `HomeViewController` 进入页触发拉取并配置 Cell

## 3. 文档

- [x] 3.1 `docs/api-inventory.md` 注明 getByCode 的 `mall_advertisement` / `home_banner_code`
- [x] 3.2 勾选本 tasks
