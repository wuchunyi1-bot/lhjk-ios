## Context

首页 Banner 已走：

`GET /v1/columnContent/getByCode?code=home_banner_code` → `ColumnContentCacheService` → `HomeViewModel` → 远程图；空则隐藏 section。

金刚区仍为：

`HomeViewModel.defaultQuickActions`（SF Symbol + 硬编码 route）。运营 code：`home_quickLink_code`。

## Goals / Non-Goals

**Goals:**

- 金刚区：`code=home_quickLink_code`，路径与过滤规则对齐 Banner（`status` 可展示；有名称或图标）
- 复用 `ColumnContentCacheService`（含冷启动预拉、in-flight 去重、登出 clear、无 TTL）
- 复用 DTO → `ServiceHubBanner`（或同构映射），再转为金刚区 UI 模型
- 接 API 后删除本地 mock 快捷项

**Non-Goals:**

- 不改 Banner / 服务 Hub `mall_advertisement`
- 不新增独立 path（仍为 getByCode）
- 不强制改金刚区卡片视觉结构（白卡 + 圆形图标底），仅图标改为远程图为主

## Decisions

### 1. Code 常量

```swift
static let homeQuickLinkCode = "home_quickLink_code"
```

与后端一字不差（注意 `quickLink` 驼峰拼写）。

### 2. 缓存与拉取

- `knownPreloadCodes` 增加 `home_quickLink_code`
- Home：`await columnContentCache.banners(for: homeQuickLinkCode)`（与 Banner 同 API 面；缓存层仍存 `[ServiceHubBanner]`）
- 不必新建 Cache Service

### 3. UI 映射

| 字段 | 用途 |
|------|------|
| `name` | 标题 |
| `imageUrl` | 金刚区图标（Kingfisher） |
| `contentType` + `contentId` | 跳转：沿用 `ColumnContentMapper.resolveRoute`；无路由则点击无跳转或仅展示 |

样式色值可继续用 Design Token / 现有暖橙底（`#FFF3EE` + `.fdPrimary`），不必从接口读色。

### 4. Cell

`HomeQuickActionsCell.Action` 增加远程图标能力（`imageUrl`）；有 URL 用 Kingfisher，无 URL 可不展示图标或整项过滤。禁止用写死 SF Symbol 列表顶替接口数据。

### 5. 空态

过滤后列表为空或请求失败 → snapshot **去掉** `.quickActions` section（对齐 Banner），禁止 `defaultQuickActions` 回填。

### 6. 清单

`docs/api-inventory.md` `#36` 备注补上 `home_quickLink_code`。

## Risks / Trade-offs

- [运营未配该 code / 无图] → 金刚区隐藏，属预期
- [跳转类型与现硬编码 `/messages` 等不一致] → 以接口 `contentType/contentId` 映射为准；缺映射时点击可 no-op，需与运营约定配置
- [缓存模型叫 Banner] → 实现层复用结构，语义上是「栏位条目」；不为本期重命名类型

## Migration Plan

1. OpenSpec 产物（本 change）
2. 常量 + 预拉 code + Home 拉取/映射 + Cell 远程图 + 删 mock + inventory
3. 首页冒烟：有配置展示、无配置隐藏、冷启动只打一次网

## Open Questions

- 若后端金刚区跳转不是现有 `contentType` 枚举，而把原生 path 放在其它字段，实现前需对照一次真实响应再微调 Mapper（spec 以现有 Mapper 为默认）。
