## 1. Spec & Models

- [x] 1.1 OpenSpec change `adapt-fundee-order-renewal`
- [x] 1.2 `PackageHospitalDetailBO.reprice`；订单 BO 补 `packageId` / `hospitalId`

## 2. 套餐详情续费态

- [x] 2.1 路由与 VC/VM 传 `renewalParentOrderId`
- [x] 2.2 Mapper 续费价、`parentId` 提交、底栏文案

## 3. 订单入口

- [x] 3.1 列表/详情「续费订单」跳转续费套餐页
- [x] 3.2 「续费订单」仅 `packageType == 1`（租赁套餐）展示
