# Wellness Cabin — 康养小屋列表

## ADDED Requirements

### Requirement: 康养小屋列表

系统 SHALL 用与「选择服务机构」相同的页面结构展示康养小屋列表：顶部定位条，下方搜索与驿站卡片。入口为 `FundeApp:/wellness-cabins`，本地路由 `/wellness-cabins`。列表页不提供预约记录入口。

#### Scenario: 页面结构

- **WHEN** 用户进入康养小屋列表
- **THEN** 导航标题为「康养小屋」
- **AND** 顶部展示「当前定位」、城市与区，以及「重新定位」
- **AND** 搜索框 placeholder 为「搜索驿站名称或地址」
- **AND** 默认提示为「按距离展示附近健康驿站」；有关键词且有结果时提示「共找到 N 家驿站」
- **AND** 无结果展示「未找到匹配驿站」

#### Scenario: 列表数据

- **WHEN** 进入页面或重新定位、输入关键词
- **THEN** 调用 `GET /v1/cabin/list`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529266269e0.md)）
- **AND** 有定位时 Query 传入 `longitude`、`latitude`，坐标系为高德 GCJ-02，由服务端按距离由近到远排序
- **AND** 无定位时不传经纬度，仍可按关键词搜索
- **AND** 关键词匹配驿站名称或地址，客户端不再用「名称含驿站」过滤

#### Scenario: 驿站卡片

- **WHEN** 渲染一条驿站
- **THEN** 展示名称；地址行按省、市、区、详细地址拼接（相邻重复段只留一次，详细地址已含省市区时不重复拼接）；有距离时右侧展示距离，地址行追加「距离约{距离}」
- **AND** `openTime` 非空时在地址下展示「营业时间：{openTime}」
- **AND** `internalOnly = 1` 时在名称旁展示「仅限内部员工」，不拦截进入
- **AND** 返回 `recommended` 为 `1` 或 `true` 时，名称旁展示「推荐」；未返回则不展示
- **AND** 展示 `serviceTags`；有 `todayAvailableCount` 时展示「今日可约：N 人」和「去门店」

#### Scenario: 进入门店

- **WHEN** 用户点击启用中的驿站卡片任意区域，或点击「去门店」（`status` 缺省或为 1）
- **THEN** 两者进入同一门店详情 `/wellness-cabins/detail`，并带上 `hospitalId`；有距离时带上 `distanceLabel`
- **WHEN** `status = 0`
- **THEN** 卡片展示「暂不可预约」，「去门店」不可用，点击卡片或按钮都提示「当前暂不可预约」

### Requirement: 康养小屋门店详情

系统 SHALL 展示驿站门店信息，并按接口返回的服务分类列出可预约项目。详情不展示评分和评价。`recommended` 为 `1` 或 `true` 时，店名旁展示「推荐」。

#### Scenario: 门店信息

- **WHEN** 进入门店详情
- **THEN** 调用 `GET /v1/cabin/detail?hospitalId=`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529266267e0.md)）
- **AND** 顶部轮播使用 `banner`（逗号分隔的图片地址）；`banner` 为空时再用 `imgUrl`。高度固定 160。多于一张时每 4 秒向下一张循环，手指拖动时暂停。没有图时不占高度。店名旁提供「切换门店」，回到驿站列表
- **AND** 地址按省、市、区、详细地址拼接，规则与列表相同，本页地址行不带距离
- **AND** 距离沿用列表传入的 `distanceLabel`，本页不重新定位；没有距离则不展示
- **AND** `openTime` 非空时在时钟图标后展示该时间
- **AND** 「导去门店」在已安装高德时用 `iosamap://navi` 打开驾车导航（GCJ-02）；未安装时提示「未安装高德地图」；没有坐标时提示「暂无门店位置」
- **AND** 「电话咨询」拨打 `mobile`；没有号码时提示「暂无联系电话」，不发起拨号
- **AND** 顶栏右侧「预约记录」进入 `/wellness-cabins/appointments`
- **AND** 门店不存在或详情失败时标题为「门店详情」，展示「未找到该驿站」，可返回列表

