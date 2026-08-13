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
- 不强制改首页 Banner 高度/全宽视觉（保持现有 288pt 全宽样式）
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
- [图比例与 288 高度不符] → `scaleAspectFill` 裁剪，与现本地图策略一致
