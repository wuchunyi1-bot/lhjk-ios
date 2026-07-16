## Context

参考：
- PRD：`funde-client/app端prd初稿/04_用户_我的地址_v1.0.md` §5.3（ADDR-EDIT-F005/F006/F008、ADDR-EDIT-M007）
- 原型：`prototype/src/views/me/AddressEditView.vue`（地区行 +「定位」按钮；原型用 mock 附近地址，iOS 用真实 GPS + 逆地理）
- 现有 iOS：`AddressEditViewController` 七字段手输 + `AddressService` 三接口已通

后端 `MAddress` / `AddressSavePayload` 仍为 `province` / `city` / `area` / `address` / `code` 字符串，无经纬度字段。定位结果经逆地理编码填入现有字段后走原保存接口。

## Decisions

### 1. DAL：`LocationManager`（原生库）

| 能力 | 实现 |
|------|------|
| 定位 | `CoreLocation` → `CLLocationManager.requestLocation()` 单次定位 |
| 逆地理 | `CLGeocoder.reverseGeocodeLocation` → `CLPlacemark` |
| 授权时机 | **仅**在用户点击「定位」且状态为 `notDetermined` 时调用 `requestWhenInUseAuthorization()`；进入编辑页不预请求 |
| 懒加载 | `CLLocationManager` 在首次定位请求时创建，避免无意义初始化 |

输出模型 `ReverseGeocodedAddress`：
- `province` ← `administrativeArea`
- `city` ← `locality`（直辖市等与省同名时用省名兜底）
- `area` ← `subLocality` / `district`
- `detail` ← `thoroughfare` + `subThoroughfare`（或 `name`）
- `postalCode` ← `postalCode`（可选写入 `code`）

错误映射用户文案：「定位失败，请手动选择」（对齐 ADDR-EDIT-M007）。

### 2. 地址编辑 UI

对齐 funde 分区：
1. **收货信息**：收货人、手机号、所在地区（只读展示 `省 市 区` +「定位」胶囊按钮）、详细地址（多行）、邮政编码（选填，API 保留）
2. **默认设置**：设为默认；首个地址强制默认且开关禁用

所在地区：
- 点击「定位」→ ViewModel 调 `LocationManager.locateAndReverseGeocode()` → 回填省市区与详址（详址有结果时覆盖/填充）
- 点击地区行本身 → 简易手动编辑（三字段输入弹层），因 PRD TBD-001 四级选择器数据源未定

### 3. ViewModel

`AddressEditViewModel`：表单状态、`isLocating`、校验、`save()`、`locate()`；注入 `AddressService` + `LocationManager`（默认 `AppContainer`）。

### 4. 不做范围

- 附近地址列表 / 地图选点 SDK
- 智能填写解析
- 四级联动地区 JSON
- 后端坐标字段

### 5. Info.plist（开发者手动）

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>用于获取当前位置并自动填写收货地址</string>
```

## Risks / Trade-offs

- Apple 逆地理在国内精度与字段完整性依赖系统；失败时依赖手动填写
- 无四级选择器时手动编辑体验弱于 funde PRD 目标态，待 TBD-001 补齐
