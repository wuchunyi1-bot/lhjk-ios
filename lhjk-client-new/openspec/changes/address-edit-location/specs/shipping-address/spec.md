# Shipping Address — Delta

## MODIFIED Requirements

### Requirement: Address Edit Form
地址编辑页 SHALL 对齐 funde「添加/编辑收货地址」交互：收货人、手机号、所在地区（展示 + 定位）、详细地址、设为默认；保存仍调用既有 `POST /v1/address/saveOrUpdateAddress`。

#### Scenario: 标题区分
- **WHEN** 新增模式进入编辑页
- **THEN** 标题为「添加收货地址」
- **WHEN** 编辑模式进入编辑页
- **THEN** 标题为「编辑收货地址」

#### Scenario: 定位回填
- **WHEN** 用户点击「定位」且定位+逆地理成功
- **THEN** 回填 `province` / `city` / `area`，有详址结果时回填 `address`；可选回填 `code`
- **WHEN** 定位失败
- **THEN** Toast「定位失败，请手动选择」，保留已有输入

#### Scenario: 校验文案
- **WHEN** 收货人为空并保存 → Toast「请输入收货人姓名」
- **WHEN** 手机号非法并保存 → Toast「请输入正确的手机号码」（`^1[3-9]\d{9}$`）
- **WHEN** 省市区任一缺失并保存 → Toast「请选择所在地区」
- **WHEN** 详细地址为空并保存 → Toast「请输入详细地址」

#### Scenario: 默认地址
- **WHEN** 用户当前无地址（新增第一条）
- **THEN** 「设为默认地址」开启且不可关闭
- **WHEN** 保存且勾选默认
- **THEN** `isDefault=1` 提交，由后端/既有逻辑保证唯一性

#### Scenario: 接口不变
- **WHEN** 保存地址
- **THEN** 仍使用 `AddressSavePayload` 字段（`name/mobile/isDefault/province/city/area/address/code`），不传经纬度

## ADDED Requirements

### Requirement: Manual Region Fallback
在四级地区选择器数据源未就绪前，系统 SHALL 允许用户手动编辑省/市/区。

#### Scenario: 手动编辑地区
- **WHEN** 用户点击「所在地区」行（非定位按钮）
- **THEN** 展示可编辑省/市/区的输入界面，确认后回显到地区行
