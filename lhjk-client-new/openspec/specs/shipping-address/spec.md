# Shipping Address

## Purpose

提供收货地址管理能力，支持用户新增、修改、查询、删除收货地址，用于商城下单时选择配送地址。

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

### Response Wrapper

所有接口统一返回 `APIResponse<T>`：
```json
{ "code": "0", "data": {...}, "msg": "ok", "total": 0, "success": true, "failed": false }
```

查询列表时 `data` 为分页对象，包含 `records`（地址列表）、分页信息等。

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
- **WHEN** 用户在地址编辑页修改已有地址的信息并提交
- **THEN** BLL 层调用 `POST /v1/address/saveOrUpdateAddress`，传入 `id` 字段，更新成功后返回地址列表页并刷新

#### Scenario: 删除地址
- **WHEN** 用户在地址列表页滑动删除或点击删除按钮
- **THEN** BLL 层调用 `DELETE /v1/address/deleteAddressById?id={id}`，删除成功后刷新列表

#### Scenario: 设置默认地址
- **WHEN** 用户在地址列表页将某个地址设为默认
- **THEN** 系统调用保存接口将 `isDefault` 设为 1，刷新列表后该地址显示"默认"标记

---

### Requirement: Input Validation
系统 SHALL 在提交前对地址表单进行前端校验。

#### Scenario: 必填校验
- **WHEN** 用户提交地址表单时存在必填字段为空
- **THEN** PL 层阻止提交并提示"请填写完整的收货信息"

#### Scenario: 手机号格式校验
- **WHEN** 用户输入的收货人电话格式不正确
- **THEN** PL 层提示"请输入正确的手机号码"

---

### Requirement: Empty State
系统 SHALL 在无地址时展示空状态引导。

#### Scenario: 空列表
- **WHEN** 用户尚无任何收货地址
- **THEN** PL 层展示空状态插图和"暂无收货地址"文案，并提供"新增地址"入口按钮
