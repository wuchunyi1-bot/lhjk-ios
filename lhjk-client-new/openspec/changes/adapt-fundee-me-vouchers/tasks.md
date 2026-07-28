## 1. Models & Service

- [x] 1.1 重写 `VoucherModels`：权益卡 / 转赠记录 / 卡包优惠券状态与展示文案
- [x] 1.2 重写 `VoucherService` Mock（对齐 funde seed）及可用数量统计
- [x] 1.3 抽出按状态筛选/排序 Helper，供各 Tab VC 复用（`VoucherListQuery`）

## 2. Order 式页面拆分

- [x] 2.1 Hub：`VoucherListViewController` 仅切换权益卡 / 优惠券子模块
- [x] 2.2 `BenefitListViewController` + `BenefitTabViewController`（每状态独立 TableView）
- [x] 2.3 `CouponListViewController` + `CouponTabViewController`（每状态独立 TableView）
- [x] 2.4 移除单 TableView 筛选实现；Cells 复用

## 3. 我的入口

- [x] 3.1 「我的卡券」角标接 `VoucherService` 可用数
