# lhjk-client-new iOS — 网络接口全量清单

> 扫描范围：`lhjk-client-new/**/*.swift` 中经 `APIManager` / `OAuthAuthenticator` 发出的后端 HTTP 请求。  
> 扫描日期：2026-08-04（增补健康 Tab CMS / 监测卡片 4 接口；此前 2026-08-03 修订）  
> Apifox 项目分享：https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/（**只读**，禁止修改 Apifox）  
> 层级来源：各接口文档 YAML `x-apifox-folder`；分享站无公开 md 时标注「文档暂无」，以 App 实际 path 为准。

## 约定

| 项 | 说明 |
|----|------|
| 业务 Base | `{gateway}/mobile` + `/v1/...` |
| 网关根 | `useGatewayRoot: true` → `{gateway}` + 路径（OAuth：`/auth/oauth2/...`） |
| Apifox OAuth 路径 | 文档多为 `/oauth2/token`、`/oauth2/logout`；App 请求 `/auth/oauth2/*` |
| Apifox | **只读查阅**；对齐实现只改本仓库 |
| 不计入本表 | 路由 `/auth/agreement/*`；融云 SDK；OSS 预签名 PUT；媒体 URLSession 下载；`PaymentService`（无 path） |
| 不写入本表 | App **未调用** 的 Apifox 接口（如 `GET /v1/coupon/getCouponList`）；历史误写 path（如 `getPackageDetail`，已不存在） |

**唯一后端 path 合计：44**（`POST /auth/oauth2/token` 计 1 条）。

---

## 1. 按 Apifox 层级（目录树）

```
登录注册/
├── 用户端app
│   └── POST /auth/oauth2/token          # 短信登录或注册 / 账号密码登录 / 微信 WE_CHAT_APP_LOGIN / Token 刷新
└── DELETE /auth/oauth2/logout

App端/
├── 系统/
│   ├── 系统短信管理
│   │   └── GET  /v1/mobileVerification/sendVerificationCode
│   ├── 用户管理
│   │   ├── POST /v1/users/updateCurrentProfile
│   │   ├── GET  /v1/users/getCurrentUserBaseInfo
│   │   ├── POST /v1/users/resetPasswordByMobile
│   │   ├── POST /v1/users/changeMobile
│   │   ├── POST /v1/users/cancelCurrentUser
│   │   └── POST /v1/users/changeCurrentPassword
│   ├── 字典管理
│   │   └── POST /v1/dictionary/getDictionaryByParentId2
│   └── 阿里云OSS
│       └── GET  /v1/cos/getCosSign
├── 机构/
│   ├── 医院管理
│   │   ├── GET /v1/hospital/searchPage
│   │   └── GET /v1/hospital/getById
│   ├── 医生管理
│   │   └── GET /v1/doctor/getDoctorPage
│   └── 档案管理
│       ├── GET  /v1/archive/getOArchiveByUserId
│       └── POST /v1/archive/saveArchiveHospital
├── 商城/
│   ├── 收货地址管理
│   ├── 购物车管理
│   ├── 商城套餐相关接口
│   ├── 商城订单相关接口
│   ├── 订单支付服务
│   │   └── GET  /v1/orderPay/orderPay
│   ├── 商城退款订单相关接口
│   └── 优惠券领用 / 员工权益卡管理
├── 内容/
│   └── 展示位内容设置管理
│       └── GET /v1/columnContent/getByCode
├── IM/
│   ├── 群组会话
│   │   ├── GET /v1/session/getGroup
│   │   └── GET /v1/session/getUserParticipateAllTeam
│   └── IM账户管理
│       └── POST /v1/account/addRongImAccount
├── 居家健康/
│   └── 监测方案定义
│       └── GET /v1/scheme/getUserToDayMonitorTask
└── 监测/
    ├── 我的健康页
    │   └── GET  /v1/healthPage/getCmsConfig
    ├── 体征监测卡片
    │   └── GET  /v1/monitorHealth/getMonitorCardList
    └── 用户监测卡片配置
        ├── GET  /v1/userMonitorCardConfig/getUserMonitorCardConfig
        └── POST /v1/userMonitorCardConfig/saveUserMonitorCardConfig
```

