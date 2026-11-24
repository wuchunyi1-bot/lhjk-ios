## ADDED Requirements

### Requirement: 预约体检可预约列表

系统 SHALL 用 `GET /v1/cabin/medicalConfigList` 渲染预约体检列表。`businessType` 为 2。分页认 `list`、`totalCount`、`totalPage`、`currPage`，也认中文分页别名。

#### Scenario: 套餐卡片

- **WHEN** 列表返回一条配置，例如名称「体检项目1」、`price` 为 10.00、`navigateUrl` 有图、`description` 为 `<p>呜呜呜呜呜</p>`
- **THEN** 卡片为横向布局：封面 96×96，标题最多两行，简介为去掉 HTML 后的纯文本且最多两行
- **AND** 封面优先 `navigateUrl`，没有时用 `imgUrls` 第一张
- **AND** 价格显示为 ¥10，按钮文案为「去预约」
- **AND** 多条时收进同一块白底圆角列表，行间有分割线
- **AND** 列表为空时展示「暂无可预约体检套餐」
- **AND** 接口没有权益名称时不展示权益胶囊

#### Scenario: 进入详情与预约

- **WHEN** 用户点击卡片
- **THEN** 进入项目预约详情，参数为该条 `id`
- **WHEN** 用户点击「去预约」且 `payType` 为 2 并带有 `packageId`
- **THEN** 先确认「需要购买后才能预约」，确认后进入对应套包购买页
- **WHEN** 用户点击「去预约」且不需要购买
- **THEN** 先确认预约，确认后提示工作人员会联系安排，不创建本地假会话

### Requirement: 体检与就医协助使用记录

系统 SHALL 用 `GET /v1/cabin/appointments` 展示使用记录。预约体检传 `businessType = 2`，就医协助传 `businessType = 3`。两边不共用一次不带类型的请求。

#### Scenario: 只看本类记录

- **WHEN** 用户在预约体检打开使用记录
- **THEN** 请求带 `businessType = 2`，不带 `status`
- **WHEN** 用户在就医协助打开使用记录
- **THEN** 请求带 `businessType = 3`
- **AND** 没有记录时展示「暂无使用记录」
- **AND** 列表不提供小屋的取消预约和再次预约
