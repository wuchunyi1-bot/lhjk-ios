## 1. 列表 id

- [x] 1.1 `HospitalPackagePageVO` 解析 `id`；`HospitalPackageMapper` 写入 `HealthPackageItem.id`

## 2. 详情 API

- [x] 2.1 DTO + Mapper：`getPackageDetail` → `ServicePackageDetail`
- [x] 2.2 `HospitalPackageService.fetchPackageDetail`；临时 `hospitalId`
- [x] 2.3 ViewModel + VC 异步加载；轮播支持图片 URL

## 3. Spec

- [x] 3.1 更新 `service-package-detail` spec：三段式布局、连续楼层、吸顶 Tab

## 4. 布局修复（对齐 funde HealthPackageDetailView）

- [x] 4.1 TableView 三段式：Banner / 简介卡 / 权益+详情卡
- [x] 4.2 权益与详情连续展示，Tab 仅用于滚动定位与吸顶
- [x] 4.3 组合组隐藏组名与 icon；修复单选默认可选逻辑
- [x] 4.4 应付金额 = 已选商品单价之和；参考价固定不变

## 5. checkType 与子项

- [x] 5.1 Spec：必选锁定 / 单选 radio / 多选 checkbox / 子项缩进
- [x] 5.2 Mapper 保留父行+children，写入 `isChild`
- [x] 5.3 ComboGroupView 按图示渲染控件与子项缩进

## 6. 角标文案与 Tab 定位

- [x] 6.1 分组头强制展示「必选 / 单选 / 可选」
- [x] 6.2 修复 Tab 楼层定位：去掉重复 sticky 扣减，计入 cell inset + 浮动 Tab 高度，动画后二次校正
