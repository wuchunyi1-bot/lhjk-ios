# Tasks: adapt-fundee-order-detail

## 1. Spec & BLL

- [x] 1.1 编写 `openspec/changes/adapt-fundee-order-detail` proposal / design / spec
- [x] 1.2 新增 `OrderDetailModels.swift`（`AppOrderDetailBO` + 明细行）
- [x] 1.3 `OrderService.getAppOrderDetail(orderId:)`

## 2. PL

- [x] 2.1 `OrderDetailViewModel` 拉取详情、格式化展示模型
- [x] 2.2 `OrderDetailComponents` 状态头 / 地址 / 套餐 / 明细 / 费用 / 信息 / 底栏
- [x] 2.3 `OrderDetailViewController` 布局与绑定
- [x] 2.4 `MyRoutes` 注册 `/orders/detail`

## 3. 验证

- [x] 3.1 待支付列表项仍进确认订单（逻辑未改）
- [x] 3.2 待发货及其它状态进详情并展示接口数据
- [ ] 3.3 手动将新增 Swift 文件加入 Xcode 工程