---

## 2. 全量明细表（按层级排序）

### 2.1 登录注册

| # | Method | App 请求 Path | Apifox 层级 | 调用位置 | Apifox（只读） |
|---|--------|---------------|-------------|----------|----------------|
| 1 | POST | `/auth/oauth2/token` | `登录注册/用户端app` | `LoginService`、`OAuthAuthenticator` | [短信登录](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/475979028e0.md) / [密码登录](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/475959250e0.md) |

> `#1` 另支持 `grant_type=WE_CHAT_APP_LOGIN`（微信 App 登录；未绑定手机返回 `AU0001`，绑定再提交 `code`+`mobile`+`smsCode`）。见 `openspec/changes/wechat-app-login/`。
| 2 | DELETE | `/auth/oauth2/logout` | `登录注册` | `LoginService.logout` | [退出登录](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/481379011e0.md) |

> 网关：`useGatewayRoot = true`。Apifox 文档 path 为 `/oauth2/*`。

### 2.2 App端 / 系统

| # | Method | Path | Apifox 层级 | 调用位置 | Apifox（只读） |
|---|--------|------|-------------|----------|----------------|
| 3 | GET | `/v1/mobileVerification/sendVerificationCode` | `App端/系统/系统短信管理` | `LoginService` | [发送验证码](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330856e0.md) |
| 4 | POST | `/v1/users/updateCurrentProfile` | `App端/系统/用户管理` | `UserService` | [修改资料](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/477932114e0.md) |
| 5 | GET | `/v1/users/getCurrentUserBaseInfo` | `App端/系统/用户管理` | `UserService` / `UserManager` | [当前用户](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/478379956e0.md) |
| 6 | POST | `/v1/users/resetPasswordByMobile` | `App端/系统/用户管理` | `UserService` | [重置密码](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/476633097e0.md) |
| 7 | POST | `/v1/users/changeMobile` | `App端/系统/用户管理` | `UserService` | [改手机号](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330847e0.md) |
| 8 | POST | `/v1/users/cancelCurrentUser` | `App端/系统/用户管理` | `UserService` | [注销](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/483911256e0.md) |
| 9 | POST | `/v1/users/changeCurrentPassword` | `App端/系统/用户管理` | `UserService` | [改当前密码](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/476633098e0.md) |
| 10 | POST | `/v1/dictionary/getDictionaryByParentId2` | `App端/系统/字典管理` | `DictionaryService` | [字典](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330853e0.md) |
| 11 | GET | `/v1/cos/getCosSign` | `App端/系统/阿里云OSS` | `OSSManager` | [OSS 签名](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330939e0.md) |

### 2.3 App端 / 机构

| # | Method | Path | Apifox 层级 | 调用位置 | Apifox（只读） |
|---|--------|------|-------------|----------|----------------|
| 12 | GET | `/v1/hospital/searchPage` | `App端/机构/医院管理` | `HospitalService` | [搜索医院](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/488248475e0.md) |
| 13 | GET | `/v1/hospital/getById` | `App端/机构/医院管理` | `HospitalService` | [医院详情](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330908e0.md) |
| 14 | GET | `/v1/doctor/getDoctorPage` | `App端/机构/医生管理` | `DoctorService` | [医生分页](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330896e0.md) |
| 15 | GET | `/v1/archive/getOArchiveByUserId` | `App端/机构/档案管理` | `UserService` | [默认档案](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/486441727e0.md) |

> `#15` 客户端使用 `data.archiveComplete` 作为 `/onboarding` 唯一门禁；另解码 `sex` / `birthday` 等回填字段。Apifox 分享站 `OArchiveVO` 可能尚未同步这些字段（以联调 JSON 为准）。
| 16 | POST | `/v1/archive/saveArchiveHospital` | `App端/机构/档案管理` | `UserService` | [保存档案机构](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/491046480e0.md) |

### 2.4 App端 / 商城

