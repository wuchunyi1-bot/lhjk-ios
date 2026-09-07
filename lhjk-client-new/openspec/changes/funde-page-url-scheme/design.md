## Context

运营在 CMS / 栏位配置里写入 `pageUrl`，常见形态：

- `FundeH5:/blood-pressure`
- `FundeH5:/monitoring-plan`
- `FundeApp:/messages`
- `FundeApp:/services/pkg?id=xxx`

来源接口：`GET /v1/columnContent/getByCode`、`GET /v1/healthPage/getCmsConfig`。

## Goals / Non-Goals

**Goals:**

- 统一前缀解析规则并文档化
- 公共方法：parse + open（H5 鉴权 WebView / Router.push）
- Home getByCode、Health CMS 点击接入

**Non-Goals:**

- 不改 Apifox
- 不发明第三种前缀；无前缀则 no-op
- 体征卡：`FundeH5:` / 已注册 `FundeApp:` 走 `FundePageURL`；否则 `cardType` 兜底；快捷入口 / getByCode 使用 pageUrl

## Decisions

### 1. 前缀（大小写敏感）

| 前缀 | 含义 | 后缀处理 |
|------|------|----------|
| `FundeH5:` | H5 路由 | 去掉前缀后规范化为 H5 path，经 `H5Config.authenticatedPageURL` 打开 `WebViewController` |
| `FundeApp:` | 本地路由 | 去掉前缀后解析 path + query，经 `Router.push` |

### 2. 后缀规范化

- trim 空白
- H5：去掉可选的 `#/` 或前导 `/`，再交给 `H5Config`；若含 `?`，query 进 `extraQuery`
- App：保证 path 以 `/` 开头；`?` 后拆为 params

### 3. API 落点

```swift
enum FundePageURL {
  enum Destination { case h5(path:query:), case app(path:params:), case none }
  static func parse(_ pageUrl: String?) -> Destination
  static func open(_ pageUrl: String?, title: String? = nil, from: UIViewController? = nil)
}
```

### 4. 调用方

凡 CMS / IM 下发的 `pageUrl` / `urlKey` 均走同一套规则（`FundeH5:` 一律开 H5，`FundeApp:` 仅已注册本地路由）：

- Home：Banner / 金刚区 / 推荐套餐 → `FundePageURL.open`；**健康陪伴除外**（走 `#/content/detail?id=`）
- Service：运营 Banner 优先 `FundePageURL.open`；无前缀或 `FundeApp` 未注册时再按 `contentType` 本地 `routePath`
- Health **快捷入口**（`getCmsConfig.quickEntryList`）：`FundePageURL.open(pageUrl)`；无前缀且以 `/` 开头则 `Router.push`
- Health **体征卡**：合法 `pageUrl` 走 `FundePageURL.open`；否则 `cardType` → `/health/metrics/{key}`
- IM 会话卡片 / 通知中心：`FundeH5:` → `FundePageURL.open`；`FundeApp:` / `/path` 走通知中心别名后再 `Router.push`

## Risks

- [历史仅写无前缀的 pageUrl] → 快捷入口 no-op；体征卡不受影响（不走 pageUrl）
- [H5 path 与宿主路由不一致] → 白屏；由运营配置与 H5 对齐

## Open Questions

无。
