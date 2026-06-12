# Image Loading

## Purpose

提供统一的图片加载和缓存能力，基于 Kingfisher 封装，支持网络图片加载、本地缓存、占位图、图片处理和下载进度。

## Requirements

### Requirement: Image Loading & Caching
系统 SHALL 在 DAL 层基于 Kingfisher 提供统一的图片加载能力，支持 UIImageView 和 UIButton 的图片加载扩展。

#### Scenario: 加载网络图片
- **WHEN** PL 层需要展示网络图片（如用户头像、聊天图片、商品图片）
- **THEN** 使用 `UIImageView.kf.setImage(with: URL)` 加载图片，Kingfisher 自动处理下载、缓存和显示

#### Scenario: 占位图
- **WHEN** 网络图片加载中或加载失败
- **THEN** 显示预定义的占位图（placeholder），加载成功后自动替换为目标图片

#### Scenario: 图片缓存
- **WHEN** 图片首次加载成功后
- **THEN** Kingfisher 自动将图片缓存到磁盘和内存中，下次加载相同 URL 时直接从缓存读取，无需重复下载

#### Scenario: 图片下载进度
- **WHEN** PL 层需要展示大图的下载进度
- **THEN** Kingfisher 提供下载进度回调，PL 层可展示进度条或百分比

#### Scenario: 图片预处理
- **WHEN** 图片需要在展示前进行缩放、裁剪或圆角处理
- **THEN** 使用 Kingfisher 的 `processor` 参数（如 `DownsamplingImageProcessor`、`RoundCornerImageProcessor`），在后台线程预处理后再显示

#### Scenario: 缓存管理
- **WHEN** 需要清理图片缓存（如用户登出或存储空间不足）
- **THEN** 调用 `KingfisherManager.shared.cache.clearDiskCache()` 清理磁盘缓存，`clearMemoryCache()` 清理内存缓存

---

### Requirement: Image Configuration
系统 SHALL 提供全局的 Kingfisher 默认配置。

#### Scenario: 全局配置
- **WHEN** 应用启动时
- **THEN** `ImageLoadingConfig` 配置 Kingfisher 的全局默认值：磁盘缓存大小上限（默认 500MB）、内存缓存上限（默认 100MB）、默认占位图、请求超时时间
