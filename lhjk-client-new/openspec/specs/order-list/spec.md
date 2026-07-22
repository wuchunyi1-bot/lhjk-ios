# 订单列表 (Order List)

## Purpose

分页查询用户订单列表，支持按状态 Tab 筛选，展示订单卡片信息。对接后端 `GET /v1/order/getAppOrderList` 接口。

## API Reference

| 接口 | 方法 | 路径 |
|------|------|------|
| 分页查询订单列表 | `GET` | `/v1/order/getAppOrderList` |

### Request Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `pageNum` | String | 否 | 当前页，默认 "1" |
| `pageSize` | String | 否 | 每页条数，默认 "10" |
| `status` | String | 否 | 单个订单状态筛选 |
| `statusList` | String | 否 | 多状态筛选（逗号分隔），如 "2,3" |
| `source` | String | 否 | 来源：1=web, 2=app |

### Order Status

| 值 | 说明 | UI 徽章文案 |
|----|------|-------------|
| 1 | 待支付 | 待支付 |
| 2 | 待发货 | 待发货 |
| 3 | 待收货 | 待收货 |
| 4 | 使用中 | 使用中 |
| 5 | 已完成 | 已完成 |
| 6 | 退款/售后 | 退款/售后 |
| 7 | 已逾期 | 已逾期 |
| 8 | 已取消 | 已取消（仅「全部」可见） |
| 9 | 退款审核中 | 退款审核中（并入「退款/售后」Tab） |

### UI Tab → API 筛选（对齐 funde 8 Tab）

| Tab | API 参数 |
|-----|---------|
| 全部 | 不传 status |
| 待支付 | `status=1` |
| 待发货 | `status=2` |
| 待收货 | `status=3` |
| 使用中 | `status=4` |
| 已逾期 | `status=7` |
| 退款/售后 | `statusList=6,9` |
| 已完成 | `status=5` |

Tab 使用 UICollectionView 横向滚动；**恰好 8 个**，顺序同表。

### Response Data Model: AppOrderListBO

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | Int64 | 订单 ID |
| `orderName` | String | 订单产品名称 |
| `status` | Int | 订单状态（1-9） |
| `payable` | Double | 应付金额 |
| `price` | Double | 实付金额 |
| `createTime` | String | 创建时间 |
| `hospitalName` | String | 医院名称 |
| `doctorName` | String | 医生姓名 |
| `packageDescription` | String | 套餐描述 |
| `packageType` | Int | 套餐类型：1=租赁 2=售卖 3=虚拟 4=体验 |
| `packageImageUrl` | String | 套餐图片 |
| `beginTime` | String | 服务开始时间 |
| `endTime` | String | 服务结束时间 |
| `serviceTime` | String | 服务时间 |

### Paginated Response

后端分页字段名（非驼峰）需 `CodingKeys` 映射：

| API 字段 | 模型属性 |
|---------|---------|
| `totalCount` | `totalRecords` |
| `pageSize` | `pageSize` |
| `totalPage` | `totalPages` |
| `currPage` | `currentPage` |
| `list` | `records` |

## Requirements

### Requirement: 订单列表展示
系统 SHALL 分页展示当前用户的订单列表。

#### Scenario: 进入订单页面
- **WHEN** 用户从"我的"页面点击"全部订单"
- **THEN** 加载第一页订单数据，默认显示"全部"Tab

#### Scenario: Tab 筛选
- **WHEN** 用户切换 Tab
- **THEN** 显示对应 Tab 的子 VC；子 VC 仅在首次加载或数据更新时请求网络，切换回已加载的 Tab 不重复请求

---

### Requirement: 订单状态展示
系统 SHALL 根据订单状态显示不同的标签样式。

#### Scenario: 状态标签
- **WHEN** 订单列表加载完成
- **THEN** 每个订单卡片显示对应状态的彩色标签

---

### Requirement: 空状态
系统 SHALL 在无订单时展示空状态。

#### Scenario: 当前 Tab 无订单
- **WHEN** 当前 Tab 下无订单数据
- **THEN** 展示空状态图标与该 Tab 对应文案（退款/售后「暂无退款/售后记录」等；详见 `adapt-fundee-order-list`）

## UI Architecture

采用 **容器 VC + 子 VC** 模式：

```
OrderListViewController (容器)
├── UICollectionView (横向 8 Tab)
├── OrderTabViewController (子VC × 8)
│   ├── UITableView + OrderCardCell（机构/封面/卖点/金额/操作）
│   ├── emptyView
│   └── loadingIndicator
└── containerView
```

### 数据缓存策略
- 每个 `OrderTabViewController` 持有独立的 `orders: [MOrder]` 和 `hasLoaded` 标志
- 首次显示时请求 API，之后切换回该 Tab 直接使用缓存数据
- 提供 `refresh()` 方法供外部触发刷新（如订单状态变更后）

## File Structure

```
BLL/Service/
├── OrderModels.swift             # MOrder 模型 + AppOrderStatus + PaginatedOrderData
└── OrderService.swift            # 订单服务（API 调用）

PL/My/Order/
├── OrderListViewController.swift # 容器 VC（8 Tab + 子VC 管理）
├── OrderTabViewController.swift  # 子 VC（单个 Tab 的 TableView + 数据加载）
└── Cells/
    ├── OrderTabCell.swift
    └── OrderCardCell.swift       # 对齐 funde OrderListCard

openspec/specs/order-list/
└── spec.md                       # 本文档

openspec/changes/adapt-fundee-order-list/
└── specs/order-list/spec.md      # funde 对齐 delta
```
