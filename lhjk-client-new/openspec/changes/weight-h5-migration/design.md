## Context

体重模块前端已独立为 H5 SPA（hash 路由）。App 侧改为 WebView 承载，原原生流程（录入 / 历史 / 详情 / 服务首页）全部下沉到 H5 内部处理。

## Decisions

### 1. 路由统一

`HealthRoutes` 中所有 `/health/metrics/weight*` 注册改为返回 `WebViewController(urlString: H5Config.weightPageURL, title: "体重")`。子路由不再区分，因 H5 自身管理内部 hash 路由。

### 2. H5 环境配置

```swift
enum H5Config {
    static var environment: H5Environment = .development
    static var weightPageURL: URL { environment.baseURL.appending("#/weight") }
}
```

base URL 按环境切换：
- development: `http://192.168.15.249:5181`
- staging / production: 待定正式域名

### 3. 原生代码保留

`WeightService`、`WeightViewController`、`WeightManualViewController`、`WeightHistoryViewController`、`WeightDetailViewController`、`WeightServiceViewController` 及对应 ViewModel **暂不删除**，便于回退或后续复用 BLL。仅断开路由引用。

### 4. Info.plist ATS（开发者手动）

H5 dev 地址为 HTTP + IP（`192.168.15.249`），ATS 的 `NSExceptionDomains` 不支持 IP 字面量，需要全局放开或临时添加。建议 dev 环境在 `NSAppTransportSecurity` 下添加：

```xml
<key>NSAllowsArbitraryLoads</key>
<true/>
```

> 上线前移除，改为 HTTPS 正式域名。AI 不修改 Info.plist，由开发者执行。

## Risks / Trade-offs

- HTTP dev 地址需 ATS 放开；正式环境应用 HTTPS
- Token / 登录态如何注入 H5（cookie 或 URL 参数）暂未实现，待 H5 联调确认
