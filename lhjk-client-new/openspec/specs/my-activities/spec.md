# 我的活动

## Purpose

首页金刚区进入当天活动列表，再进入单场活动详情。列表和详情都走会员活动 C 端接口，不使用本地假数据。

## Requirements

### Requirement: 入口

首页金刚区「我的活动」打开本地路由 `/home/activities`。运营把该入口配成 `FundeApp:/home/activities`。未注册时 `FundeApp:` 不跳转。

#### Scenario: 打开列表

- **WHEN** 用户点击首页「我的活动」
- **THEN** push `MyActivitiesViewController`，顶栏标题「我的活动」，可返回首页

### Requirement: 活动列表

系统 SHALL 调用 `GET /v1/memberActivity/client/listMyActivitiesForClient`。该接口无 query，服务端已按当前用户、已签到、当天可见过滤。

列表只展示角标 `clientBadgeCode` 为进行中或已结束的活动：

| `clientBadgeCode` | 展示 |
|---|---|
| 1 待开始 | 不出现 |
| 2 进行中 | 暖色卡片，右上角「进行中」角标 |
| 3 已结束 | 灰色卡片，右上角「已结束」角标 |
| 4 已提交并评价 | 灰色卡片，右上角「已结束」角标 |

排序：进行中在前；同一状态按 `startTime` 从早到晚。

卡片展示 `theme`、活动时间、`ourLeaderName`。进行中标题 `#522B0F`、说明 `#8C714F`，使用 `event_live_*` 切图；已结束标题 `#303030`、说明 `#6E6E6E`，使用 `event_end_*` 切图。文案为「活动时间：」和「活动负责人：」。时间把 `yyyy-MM-dd HH:mm:ss` 收成 `yyyy-MM-dd H:mm-H:mm`（日期取开始日，去掉秒，小时不补前导零）。空列表展示「暂无活动」。

能否进入详情以列表字段 `detailAccessible` 为准。该字段与详情接口时间窗一致：结束满 2 小时后为 `false`。为 `false` 时卡片仍显示并变淡，不可点击。

#### Scenario: 进入详情

- **WHEN** 用户点击 `detailAccessible` 为 true 的卡片
- **THEN** push `/home/activities/detail`，参数 `activityId` 为该行活动 id

#### Scenario: 不可进入详情

- **WHEN** 列表返回 `detailAccessible` 为 false
- **THEN** 卡片变淡且不能进入详情

### Requirement: 活动详情

系统 SHALL 调用 `GET /v1/memberActivity/client/getDetailForClient?activityId=`。顶栏标题仍是「我的活动」。

页面展示主题、活动时间、活动负责人，样式与进行中列表卡一致，右上角放 `event_detail_icon`。同一张白卡内是福利区：礼盒 `event_detail_gift`、标题「添加健康福利官」、副文案「一键领取现场健康福利，享报告解读、健康咨询等专属权益」，主按钮「立即领取」。App 不展示企微二维码。

「立即领取」在已安装微信时调用 `WeChatSDKManager.launchMiniProgram`，path 为 `WeChatConfig.memberActivityDetailPath(activityId:)`，即 `pkg-mine/activities/detail?id={id}`。小程序版本与健康知识分享相同。未安装微信时 Toast，不发请求。

设备检测入口来自详情 `clientDetectionItems`。无绑定时该列表为空，不展示「设备检测」。有入口时单独白卡，两列排列。每项名称、橙色「去检测 ›」，右侧设备图：

| 字段 | 用途 |
|---|---|
| `description` | 入口名称。为空时按类型码使用「鹰瞳眼底检测 / 呼吸道炎症仪检测 / 消化道菌群失衡检测」 |
| `clientDetectionTypeCode` | `15` 鹰瞳、`16` 炎症仪、`17` 炎菌仪。同一类型只保留第一项，顺序保持接口返回顺序 |
| `pageUrl` | 与健康首页同类型卡片相同的 CMS 地址。点击时在其后追加 `activityId`，再按 `FundeH5:` / `FundeApp:` 打开 |
| `imageUrl` / `iconUrl` / `imgUrl` | 设备图，有值才显示。都没有时右侧留空，不用本地占位图 |

`pageUrl` 无法打开时，按类型码进入本地路由 `/health/metrics/fundus`、`/health/metrics/respiratory-inflammation`、`/health/metrics/gut-flora`，并带上 `activityId`。带活动进入检测页时同时提供扫一扫和选择设备 SN。活动不存在时展示「未找到该活动」。

#### Scenario: 领取福利官

- **WHEN** 用户点击「立即领取」且本机已安装微信
- **THEN** 打开用户端小程序的同场次活动详情

#### Scenario: 进入本场检测

- **WHEN** 用户点击某条检测入口
- **THEN** 打开该项 `pageUrl`，并带上当前 `activityId`
