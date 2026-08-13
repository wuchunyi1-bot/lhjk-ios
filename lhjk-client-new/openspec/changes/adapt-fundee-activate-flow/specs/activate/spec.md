## ADDED Requirements

### Requirement: 激活兑换 Hub

`/activate` SHALL 对齐 funde `ActivateView` / `activate.page.yaml`，作为首页「激活兑换」落地页。

#### Scenario: 结构与入口

- **WHEN** 用户进入 `/activate`
- **THEN** 导航标题为「激活兑换」，不展示 Tab Bar
- **AND** 展示「权益卡服务」标题与说明「先绑定企业发放的权益卡，再兑换健康服务套餐。」
- **AND** 按序展示两张操作卡：第一步「绑定权益卡」、第二步「兑换健康服务套餐」
- **AND** 绑定卡跳转 `/activate/bind`；兑换卡跳转 `/activate/redeem`
- **AND** **不得**再进入「我的卡券」列表作为该路由落地页
- **AND** **不得**展示购买权益卡入口

#### Scenario: 待使用数量

- **WHEN** Hub 展示兑换卡
- **THEN** 副文案在有待使用卡时为「当前有 N 张权益卡可用」，否则「暂无可用权益卡，先去绑定」
- **AND** N 仅统计本人待使用、未转赠锁定的权益卡（`getCustomerStatusCount` value=3 / 等价缓存）

### Requirement: 绑定权益卡页

`/activate/bind` SHALL 对齐 funde `BenefitCardBindView`（正式能力，不含原型演示专用入口）。

#### Scenario: 表单

- **WHEN** 用户进入绑定页（含卡包「去绑定」）
- **THEN** 标题「绑定权益卡」；展示卡密输入、扫码行、立即绑定、规则勾选、绑定/使用说明合并卡片
- **AND** 未同意规则点立即绑定不提交并抖动规则区
- **AND** 绑定调用 `preCheckByKey` → `bindByKey`；成功进入页内成功态

#### Scenario: 扫码绑定

- **WHEN** 用户点击「扫码绑定」
- **THEN** 进入扫描二维码页（DAL `QRCodeScanner` / `QRCodeScanViewController`，系统 AVFoundation）
- **AND** 识别成功后回填卡密并返回绑定页，**不**自动调用绑定接口
- **AND** 未授予相机权限时提示并关闭扫码页

#### Scenario: 成功出口

- **WHEN** 绑定成功
- **THEN** 提供「去兑换套餐」（`/activate/redeem`）与「查看我的权益卡」（`/me/vouchers`）

### Requirement: 兑换套餐专区

`/activate/redeem` SHALL 对齐 funde `BenefitCardRedeemView` 的机构头与空态规则；可兑套餐列表待后端适用范围接口。

#### Scenario: 无卡 / 有卡暂无列表

- **WHEN** 无待使用权益卡
- **THEN** 空态引导绑定并跳转 `/activate/bind`
- **WHEN** 有待使用卡但尚无可用套餐数据源
- **THEN** 展示「当前机构下暂无可兑换套餐。」；**禁止** mock 套餐列表

#### Scenario: 卡包立即兑换

- **WHEN** 用户在待使用权益卡点击「立即兑换」
- **THEN** 进入 `/activate/redeem`
