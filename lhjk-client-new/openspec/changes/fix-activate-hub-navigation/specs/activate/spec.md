## MODIFIED Requirements

### Requirement: 激活兑换 Hub 操作卡导航

`/activate` 操作卡 SHALL 对齐 funde `ActivateView`：整卡与右侧胶囊均可跳转。

#### Scenario: 去绑定

- **WHEN** 用户点击绑定卡任意区域或「去绑定」
- **THEN** `Router.push("/activate/bind", from: 当前 VC)`，进入绑定权益卡页
- **AND** 隐藏 Tab Bar

#### Scenario: 去兑换

- **WHEN** 用户点击兑换卡任意区域或「去兑换」
- **THEN** `Router.push("/activate/redeem", from: 当前 VC)`，进入兑换套餐页
- **AND** 无论当前是否有可用权益卡，均允许进入（无卡时兑换页可再引导绑定）

#### Scenario: 触摸可点

- **WHEN** 操作卡内含步骤标签、图标、文案与 CTA
- **THEN** 不得因嵌套 Stack/子视图吞掉点击；整卡与 CTA 均可触发导航