#### Scenario: 服务项目

- **WHEN** 门店详情加载成功
- **THEN** 调用 `GET /v1/cabin/categoryList?hospitalId=`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529785605e0.md)），按 `sortId` 升序展示分类，不写死分类名称
- **AND** 选中分类后调用 `GET /v1/cabin/configList?hospitalId=&parentId=`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529266270e0.md)）
- **AND** 每个项目展示封面（`imgUrls` 第一张）、名称、价格和时长，不展示项目简介
- **AND** `payType = 1` 时价格为「免费」；分类名含「活动」时为「免费报名」；其它有价格时展示金额，有单位时带上单位
- **AND** 有时长时展示「{duration} 分钟」
- **AND** 没有分类时展示「暂无服务项目」；当前分类没有项目时分类条仍在，并展示「暂无项目」
- **AND** 「立即预约」：当前分类名称含「活动」时进入 `/wellness-cabins/activity`，否则进入 `/wellness-cabins/book`，并带上 `hospitalId`、项目配置 `configId`、`internalOnly`；有价格时带上 `price` 和 `unitName`

### Requirement: 康养小屋项目预约

系统 SHALL 在项目预约页展示预约详情，供用户选择日期和时段。点「确定预约」后不弹温馨提示，按 `sourceType` 直接提交或创建订单。

#### Scenario: 加载预约详情

- **WHEN** 从门店详情进入项目预约
- **THEN** 导航标题为「项目预约」
- **AND** 调用 `GET /v1/cabin/bookDetail?configId=`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529785607e0.md)），`configId` 为项目配置 id
- **AND** 有介绍图时顶部展示图集，高度固定 200；多于一张时每 4 秒向下一张循环，手指拖动时暂停。展示项目名称、单次时长、适用人群、禁止人群
- **AND** `applicablePeople` / `restrictedPeople` 是字典 `value`，分别用父节点 `2113189162759884800`（服务项目适用人群）、`2113189218107920384`（服务项目禁用人群）换成名称后再展示；多个值用「、」连接。缓存里还没有这两项时重新同步一次字典
- **AND** 禁止人群只展示，不拦截
- **AND** 有项目介绍时展示介绍；有预约须知时展示须知
- **AND** 项目不存在或详情失败时展示「未找到该项目」

#### Scenario: 选择日期和时段

- **WHEN** 预约详情返回 `bookDaysAhead`
- **THEN** 从今天起展示可约日期，含今天，最远为今天加 `bookDaysAhead` 天；未返回时只展示今天
- **AND** 默认选中接口返回的日期，否则选中今天，并选中当天第一个可预约时段
- **AND** 切换日期后再次调用 `GET /v1/cabin/bookDetail?configId=&date=`，`date` 为 `yyyy-MM-dd`，并改选该日第一个可预约时段
- **AND** 换日失败时停在原日期并提示错误
- **AND** 可预约时段展示「已约人数/剩人数」；剩余为空且可预约时只展示已约人数
- **AND** `bookable` 为假或剩余为 0 时展示「已约满」，不可选
- **AND** 当天没有时段时展示「暂无可预约时段」

#### Scenario: 费用和确认

