# Design: 激活兑换对齐原型

## 对照

| 路由 | 原型 | iOS 本期 |
|------|------|----------|
| `/activate` | `ActivateView.vue` | Hub：标题「激活兑换」、权益卡服务说明、第一步绑定卡、第二步兑换卡 |
| `/activate/bind` | `BenefitCardBindView.vue` | 表单 + 规则 + 说明卡 + 成功态；API 真绑定 |
| `/activate/redeem` | `BenefitCardRedeemView.vue` | 机构信息 + 空态；套餐列表待「可兑换套餐」接口 |

## Hub

- 进入刷新待使用权益卡数（`getCustomerStatusCount` / 缓存）
- 绑定卡：橙主色视觉；整卡 → `/activate/bind`
- 兑换卡：信息蓝视觉；副文案有卡「当前有 N 张…」/ 无卡「暂无可用…」；整卡 → `/activate/redeem`
- 不展示购买权益卡；不显示 Tab Bar

## 绑定页

- 进入自动聚焦卡密；输入字母数字并格式化为 4 位一组（`-`）
- 立即绑定始终主色高亮；未勾选规则则抖动勾选区
- 同意规则：勾选 + 点《权益卡使用规则》打开说明（可走协议详情 `benefit-card`）
- `preCheckByKey` → `bindByKey`；失败保留输入，行内错误文案
- 成功：页内成功态；「去兑换套餐」`replace`→`/activate/redeem`；「查看我的权益卡」→`/me/vouchers`
- 扫码行：点击进入 `QRCodeScanViewController`（DAL `AVFoundation` 扫码，无第三方）；回填卡密后不自动绑定
- **不做**：原型专用演示扫码四场景 / 重新演示绑定

## 兑换页

- 标题「兑换套餐」；顶部展示当前选中机构名称/地址（`InstitutionSelectionStore`），无切换
- 无待使用卡：空态 +「绑定权益卡」
- 有卡：本期无「按卡可兑套餐」接口 → 空态「当前机构下暂无可兑换套餐。」（禁止 mock 套餐列表）
- 「立即兑换」入口统一进本页

## 路由

- 修正原 `/activate` → `VoucherListViewController` 错误映射
- 注册 `/activate`、`/activate/bind`、`/activate/redeem`
