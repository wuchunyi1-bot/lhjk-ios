## Context

对齐 funde PRD `05_用户_我的订单_v1.0.md` §3.3 / §3.5 / §5.7，并已对接 Apifox：

- 申请阶段只采「申请退款原因」，**不**展示退货方式/物流
- 审核通过 → 订单主状态进入「退款/售后」（App `status=6`）
- 列表下发 `canReturnGoods` + `refundId` → 合资格展示「去退货」
- 用户选自行送回或快递寄回；快递寄回必填物流名称 + 物流单号
- 提交：`POST /v1/orderClearing/submitReturnGoods`
- 提交成功后刷新；服务端将 `canReturnGoods` 置为不可展示则入口消失

## Goals / Non-Goals

**Goals:**

- 以服务端 `canReturnGoods` / `refundId` 为列表资格权威来源
- 抽屉提交真实接口，禁止 mock 假 id
- 列表与详情共用同一资格与提交流程

**Non-Goals:**

- 不实现后台审核、金额核算、正向物流轨迹
- 不在待收货 / 使用中 / 已完成等**申请入口**状态展示「去退货」
- 本期抽屉不采集寄件人姓名/电话（接口字段可选）

## Decisions

1. **展示条件**  
   `status == 6` **且** `canReturnGoods == true` **且** `refundId > 0`。  
   详情若暂无 `canReturnGoods`：兼容为 `status == 6` + `refundId > 0`。

2. **提交 Body 映射**（[文档](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/493050735e0.md)）  

   | UI | API |
   |----|-----|
   | 退款单 | `refundId`（来自列表/详情，非订单 id） |
   | 自行送回 | `returnMethod = 1` |
   | 快递寄回 | `returnMethod = 2` + `logisticsName` + `logisticsId` |

3. **入口位置**  
   退款/售后 Tab / 全部 Tab 合资格卡片；详情底部操作区。

4. **与申请抽屉分离**  
   申请抽屉禁止退货字段；去退货仅审核通过后出现。

5. **物流名称**  
   本期沿用本地常用物流枚举（与现有抽屉一致）；后续可换字典接口。

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| 列表有 `canReturnGoods`、详情暂无 | 详情用 `refundId` 兼容；两边都解码 `canReturnGoods` |
| 用户误把订单 id 当 refundId | BLL 只接受传入的 `refundId`；无值则不展示入口 |
| 提交成功但列表未刷新 | 成功后 `orderListNeedsRefresh` + 详情 `load()` |

## Open Questions

1. ~~提交退货 API~~ — 已决议：`POST /v1/orderClearing/submitReturnGoods`
2. ~~列表是否下发可退货标志~~ — 已决议：`canReturnGoods` + `refundId`
3. 物流名称字典 vs 本地枚举 — 本期本地枚举，后续可换
4. `sender` / `senderPhone` 是否产品强制 — 本期不采集（接口可选）