- **WHEN** `sourceType = 1`，或接口未返回来源且 `payType` 不是需购买
- **THEN** 底栏与付费相同：左侧「免费」，右侧「确定预约」，不展示金额
- **WHEN** `sourceType = 2` 且可用次数大于 0
- **THEN** 展示「可用次卡」和剩余次数，并展示固定文案「优先使用次卡，本次预约将扣减 1 次」
- **WHEN** `sourceType = 3`，或未返回来源且 `payType = 2`
- **THEN** 底栏展示「确定预约」；金额优先用 `bookDetail.price`，没有时再用进入页时项目列表的 `price`
- **WHEN** 未选可预约时段就点「确定预约」
- **THEN** 提示「请选择可预约时段」
- **WHEN** 已选时段后点「确定预约」
- **THEN** 不弹出温馨提示，按来源直接处理
- **WHEN** 已选时段后点「确定预约」，且 `sourceType` 为 1 或 2，并且次卡剩余次数大于 0
- **THEN** 调用 `POST /v1/cabin/book`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/530062590e0.md)）
- **AND** 请求体带 `configId`、`reserveDate`、`sourceType`、`startTime`、`endTime`、`quantity = 1`，不带 `orderId`
- **AND** 成功后提示「已提交预约」，并进入 `/wellness-cabins/appointments`
- **AND** 失败时提示错误，停留本页，不进入预约记录
- **WHEN** 已选时段后点「确定预约」，且 `sourceType` 为 3，或次卡 `availableQuantity` 为 0
- **THEN** 本页不调用预约接口，也不进入套餐页
- **AND** 调用 `POST /v1/cabin/createReservationOrder`，请求体只有 `configId`
- **AND** 用返回的订单 id 打开 `/orders/confirm`
- **AND** `configId`、预约日期、开始时间和结束时间只放在路由参数里，确认订单页不展示
- **AND** 确认页沿用原订单结算和支付，不改套餐立即购买、购物车和订单列表支付
- **AND** 这些原订单入口不带预约参数，支付成功后不调用预约接口
- **AND** 仅当次确认页支付成功后，调用 `POST /v1/cabin/book`，`sourceType = 3`，并带 `orderId` 和本次时段
- **AND** 预约提交失败不撤销已完成的支付，支付结果页说明预约未成功

### Requirement: 康养小屋活动详情

分类名称包含「活动」时进入活动详情。页面复用预约页详情，不展示整场名额、活动规则正文、金额和单位。

#### Scenario: 活动预约

- **WHEN** 从门店项目进入活动
- **THEN** 调用 `GET /v1/cabin/bookDetail`，展示介绍、须知、日期和时段
- **AND** 不展示整场剩余名额、活动规则正文、金额和单位
- **AND** 确认后不弹温馨提示，仍按 `sourceType` 直接预约或创建预约订单

### Requirement: 康养小屋预约记录

系统 SHALL 按状态展示当前登录人的康养小屋预约。入口为门店详情顶栏「预约记录」。驿站列表不提供该入口。卡片样式与原型预约记录一致：预约日期与时段同一行，时段用主色；门店名称与「门店信息」同一行，地址在下一行。操作按钮靠右。待服务可在卡片上取消，也可进入详情取消。

#### Scenario: 列表

- **WHEN** 进入预约记录或下拉刷新
- **THEN** 导航标题为「预约记录」
- **AND** 调用 `GET /v1/cabin/appointments`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529785606e0.md)）
- **AND** Tab 为全部、待服务、服务中、已完成、已取消、已过期，默认全部
- **AND** 全部不传 `status`；其余分别传 `3`、`4`、`5`、`6`、`7`
- **AND** 卡片展示项目名称、状态、时长、预约日期、时段、门店名称和地址
- **AND** 预约日期与时段排在「预约时间」右侧同一行，时段使用主色
- **AND** 门店名称排在「门店信息」右侧，地址换行展示
- **AND** 待服务卡片右侧为「取消预约」和「查看详情」
- **AND** 服务中卡片只有「查看详情」
- **AND** 已完成、已取消、已过期卡片右侧为「再次预约」和「查看详情」
- **AND** 待服务且预约结束时间已过、日期仍是当天时，展示「超时未使用，当天可以根据门店情况沟通核销，超过当天订单失效」
- **AND** 当前 Tab 没有记录时，全部展示「暂无预约记录」，其它 Tab 展示「暂无{状态}预约」
- **AND** 失败时提示错误

#### Scenario: 列表取消

