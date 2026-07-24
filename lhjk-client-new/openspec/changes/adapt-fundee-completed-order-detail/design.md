# Design: 已完成订单详情 UI

## 页面结构（对齐 funde PaidOrderDetailView）

```
┌─────────────────────────────────────────┐
│ 导航栏 · 订单详情                        │
├─────────────────────────────────────────┤
│ [状态卡] 已完成 + 图标                   │
│ [提示条] 订单已完成，感谢您的信任          │
├─────────────────────────────────────────┤
│ [退款/售后信息] 条件展示                  │
├─────────────────────────────────────────┤
│ [套餐卡] 封面 + 机构 + 名称 + 卖点        │
│ [商品明细] 条件展示                      │
├─────────────────────────────────────────┤
│ [收货地址] 快递订单 + 有地址时            │
│ [物流信息] 快递 + 有商品行时              │
│ [自提信息] 自提 + 有商品行时              │
│ [服务机构/自提地址] 自提或服务类订单       │
├─────────────────────────────────────────┤
│ [费用明细]                               │
│ [订单信息]                               │
└─────────────────────────────────────────┘
```

## 区块可见性

| 区块 | 条件 |
|------|------|
| 收货地址 | `typeOrder == 1` 且 `receiver/phone/address` 任一非空 |
| 物流信息（快递） | `typeOrder == 1` 且 `detailLines` 非空 |
| 自提信息 | `typeOrder == 0` 且 `detailLines` 非空 |
| 服务机构 | `typeOrder == 0`（自提） |
| 退款/售后信息 | `showsAfterSaleInfoCard`（沿用现有规则） |

## 物流信息行（OrderLogisticsInfoSection 映射）

数据源：`shoppingCartPackageDetailList` → `OrderDetailPackageLineBO`

| API 字段 | 展示 |
|----------|------|
| `commodityName` / `packageName` | 商品标题 |
| `shipmentStatus` `1` | 状态徽章「待发货」（warning 色） |
| `shipmentStatus` `2` | 状态徽章「已发货」（info 色） |
| `presetDeliveryTime` | 待发货副文案：`商家备货中，预计发货时间 {time}` |
| 订单级 `logisticsChineseName` + `logisticsNumber` | 已发货副文案 + 复制按钮 |

自提副文案（`typeOrder == 0` 且待发货）：`预计 {presetDeliveryTime} 完成备货，可自提`

## 收货地址 / 服务机构

**收货地址**（对齐 funde address-row）：
- 左侧 location 图标（info-soft 底）
- 姓名 + 手机（`fdBody` semibold）
- 详细地址（`fdCaption` subtext）

**服务机构**（对齐 funde institution-card）：
- 标题：自提 →「自提地址」；否则「服务机构」
- 机构名 + building 图标
- 地址文案
- 全宽「联系机构」按钮（image + 文字居中）

## 退款/售后信息

对齐 `OrderAfterSaleInfoCard.vue`：
- 标题「退款/售后信息」在卡片内
- 行样式与订单信息一致：`fdBody`、行高 40pt
- 退款金额：`fdDangerSoft` 底 + `fdDanger` 金额 `fdNumM`

## 技术决策

- 物流仅统计 `shipmentStatus != nil` 的商品行；详情预览 1 条 + 发货记录入口
- 发货记录子页路由 `/orders/shipment-records`
- 联系机构：有 `phone` 时 `tel:`，否则 Toast
- `OrderDetailFulfillmentView` 保留文件但详情页不再使用，避免影响其他引用
