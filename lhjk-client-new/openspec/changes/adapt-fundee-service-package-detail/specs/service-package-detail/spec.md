## ADDED Requirements

### Requirement: 套餐详情页三段式布局

`/services/detail` 与 `/services/pkg` SHALL 展示对齐 funde-client `HealthPackageDetailView.vue` 的套餐配置详情。TableView 主体 MUST 按纵向顺序分为三个区域，**不得**用 Tab 互斥隐藏权益或详情楼层。

#### Scenario: 区域一 — 顶部 Banner

- **WHEN** 用户进入套餐详情
- **THEN** 导航标题为「套餐详情」
- **AND** 首行展示 16:9 圆角轮播（优先 `bannerList` / `packageCarousel` 图片 URL；无图时渐变占位 + 文案）
- **AND** 轮播左右边距 16pt，圆角与 funde 卡片风格一致

#### Scenario: 区域二 — 套餐简介

- **WHEN** Banner 下方渲染简介区
- **THEN** 使用白色圆角卡片（`fdSurface` + 阴影）
- **AND** 展示：可选推荐角标（橙底白字，内联于名称前）+ 套餐名称（最多 2 行）
- **AND** 展示一句话简介（`introduction` / `subtitle`，弱于标题字号）
- **AND** 参考价右对齐展示 `¥xxx 元起`（来自 `packageInfo.price` 最低参考价），**不随**用户勾选变化
- **AND** 简介区**不得**与权益区合并为同一卡片

#### Scenario: 区域三 — 权益与详情连续楼层

- **WHEN** 用户浏览主体下半区
- **THEN** 使用独立白色圆角卡片包裹 Tab + 权益 + 详情
- **AND** Tab 文案为「权益」「详情」（对齐 funde）；`detailImageURLs` 为空时**隐藏**「详情」Tab
- **AND** 「权益」楼层：按 `packageHospitalDetailList` 分组连续展示组合行；`checkType` 2→必选、1→单选、3→可选
- **AND** 「详情」楼层：紧接权益楼层下方连续展示详情长图（`imageDetailsUrl1~3`），无详情图时不展示该楼层
- **AND** 权益与详情 MUST 同时存在于滚动内容中，**禁止**切换 Tab 时移除另一楼层 cell

#### Scenario: 吸顶 Tab 与楼层定位

- **WHEN** 用户向上滚动，Tab 行到达导航栏下方
- **THEN** Tab 吸顶保持可见（浮动副本或等效实现）
- **WHEN** 用户点击「权益」Tab
- **THEN** 页面滚动定位到权益楼层顶部（首个组合分组）
- **WHEN** 用户点击「详情」Tab 且存在详情图
- **THEN** 页面滚动定位到详情图楼层顶部
- **WHEN** 用户手动滚动穿越楼层
- **THEN** Tab 激活态与当前可见楼层同步

#### Scenario: 组合规则组样式

- **WHEN** 渲染套餐权益分组
- **THEN** 仅展示规则角标（必选 / 单选 / 可选），**不展示**规格组名称与 emoji icon
- **AND** 必选组：浅红底 + 红色虚线边框；单选 / 可选组：白底 + 灰色虚线边框（三组均为虚线框）
- **AND** 每行展示：选择控件 + 商品名称｜数量单位｜单价

#### Scenario: checkType 选择控件

- **WHEN** 分组 `checkType = 2`（强制 / 必选）
- **THEN** 分组头部展示「必选」角标；控件为圆角方框 checkbox，全部默认选中（红底白勾）
- **AND** 行不可点击、不可取消选中
- **WHEN** 分组 `checkType = 1`（单选）
- **THEN** 分组头部展示「单选」角标；控件为圆形 radio；组内互斥，必须且只能选 1 项
- **AND** 默认选中：优先 `defaultCheck=1` 的项，否则选最低价项
- **AND** 选中态为红圈 + 红实心圆点
- **WHEN** 分组 `checkType = 3`（可选 / 多选）
- **THEN** 分组头部展示「可选」角标；控件为圆角方框 checkbox，可自由勾选 / 取消
- **AND** 初始选中态按各项 `defaultCheck` 初始化（`1` 选中，否则未选）
- **AND** 角标文案 MUST 为「必选 / 单选 / 可选」，不得展示「强制 / 多选」等内部枚举名

#### Scenario: 吸顶 Tab 楼层定位精度

- **WHEN** 用户点击「权益」或「详情」Tab
- **THEN** 将对应楼层锚点滚动到浮动 Tab 下方（预留浮动 Tab 高度 + 间距），定位误差控制在数 pt 内
- **AND** 计算使用锚点在 `tableView` 坐标系中的绝对位置，**不得**重复扣减 sticky 偏移
- **AND** 须计入 floors cell 的 top inset

#### Scenario: 父子子项缩进

- **WHEN** 明细行存在 `children` 子节点
- **THEN** Mapper 同时保留父行与子行（不得用子行替换父行）
- **AND** 子行标记为子类型（`isChild = true`）
- **AND** UI 子行相对父行增加左侧缩进（对齐 funde `combo-row--child`），控件与文案整体右移
- **AND** 子行仍遵循所属分组的 checkType 选择规则（必选锁定 / 单选互斥 / 多选勾选）

#### Scenario: 底部操作栏

- **WHEN** 用户查看底部固定栏
- **THEN** 左侧「应付」+ 实时总价（**当前已选商品单价之和**）
- **AND** 右侧「加入购物车」「立即下单」
- **AND** 底部栏不展示购买数量入口

### Requirement: 列表返回套餐 id

`GET /v1/hospitalPackage/getEnabledHospitalPackagePage` 列表项 SHALL 解析商品主键 `id`，并写入 `HealthPackageItem.id`，供详情页作为 `packageId`。

#### Scenario: 推荐 / 搜索列表

- **WHEN** 列表接口返回记录含 `id`（String 或 Number）
- **THEN** `HospitalPackagePageVO.id` 解码为字符串
- **AND** `HealthPackageItem.id` 等于该值（除非 `id` 缺失）

### Requirement: 套餐详情接口

服务模块套餐详情 SHALL 调用 `GET /v1/hospitalPackage/getPackageDetail`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/485486161e0)）。

#### Scenario: 请求参数

- **WHEN** 用户从推荐服务 / 搜索进入详情，且 `packageId` 为有效数字 id
- **THEN** 请求 Query：`hospitalId` + `packageId`
- **AND** `hospitalId` 暂固定为 `1372444113118564352`
- **AND** `packageId` 为列表项 `id`

#### Scenario: 响应映射

- **WHEN** 接口成功返回 `HospitalPackageDetailBO`
- **THEN** `packageInfo` → 名称 / 简介 / 参考价 / 角标 / 适用人群
- **AND** `bannerList`（及 `packageCarousel`）→ 轮播
- **AND** `packageHospitalDetailList[]` → 权益分组；`checkType`：1 单选、2 强制（必选）、3 可选（多选）
- **AND** 分组内若父节点含 `children`，映射为父行 + 缩进子行（`isChild`）
- **AND** 计费单位 `billingType`：1 天、2 月、3 次、4 件

#### Scenario: 非 API id 降级

- **WHEN** 路由 `id` 非数字（如德系原型 `dehao-m`）或详情接口失败
- **THEN** 可降级本地原型数据或展示空态 / 错误提示，**不得**把 mock id 传给详情 API

### Requirement: 入口路由

#### Scenario: 推荐服务 / 搜索

- **WHEN** 用户点击「了解详情」
- **THEN** `Router.push("/services/detail", params: ["id": pkg.id])`，其中 `pkg.id` 为列表接口商品 id
