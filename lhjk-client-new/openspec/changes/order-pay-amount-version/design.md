# Design: order-pay-amount-version

## 后端契约（Apifox 只读）

| 接口 | 字段 | 说明 |
|------|------|------|
| `GET /v1/order/getOrderSettlement` | `data.amountVersion` int32 | 结算版本，支付时原样带回 |
| 同上 | `data.expectedPayableAmount` number | 期望应付金额，支付时原样带回 |
| `GET /v1/order/getAppOrderDetail` | `data.amountVersion` / `data.expectedPayableAmount` | 同上；详情另有 `settlementVersion` 可作版本缺省 |
| `POST /v1/orderPay/orderPay` | JSON body 同名字段 | 与当前结算不一致时拒绝拉起支付 |

Apifox GET 文档标题仍为「灰度兼容，可不带结算版本」；客户端新链路 **始终 POST JSON body 并带上两字段**，**禁止** query。

## 决策

1. **原样带回**：禁止用本地重算的应付（含确认页本地权益抵扣启发式）替换 `expectedPayableAmount`。
2. **展示**：结算应付优先 `expectedPayableAmount`，与将要提交的校验金额一致。
3. **拒绝支付**：展示 `msg`，调用 `getOrderSettlement` 刷新，不跳转、不调起微信/支付宝。
4. **缺字段**：有则必传；版本缺失不造假 `0`。应付缺失时退到结算 `totalPrice` / 详情 `settlementAmount`。
