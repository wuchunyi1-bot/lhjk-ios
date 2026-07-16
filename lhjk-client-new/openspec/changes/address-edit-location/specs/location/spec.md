# Location / 定位与逆地理编码

## Purpose

在 DAL 层封装 iOS 原生定位与逆地理编码，供地址编辑等业务按需调用。不引入第三方地图 SDK。

## Requirements

### Requirement: On-Demand Authorization

系统 SHALL 仅在用户主动触发定位时请求「使用期间」定位授权，不得在进入业务页时预弹授权框。

#### Scenario: 首次点击定位
- **WHEN** 用户点击「定位」且授权状态为 `notDetermined`
- **THEN** 调用 `requestWhenInUseAuthorization()`，由系统弹出授权对话框

#### Scenario: 进入编辑页
- **WHEN** 用户进入收货地址编辑页但未点击「定位」
- **THEN** 不请求定位授权、不启动定位

#### Scenario: 已拒绝授权
- **WHEN** 授权状态为 `denied` / `restricted` 且用户点击「定位」
- **THEN** 抛出可映射为「定位失败，请手动选择」的错误，不重复弹系统框

---

### Requirement: One-Shot Locate And Reverse Geocode

系统 SHALL 提供单次定位并逆地理编码的异步 API。

#### Scenario: 定位成功并解析
- **WHEN** 已授权且定位成功
- **THEN** 使用 `CLGeocoder` 逆地理编码，返回 `ReverseGeocodedAddress`（至少包含可用的省份或城市信息）

#### Scenario: 字段映射
- **WHEN** 收到 `CLPlacemark`
- **THEN** `province` ← `administrativeArea`；`city` ← `locality`（空则回退 `administrativeArea`）；`area` ← `subLocality`；`detail` ← 街道相关字段拼接；`postalCode` ← `postalCode`

#### Scenario: 定位或逆地理失败
- **WHEN** 定位超时、服务关闭或逆地理失败
- **THEN** 抛出错误，由 PL 提示「定位失败，请手动选择」

---

### Requirement: Native Stack Only

系统 SHALL 使用 `CoreLocation` + `CLGeocoder` 实现，不依赖第三方地图 Pod。

#### Scenario: 依赖边界
- **WHEN** 工程集成定位能力
- **THEN** 无需修改 Podfile；仅需 Info.plist 配置 `NSLocationWhenInUseUsageDescription`
