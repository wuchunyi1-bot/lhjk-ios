# Shipping Address

## Purpose

提供收货地址管理能力，支持用户新增、修改、查询、删除收货地址，用于商城下单时选择配送地址。

地址编辑交互对齐 funde-client PRD《04_用户_我的地址》：所在地区支持「定位」回填（CoreLocation + CLGeocoder），保存接口字段不变。

## API Reference

| 接口 | 方法 | 路径 |
|------|------|------|
| 新增/修改地址 | `POST` | `/v1/address/saveOrUpdateAddress` |
| 查询地址列表 | `GET` | `/v1/address/getAddressList` |
| 删除地址 | `DELETE` | `/v1/address/deleteAddressById` |

### Data Model: MAddress

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | Int64 | 主键（新增时不传，修改时必传） |
| `userId` | Int64 | 用户 ID |
| `name` | String | 收货人名称 |
| `mobile` | String | 收货人电话 |
| `isDefault` | Int32 | 是否默认地址（1=是，0=否） |
| `province` | String | 所在省份 |
| `city` | String | 所在城市 |
| `area` | String | 所在区 |
| `address` | String | 详细地址 |
| `code` | String | 邮政编码 |
| `createTime` | String | 创建时间 |
| `createId` | Int64 | 创建人 ID |
| `modifyTime` | String | 修改时间 |
| `modifyId` | Int64 | 修改人 ID |

> 无经纬度字段。定位结果经逆地理编码写入上述字符串字段后提交。

### Response Wrapper

所有接口统一返回 `APIResponse<T>`：
```json
{ "code": "0", "data": {...}, "msg": "ok", "total": 0, "success": true, "failed": false }
```

查询列表时 `data` 为分页对象，包含 `list`（地址列表）、分页信息等。

## Requirements

### Requirement: Address CRUD
系统 SHALL 提供收货地址的完整增删改查能力。

#### Scenario: 查询地址列表
- **WHEN** 用户进入收货地址页面
- **THEN** BLL 层调用 `GET /v1/address/getAddressList` 获取当前用户的地址列表，支持分页参数（`pageNum`、`pageSize`），PL 层以列表形式展示

#### Scenario: 新增地址
- **WHEN** 用户在地址编辑页填写完整信息（收货人、电话、省市区、详细地址、是否默认）并提交
- **THEN** BLL 层调用 `POST /v1/address/saveOrUpdateAddress`，不传 `id` 字段，创建成功后返回地址列表页并刷新

#### Scenario: 修改地址
- **WHEN** 用户在地址列表页点击某个地址的编辑按钮
- **THEN** 列表页将已有的 `MAddress` 对象直接传递给编辑页，编辑页立即填充表单（无需再次网络请求），用户修改后 BLL 层调用 `POST /v1/address/saveOrUpdateAddress`，传入 `id` 字段，更新成功后返回地址列表页并刷新

#### Scenario: 删除地址
- **WHEN** 用户在地址列表页滑动删除或点击删除按钮
- **THEN** BLL 层调用 `DELETE /v1/address/deleteAddressById?id={id}`，删除成功后刷新列表

#### Scenario: 设置默认地址
- **WHEN** 用户将某个地址设为默认并保存
- **THEN** 系统调用保存接口将 `isDefault` 设为 1；第一条地址强制默认且开关不可关

---

### Requirement: Address Edit Form
地址编辑页 SHALL 对齐 funde 表单结构与文案。

#### Scenario: 标题区分
- **WHEN** 新增 → 标题「添加收货地址」；编辑 → 标题「编辑收货地址」

#### Scenario: 字段结构
- **THEN** 页面包含：收货人、手机号、所在地区（展示行 +「定位」按钮）、详细地址、邮政编码（选填）、设为默认地址、保存地址

#### Scenario: 定位回填
- **WHEN** 用户点击「定位」
- **THEN** 通过 `LocationManager` 按需请求授权、单次定位并逆地理编码，成功后回填省市区与详址
- **WHEN** 定位失败
- **THEN** Toast「定位失败，请手动选择」

#### Scenario: 手动编辑地区
- **WHEN** 用户点击所在地区行（非定位按钮）
- **THEN** 可手动编辑省/市/区（四级联动数据源待定前的过渡方案）

---

### Requirement: Input Validation
系统 SHALL 在提交前对地址表单进行前端校验。

#### Scenario: 必填校验
- **WHEN** 收货人为空 → 「请输入收货人姓名」
- **WHEN** 省市区不完整 → 「请选择所在地区」
- **WHEN** 详细地址为空 → 「请输入详细地址」

#### Scenario: 手机号格式校验
- **WHEN** 手机号不符合 `^1[3-9]\d{9}$`
- **THEN** 「请输入正确的手机号码」

---

### Requirement: Empty State
系统 SHALL 在无地址时展示空状态引导。

#### Scenario: 空列表
- **WHEN** 用户尚无任何收货地址
- **THEN** PL 层展示空状态插图和「暂无收货地址」文案，并提供「新增地址」入口按钮
