## 结构对比

| 区域 | 旧 iOS | 新原型 |
|------|--------|--------|
| Hero | 个人信息 pill + 健康档案 | 头像/姓名点进 profile；仅健康档案 pill |
| 会员 | 无 | 健康大会员四格资产 |
| 履约 | 无 | 四格订单统计 + 全部订单 |
| 常用功能 | 8 宫格 | **移除**（地址/设备进设置） |
| 健康管理 | 7 项含档案 | 6 项（档案仅在 Hero） |
| 登出 | Hub 底部 | **设置页底部** |

## 路由

### Hub

| 入口 | route |
|------|-------|
| 头像/姓名 | `/me/profile` |
| 设置齿轮 | `/me/settings` |
| 健康档案 | `/me/health-profile` |
| 健康大会员 / 会员等级 / 富德币 | `/me/member-level` |
| 会员兑换 | `/me/redemptions` |
| 健康积分 | `/me/points` |
| 权益卡券 | `/me/vouchers` |
| 履约四格 / 全部订单 | `/orders?tab=*` / `/orders` |
| 健康管理各行 | 见 `me.json` healthManagementActions |

### 设置

| 入口 | route |
|------|-------|
| 我的地址 | `/me/settings/addresses`（别名 `/me/address`） |
| 智能设备 | `/me/devices` |
| 退出登录 | 本页确认后走统一 logout 流程 |

## 数据

- 会员资产默认值对齐 `member-marketing.ts`（V1 / 892 / 200）；权益卡券数走 `VoucherService`
- 履约四格数量暂为 `0`，待订单统计 API
- 健康管理 detail 文案暂不展示 mock（未接 API 时留空）
