## Why

funde-client 地址编辑页（PRD `04_用户_我的地址_v1.0` + `AddressEditView.vue`）在「所在地区」行提供「定位」能力：用户主动点击后获取当前位置并回填地区/详址。iOS 现有编辑页仅为省/市/区手输字段，无定位与逆地理编码，录入成本高。需对齐该交互，且地址保存接口不变。

## What Changes

- DAL 新增原生 `LocationManager`（CoreLocation + CLGeocoder）：按需请求定位授权、单次定位、逆地理编码解析为省/市/区/详址
- 地址编辑页对齐 funde：收货人、手机号、所在地区（展示行 +「定位」按钮）、详细地址、设为默认；文案与校验对齐 PRD
- 抽出 `AddressEditViewModel`，定位与保存逻辑下沉 ViewModel
- **不改** `saveOrUpdateAddress` / `getAddressList` / `deleteAddressById` 接口与 `AddressSavePayload` 字段
- 智能填写、省市区街道四级选择器数据源（PRD TBD）本期不做
- Info.plist 需开发者手动补充 `NSLocationWhenInUseUsageDescription`

## Capabilities

### New Capabilities

- `location`: 按需定位授权、单次定位、逆地理编码封装

### Modified Capabilities

- `shipping-address`: 地址编辑页支持定位回填；表单交互对齐 funde PRD

## Impact

- `DAL/Location/LocationManager.swift`（新增）
- `DAL/AppContainer.swift`
- `PL/My/Address/AddressEditViewController.swift`
- `PL/My/Address/ViewModels/AddressEditViewModel.swift`（新增）
- `openspec/specs/shipping-address/spec.md`（本变更归档后同步）
- `Info.plist`（开发者手动）
