## 1. Spec

- [x] 1.1 编写 proposal / design / location + shipping-address delta specs

## 2. DAL 定位

- [x] 2.1 新增 `DAL/Location/LocationManager.swift`（授权状态、按需授权、单次定位、逆地理）
- [x] 2.2 `AppContainer` 注册 `locationManager`
- [ ] 2.3 提示开发者补充 Info.plist `NSLocationWhenInUseUsageDescription`

## 3. 地址编辑 PL

- [x] 3.1 新增 `AddressEditViewModel`（表单、定位、校验、保存）
- [x] 3.2 重构 `AddressEditViewController`：地区行 + 定位按钮 + 详址多行 + 默认规则
- [x] 3.3 地区行点击 → 手动编辑省市区弹层

## 4. 验证

- [ ] 4.1 未点定位不弹授权
- [ ] 4.2 定位成功回填省市区（及详址）
- [ ] 4.3 拒绝定位后 Toast「定位失败，请手动选择」
- [ ] 4.4 保存仍走原 `saveOrUpdateAddress` 接口