| # | Method | Path | Apifox 层级 | 调用位置 | Apifox（只读） |
|---|--------|------|-------------|----------|----------------|
| 17 | GET | `/v1/address/getAddressList` | `App端/商城/收货地址管理` | `AddressService` | [地址列表](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330757e0.md) |
| 18 | POST | `/v1/address/saveOrUpdateAddress` | `App端/商城/收货地址管理` | `AddressService` | [新增修改地址](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330756e0.md) |
| 19 | DELETE | `/v1/address/deleteAddressById` | `App端/商城/收货地址管理` | `AddressService` | [删除地址](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330758e0.md) |
| 20 | POST | `/v1/shoppingCart/saveShoppingCartOrPurchase` | `App端/商城/购物车管理` | `ShoppingCartService` | [加购/购买](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330718e0.md) |
| 21 | GET | `/v1/shoppingCart/getShoppingCartList` | `App端/商城/购物车管理` | `ShoppingCartService` | [购物车列表](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330722e0.md) |
| 22 | DELETE | `/v1/shoppingCart/deleteShoppingCart` | `App端/商城/购物车管理` | `ShoppingCartService` | [删购物车](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330724e0.md) |
| 23 | GET | `/v1/hospitalPackage/getEnabledHospitalPackagePage` | `App端/商城/商城套餐相关接口` | `HospitalPackageService` | [启用套包分页](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/484150836e0.md) |
| 24 | GET | `/v1/hospitalPackage/getEnabledRetailHospitalPackagePage` | `App端/商城/商城套餐相关接口` | `HospitalPackageService` | [零售套包分页](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/487882770e0.md) |
| 25 | GET | `/v1/hospitalPackage/getCategoryServiceListByType` | `App端/商城/商城套餐相关接口` | `HospitalPackageService` | [业务类别](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/487882771e0.md) |
| 26 | GET | `/v1/hospitalPackage/getHospitalPackageDetail` | `App端/商城/商城套餐相关接口` | `HospitalPackageService` | 文档暂无（**正确 path**；勿用已废弃的 `getPackageDetail`） |
| 27 | GET | `/v1/order/getAppOrderList` | `App端/商城/商城订单相关接口` | `OrderService` | [订单列表](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330738e0.md) |
| 28 | GET | `/v1/order/getAppOrderDetail` | `App端/商城/商城订单相关接口` | `OrderService` | [订单详情](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330739e0.md) |
| 29 | GET | `/v1/order/getOrderSettlement` | `App端/商城/商城订单相关接口` | `OrderService` | [结算信息](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/490169537e0.md) |
| 30 | POST | `/v1/order/insertOrEdit` | `App端/商城/商城订单相关接口` | `OrderService` | [新增编辑订单](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330734e0.md) |
| 31 | POST | `/v1/order/updateOrderDelivery` | `App端/商城/商城订单相关接口` | `OrderService` | [改配送](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/490169536e0.md) |
| 32 | POST | `/v1/order/updateOrderDescription` | `App端/商城/商城订单相关接口` | `OrderService` | [改备注](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/490169535e0.md) |
| 33 | POST | `/v1/orderClearing/submitReturnGoods` | `App端/商城/商城退款订单相关接口` | `OrderService` | [提交退货](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/493050735e0.md) |
| 33a | GET | `/v1/orderPay/orderPay` | `App端/商城/订单支付服务` | `OrderService` / `PaymentService.payMallOrder`；确认订单立即支付 | [支付统一接口](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330716e0.md) |
| 34 | GET | `/v1/couponTake/getCouponTakeList` | `App端/商城/优惠券领用` | `CouponService` | [领用列表](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330752e0.md) |
| 35 | POST | `/v1/couponTake/bindCouponTake` | `App端/商城/优惠券领用` | `CouponService` | [绑定优惠券](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330751e0.md) |
| 35a | GET | `/v1/benefitsTake/getCustomerPage` | `App端/商城/员工权益卡管理` | `VoucherService`（卡包列表） | [用户卡包分页](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/498029202e0.md) |
| 35b | GET | `/v1/benefitsTake/getCustomerStatusCount` | `App端/商城/员工权益卡管理` | `VoucherService`（角标回退） | [用户状态数量](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/498029201e0.md) |
| 35c | GET | `/v1/benefitsTake/getGiftRecordPage` | `App端/商城/员工权益卡管理` | `VoucherService` | [转赠记录](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/498029200e0.md) |
| 35d | POST | `/v1/benefitsTake/preCheckByKey` | `App端/商城/员工权益卡管理` | `VoucherService` | [卡密预校验](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/498029194e0.md) |
| 35e | POST | `/v1/benefitsTake/bindByKey` | `App端/商城/员工权益卡管理` | `VoucherService` | [卡密绑定](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/498029199e0.md) |
| 35f | POST | `/v1/benefitsTake/giftBenefit` | `App端/商城/员工权益卡管理` | `VoucherService` | [好友转赠](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/498029198e0.md) |
| 35g | GET | `/v1/benefitsTake/getActivationOverview` | `App端/商城/员工权益卡管理` | `VoucherService`；激活兑换 Hub | [激活兑换入口](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/498627164e0.md) |
| 35h | GET | `/v1/benefitsTake/getRedeemPageInfo` | `App端/商城/员工权益卡管理` | `VoucherService`；兑换套餐页头/分类 | [兑换页基础数据](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/498627161e0.md) |
| 35i | GET | `/v1/benefitsTake/getRedeemPackagePage` | `App端/商城/员工权益卡管理` | `VoucherService`；可兑套餐列表 | [可兑套餐分页](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/498627162e0.md) |
| 35j | GET | `/v1/benefitsTake/getOrderBenefitsList` | `App端/商城/员工权益卡管理` | `VoucherService`；确认订单权益卡 | [订单可选权益卡](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/498627163e0.md) |
| 35k | POST | `/v1/benefitsTake/updateOrderBenefits` | `App端/商城/员工权益卡管理` | `VoucherService`；确认订单绑卡（query） | [保存订单权益卡](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/498627160e0.md) |

