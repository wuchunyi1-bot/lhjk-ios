# Location / 定位与逆地理编码

## Purpose

DAL 层封装 iOS 原生定位与逆地理编码（`CoreLocation` + `CLGeocoder`），供地址编辑等业务按需调用。不引入第三方地图 SDK。

## Requirements

### Requirement: On-Demand Authorization

系统 SHALL 仅在用户主动触发定位时请求「使用期间」定位授权。

#### Scenario: 首次点击定位
- **WHEN** 用户触发定位且授权为 `notDetermined`
- **THEN** 弹出系统 WhenInUse 授权框

#### Scenario: 进入业务页未定位
- **WHEN** 进入地址编辑页但未点「定位」
- **THEN** 不请求授权、不启动定位

### Requirement: One-Shot Locate And Reverse Geocode

系统 SHALL 提供 `locateAndReverseGeocode()`，返回 `ReverseGeocodedAddress`（province / city / area / detail / postalCode）。

#### Scenario: 失败提示
- **WHEN** 拒绝授权、定位失败或逆地理失败
- **THEN** 错误文案为「定位失败，请手动选择」
