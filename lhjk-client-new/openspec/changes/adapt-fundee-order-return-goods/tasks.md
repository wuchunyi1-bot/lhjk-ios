# Tasks: adapt-fundee-order-return-goods

## 1. Spec 锁定（本变更）

- [x] 1.1 proposal / design / specs：去退货资格与抽屉规则（对齐 PRD §3.3 / §3.5 / §5.7）
- [x] 1.2 明确接口未出：禁止自造提交参数

## 2. UI 骨架（可先做，无网或按钮隐藏）

- [ ] 2.1 抽出 `canShowReturnGoods` 资格判断（列表/详情共用；履约状态枚举占位 + TODO 对齐文档）
- [ ] 2.2 `OrderCardCell`：`status=6` 合资格时展示「去退货」
- [ ] 2.3 `OrderDetailAfterSaleView`：合资格展示「去退货」入口；已提交后回显退货方式/物流
- [ ] 2.4 新增去退货底部抽屉：自行送回 / 快递寄回 + 校验文案（对齐 funde `OrderReturnDialog`）

## 3. 接口接入（Apifox 发布后）

- [ ] 3.1 粘贴/对齐提交与回显接口文档字段（**禁止臆造**）
- [ ] 3.2 BLL Service + 模型解码；提交成功刷新列表/详情
- [ ] 3.3 物流名称数据源（字典或文档枚举）接入
- [ ] 3.4 更新本 change design「Open Questions」为已决议，并 sync 主 spec
