## Context

服务 Hub：`ColumnContentService.fetchHospitalBanners()` → `code=mall_advertisement`。  
首页：`HomeBannerCarouselCell` 硬编码本地图，未接 API。

## Goals / Non-Goals

**Goals:**

- 首页 Banner：`GET /v1/columnContent/getByCode?code=home_banner_code`
- 复用 `ColumnContentDTO` / `ColumnContentMapper.toHubBanner` → `ServiceHubBanner`
- 空/失败：隐藏 Banner section，禁止本地 mock 图顶替

**Non-Goals:**

- 不改服务 Tab 的 `mall_advertisement`
- 首页 Banner 宽度全屏；高度按图片比例（未加载前 `288/375` 兜底），不再写死 288pt
- 不做独立首页缓存服务（随 `viewWillAppear` 拉取即可；可后续对齐 Hub 预加载）

## Decisions

### 1. Code 常量

```swift
static let homeBannerCode = "home_banner_code"
```

与后端约定一字不差。

### 2. Service API

```swift
func fetchBanners(code: String) async throws -> [ServiceHubBanner]
func fetchHomeBanners() async throws -> [ServiceHubBanner] // code = homeBannerCode
func fetchHospitalBanners() // 仍默认 mall_advertisement
```

过滤规则与现网一致：`status==1`（或 nil）且有图或标题。

### 3. Home 编排

`HomeViewModel.loadBanners()` → `ColumnContentService.fetchHomeBanners()`；`banners` 空则 snapshot 去掉 `.banner` section。

### 4. Cell

`configure(_ banners: [ServiceHubBanner])`：Kingfisher 加载 `imageUrl`；多页自动轮播；可选点击走 `routePath`（与服务 Banner 映射一致）。

## Risks

- [运营未配置 `home_banner_code`] → 首页无 Banner，属预期空态
- [图比例与 375 稿 288 高不符] → 高度按实际图片宽高比计算；未加载前用 `288/375` 兜底，不再写死 288pt
