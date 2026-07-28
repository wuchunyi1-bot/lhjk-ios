# Tasks: adapt-fundee-order-return-goods

## 1. Spec 锁定（本变更）

- [x] 1.1 proposal / design / specs：去退货资格与抽屉规则（对齐 PRD §3.3 / §3.5 / §5.7）
- [x] 1.2 对齐列表字段 `canReturnGoods` / `refundId` 与提交接口 `submitReturnGoods`

## 2. UI 骨架

- [x] 2.1 抽出 `canShowReturnGoods` 资格判断（列表/详情共用）
- [x] 2.2 `OrderCardCell`：合资格时展示「去退货」
- [ ] 2.3 `OrderDetailAfterSaleView`：合资格展示「去退货」入口；已提交后回显退货方式/物流（详情底部已用 action bar；回显可后续）
- [x] 2.4 去退货底部抽屉：自行送回 / 快递寄回 + 校验

## 3. 接口接入

- [x] 3.1 对齐提交文档字段（[submitReturnGoods](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/493050735e0.md)）
- [x] 3.2 BLL `submitReturnGoods` + 模型解码；提交成功刷新列表/详情
- [x] 3.3 物流名称：本期本地枚举（顺丰/京东/中通/圆通）
- [x] 3.4 更新 design「Open Questions」为已决议；同步主 `order-list` spec 字段表
