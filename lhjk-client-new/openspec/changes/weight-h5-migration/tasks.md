## 1. Spec

- [x] 1.1 创建 `weight-h5-migration` proposal / design / spec

## 2. BLL / 路由

- [x] 2.1 新增 `H5Config` / `H5Environment`
- [x] 2.2 `HealthRoutes` 体重路由全部改为 `WebViewController`
- [x] 2.3 `/health/metrics/add?key=weight` 改为 H5

## 3. 配置（开发者手动）

- [ ] 3.1 Info.plist 放开 dev IP HTTP（`NSAllowsArbitraryLoads` 或正式 HTTPS）
- [ ] 3.2 新增 `Other/Common/H5Config.swift` 加入 Xcode 工程

## 4. 验证

- [ ] 4.1 健康页点击「体重」卡片打开 H5
- [ ] 4.2 H5 `#/weight` 正常加载
