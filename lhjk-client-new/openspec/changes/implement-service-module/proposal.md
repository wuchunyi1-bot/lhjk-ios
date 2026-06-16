## Why

当前 iOS `ServiceViewController` 仅有一个 "服务" label + 测试支付按钮，是纯占位页。funde-client 服务模块包含完整的 Hub 页 + 套餐列表 + 详情 + 商城，共 6 个 Vue 页面 + 12 个套餐数据 + 9 个产品矩阵 + 9 个商城商品。

需要将服务模块完整适配到 iOS。

## What Changes

### Phase 1: Hub 页（本次 spec 重点）
- `ServicesHubViewController`: 重写 `ServiceViewController`
  - tableHeaderView: 自定义 Topbar
  - Section 0: Featured package cards (2 rows)
  - Section 1: Medical assist card (1 row)
  - Section 2: Product matrix (3×3 grid, 1 row)
  - Section 3: 富德优选 mall grid (2×N grid, 1 row, 最多展示 6 个)
- 数据模型 `ServiceModels.swift`

### Phase 2: 子页面 (Deferred)
- `ServiceListViewController`: 左分类导航 + 右套餐列表
- `ServiceDetailViewController`: banner + 权益 + 适用人群 + 详情 + 特性 + 评价 + 承诺 + 底部固定栏
- `HealthMallViewController`: 分类 Tab + 商品 2 列 grid
- Detail pages: placeholder

## Impact
- **PL/Service/**: 重写 ServiceViewController → ServicesHubViewController，新增 Cells
- **BLL/Service/**: 更新路由注册
- **DAL/**: 新增 ServiceModels
