## ADDED Requirements

### Requirement: 三协议勾选与知情同意确认弹窗

登录表单底部与前置隐私弹窗 SHALL 展示三项协议：《用户协议》《隐私政策》《健康管理服务知情同意书》。最终提交（验证码登录、密码登录）未勾选时 SHALL 弹出知情同意确认弹窗，而非仅 Toast。

对齐 PRD AUTH-06、funde `LoginView.vue`。

#### Scenario: 三协议勾选文案

- **WHEN** 展示登录页协议区
- **THEN** 文案为「我已阅读并同意《用户协议》《隐私政策》与《健康管理服务知情同意书》」
- **AND** 三项名称均可点击打开协议预览（Router / WebView）
- **AND** 默认未勾选

#### Scenario: 未勾选最终提交

- **WHEN** 用户点击登录/注册或密码登录且未勾选协议
- **THEN** 弹出知情同意确认弹窗
- **AND** 文案提示先阅读并同意三协议
- **AND** 提供「查看用户协议 / 隐私政策 / 知情同意书」入口
- **AND** 「同意并继续」自动勾选三协议并继续原提交动作
- **AND** 「稍后再看」关闭弹窗且不提交

#### Scenario: 获取验证码不强制勾选

- **WHEN** 用户点击获取验证码
- **THEN** **不因**未勾选协议而弹出知情同意弹窗（对齐 PRD；仍校验手机号与拼图）

#### Scenario: 前置隐私弹窗

- **WHEN** 首次启动或协议版本更新展示隐私保护提示
- **THEN** 链接区含上述三项协议
- **AND** 说明文案可提及三协议

---

### Requirement: 忘记密码页内步骤

忘记密码 SHALL 在登录页内部以步骤切换完成，不依赖独立顶栏导航作为主路径。

对齐 PRD AUTH-08、funde `LoginView` `step=forgot|reset-password`。

#### Scenario: 进入找回

- **WHEN** 用户在密码登录模式点击「忘记密码」
- **THEN** 登录页切换至「找回密码」步骤（页内标题「找回密码」+ 返回密码登录）
- **AND** 预填当前密码登录手机号（若有）
- **AND** 展示手机号、验证码、获取验证码；获取前走拼图验证

#### Scenario: 进入设置新密码

- **WHEN** 找回步骤用户点击下一步且手机号、验证码格式合法
- **THEN** 调用 `GET /v1/mobileVerification/checkedSmsCode`（`mobile`、`checkCode`、`type=2`）校验验证码
- **WHEN** 校验成功
- **THEN** 切换至「设置新密码」步骤
- **AND** 展示新密码、确认新密码与提交
- **WHEN** 校验失败
- **THEN** Toast 展示服务端错误（如验证码错误/过期），停留找回步骤

#### Scenario: 重置成功

- **WHEN** 新密码校验通过并调用重置接口成功
- **THEN** 回到密码登录步骤
- **AND** 预填该手机号
- **AND** Toast「密码已重置，请重新登录」

#### Scenario: 返回

- **WHEN** 用户在找回或设置新密码步骤点击返回
- **THEN** 回到密码登录步骤，不离开登录页

---

### Requirement: 完善资料所属机构与 hospitalId

完善基础信息页 SHALL 采集所属机构并写入 `hospitalId`；门禁字段为 `chineseName`、`sex`、`birthday`、`hospitalId`。

对齐 PRD §5.10 / §5.11、`onboarding-login-userinfo`。

#### Scenario: 字段

- **WHEN** 展示完善资料页
- **THEN** 必填：姓名、性别、出生日期、所属机构（选择入口，不可手输）
- **AND** **不得**以「所在城市」替代所属机构

#### Scenario: 选择机构

- **WHEN** 用户点击所属机构
- **THEN** 进入选择服务机构子页（仅启用机构）
- **AND** 选中后回显机构名称，并保存对应 `hospitalId`（接口真实 id，禁止 mock）

#### Scenario: 提交

- **WHEN** 用户点击提交且四项齐全
- **THEN** 更新资料，并将 `hospitalId` 写入 `loginUserInfo`
- **AND** `checkNeedOnboarding()` 不再因缺机构拦截
- **AND** 进入首页（或既有成功路径）

#### Scenario: 未选机构

- **WHEN** 未选所属机构点击提交
- **THEN** Toast「请选择服务机构」且不进入首页