### 2.5 App端 / 内容 · IM · 居家健康

| # | Method | Path | Apifox 层级 | 调用位置 | Apifox（只读） |
|---|--------|------|-------------|----------|----------------|
| 36 | GET | `/v1/columnContent/getByCode` | `App端/内容/展示位内容设置管理` | `ColumnContentService` | [栏位内容](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/484052032e0.md) |

> `#36` Query `code`：服务 Hub Banner = `mall_advertisement`；首页 Banner = `home_banner_code`；首页金刚区 = `home_quickLink_code`；首页推荐健康套餐 = `home_healthService_code`；首页健康陪伴 = `home_news_code`。  
> 缓存：`ColumnContentCacheService` — 冷启动预拉已知 code 写入内存；界面优先读缓存，未命中再请求；无 TTL，登出清空。  
> `#36` 响应 `ColumnContentBo.detail`（作者/浏览数/标签等）用于健康陪伴列表展示（Apifox ColumnContentDetailBo）。
| 37 | GET | `/v1/session/getGroup` | `App端/IM/群组会话` | `IMService` | [我的群组](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/478720935e0.md) |
| 38 | GET | `/v1/session/getUserParticipateAllTeam` | `App端/IM/群组会话` | `HomeService` | [参与团队](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/495580451e0.md) |
| 39 | POST | `/v1/account/addRongImAccount` | `App端/IM/IM账户管理` | `RongCloudManager` | [融云账号](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/478384048e0.md) |
| 40 | GET | `/v1/scheme/getUserToDayMonitorTask` | `App端/居家健康/监测方案定义` | `HomeService` | [今日监测任务](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330787e0.md) |

### 2.6 App端 / 监测（健康 Tab）

| # | Method | Path | Apifox 层级 | 调用位置 | Apifox（只读） |
|---|--------|------|-------------|----------|----------------|
| 41 | GET | `/v1/healthPage/getCmsConfig` | `App端/监测/我的健康页` | `HealthPageService` | [健康页 CMS](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/495657301e0.md) |
| 42 | GET | `/v1/monitorHealth/getMonitorCardList` | `App端/监测/体征监测卡片` | `HealthPageService` | [监测卡片列表](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/495657300e0.md) |
| 43 | GET | `/v1/userMonitorCardConfig/getUserMonitorCardConfig` | `App端/监测/用户监测卡片配置` | `HealthPageService` | [查询卡片配置](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/495657299e0.md) |
| 44 | POST | `/v1/userMonitorCardConfig/saveUserMonitorCardConfig` | `App端/监测/用户监测卡片配置` | `HealthPageService` | [保存卡片配置](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/495657298e0.md) |