- **WHEN** 在待服务卡片点击「取消预约」并确认
- **THEN** 确认文案说明只作废本次时段，退款需到订单办理
- **AND** 确认后调用 `POST /v1/cabin/cancel`，成功后刷新列表

#### Scenario: 再次预约

- **WHEN** 点击「查看详情」
- **THEN** 进入 `/wellness-cabins/appointments/detail`，调用 `GET /v1/cabin/reservationDetail?id=`
- **AND** 待服务且有 `cancellationCode` 时展示核销码，可复制
- **AND** 待服务底部为「取消预约」，确认后调用 `POST /v1/cabin/cancel`
- **AND** 服务中不展示主按钮
- **WHEN** 记录状态为已完成、已取消或已过期，且有 `configId`
- **THEN** 「再次预约」进入 `/wellness-cabins/book`，带上 `configId` 和 `hospitalId`
- **WHEN** 没有 `configId` 但有 `hospitalId`
- **THEN** 「再次预约」进入该门店详情 `/wellness-cabins/detail`
- **WHEN** 状态为待服务或服务中
- **THEN** 卡片不展示「再次预约」

### Requirement: 康养小屋页面字段对照

对照原型 `docs/v0.1/pages/home/wellness-cabin-*.md` 与 2026-11-02 公开接口。已经能展示的字段按各页需求实现。下面只记录仍缺的展示字段，以及产品明确不做的字段。

#### Scenario: 已补齐

- **WHEN** 对照这次接口更新
- **THEN** 项目预约金额使用 `GET /v1/cabin/bookDetail` 的 `price`
- **AND** 次卡说明使用固定文案「优先使用次卡，本次预约将扣减 1 次」，不依赖接口字段
- **AND** 预约记录用 `configId` 回到原项目预约页
- **AND** 预约详情使用 `GET /v1/cabin/reservationDetail`，取消使用 `POST /v1/cabin/cancel`
- **AND** 待服务展示 `cancellationCode`；已取消展示 `cancelTime`、`cancelReason`；详情同时展示预约编号、创建时间、项目介绍、须知、适用人群、禁止人群、门店名称、地址、营业时间和电话

#### Scenario: 产品明确不做

- **WHEN** 展示活动详情
- **THEN** 不展示整场剩余名额、名额总数、活动规则正文、金额和单位
- **AND** 这些字段即使接口以后返回，本页也不展示

#### Scenario: 驿站列表和门店详情仍缺推荐标

- **WHEN** 渲染驿站列表或门店详情
- **THEN** 原型要在名称旁展示 `recommended`
- **AND** `GET /v1/cabin/list` 与 `GET /v1/cabin/detail` 的 `CabinBO` 仍没有 `recommended`
- **AND** 客户端只在响应带 `recommended = 1` 或 `true` 时展示「推荐」，当前文档下不展示

#### Scenario: 项目预约仍缺计价单位

- **WHEN** 项目预约展示付费金额
- **THEN** 金额来自 `bookDetail.price`
- **AND** `bookDetail` 没有 `unitName`
- **AND** 从门店项目进入时，单位用 `GET /v1/cabin/configList` 带入的 `unitName`；没有带入时展示「次」

#### Scenario: 预约详情字段

- **WHEN** 展示预约详情
- **THEN** 页头用 `parentName` 作为服务分类，跟在时长后面
- **AND** 项目介绍使用 `description` 富文本，介绍图在正文里，不另找图片字段
- **AND** 待服务展示 `qrCode` 和 `cancellationCode`；服务中展示 `verifyTime`；已完成展示 `verifyTime` 和 `finishTime`；已取消展示 `cancelTime`；已过期展示 `expireTime`
- **AND** 当天已过时段仍由客户端判断，只展示超时说明。详情没有单独的超时时间字段
- **AND** 响应带 `longitude`、`latitude` 时提供「导航到门店」；已安装高德才跳转，未安装提示「未安装高德地图」；还没返回坐标时不展示导航
- **AND** 再次预约优先用详情里的 `configId`，没有则用列表带入的 `configId`