> Query / Body 共用：`hospitalId`（数字串）、`code=column_health`（APP）。保存 Body：`addCardVOList[{cardType, cardName?, sortId}]`，不传 `hiddenCardVOList`。规格见 `openspec/changes/health-page-vitals-cms-api/`。

---

## 3. 按 iOS 模块（BLL/DAL）索引

| 模块文件 | 接口数 | Paths |
|----------|--------|-------|
| `BLL/RegisterLogin/LoginService.swift` | 3 | oauth2/token、oauth2/logout、sendVerificationCode |
| `DAL/Networking/OAuthAuthenticator.swift` | 1（复用） | oauth2/token（refresh） |
| `BLL/User/UserService.swift` | 8 | users/* ×6、archive/* ×2 |
| `BLL/My/AddressService.swift` | 3 | address/* |
| `BLL/Service/OrderService.swift` | 8 | order/* ×6、orderClearing/submitReturnGoods、orderPay/orderPay |
| `BLL/Service/ShoppingCartService.swift` | 3 | shoppingCart/* |
| `BLL/Service/CouponService.swift` | 2 | couponTake/* |
| `BLL/My/VoucherService.swift` | 11 | benefitsTake/getCustomerPage、getCustomerStatusCount、getGiftRecordPage、preCheckByKey、bindByKey、giftBenefit、getActivationOverview、getRedeemPageInfo、getRedeemPackagePage、getOrderBenefitsList、updateOrderBenefits |
| `BLL/Service/HospitalPackageService.swift` | 4 | hospitalPackage/*（含 **getHospitalPackageDetail**） |
| `BLL/Service/HospitalService.swift` | 2 | hospital/* |
| `BLL/Service/DoctorService.swift` | 1 | doctor/getDoctorPage |
| `BLL/Service/ColumnContentService.swift` | 1 | columnContent/getByCode |
| `BLL/Service/DictionaryService.swift` | 1 | dictionary/getDictionaryByParentId2 |
| `BLL/Home/HomeService.swift` | 2 | scheme/getUserToDayMonitorTask、session/getUserParticipateAllTeam |
| `BLL/Health/HealthPageService.swift` | 4 | healthPage/getCmsConfig、monitorHealth/getMonitorCardList、userMonitorCardConfig/* ×2 |
| `BLL/Message/IMService.swift` | 1 | session/getGroup |
| `DAL/IM/RongCloudManager.swift` | 1 | account/addRongImAccount |
| `DAL/OSS/OSSManager.swift` | 1 | cos/getCosSign |

---

## 4. 明确排除（勿当作本 App 接口）

| 项 | 说明 |
|----|------|
| `GET /v1/hospitalPackage/getPackageDetail` | **不存在 / 已废弃命名**；正确为 `getHospitalPackageDetail` |
| `POST /v1/users/changePassword` | Apifox 分享站无文档且 App **无调用**，已从 `UserService` 删除 |
| 失效链接 `…/485486161e0` | 分享站 404；已从代码注释与清单移除，**不**在 Apifox 补文档 |
| `GET /v1/coupon/getCouponList` | Apifox 有文档，**本 App 未调用** |
| 订单绑定权益卡 / 结算权益抵扣字段 | Apifox **文档暂无**；确认订单本期客户端多选试算（复用 35a），不以假 path 调用 |
| `/auth/agreement/*` | 协议页路由，非 HTTP API |
| `/v1/monitor/*` | 体征**录入**类原生 path 当前工程无 Swift 调用（多走 H5）；勿与已接入的 `/v1/monitorHealth/*`、`/v1/healthPage/*`、`/v1/userMonitorCardConfig/*` 混淆 |

---

## 5. 校验方法（防漏）

```bash
rg -o --glob '*.swift' '/(v1|auth)/[A-Za-z0-9_./-]+' lhjk-client-new | sort -u
rg -l --glob '*.swift' 'getAsync|postAsync|deleteAsync|putAsync|postFormURLEncodedAsync|publicPostFormURLEncodedAsync' lhjk-client-new
```

新增接口时：只读 Apifox → 改本仓库 → 更新本清单。
