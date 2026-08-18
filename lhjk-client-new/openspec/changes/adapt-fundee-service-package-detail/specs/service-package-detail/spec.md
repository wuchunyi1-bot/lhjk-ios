## ADDED Requirements

### Requirement: 套餐详情页布局（对齐 Figma 3449:7764）

`/services/detail` 与 `/services/pkg` SHALL 展示对齐 Figma 3449:7764 的套餐配置详情。TableView 主体 MUST 按纵向顺序分为 Banner、价格与简介、权益与详情连续楼层，**不使用**吸顶 Tab，**详情图片全部完整加载不截取**。

#### Scenario: 区域一 — 顶部 Banner 轮播

- **WHEN** 用户进入套餐详情
- **THEN** 顶部展示 1:1 正方形全宽 Banner 轮播（宽度为屏幕宽度，高度与宽度 1:1，容器背景为纯黑 `#000000`）
- **AND** 图片渲染规则：图片宽度固定为屏幕宽度；若渲染高度大于容器高度，居中截取中间部分（超出截取中间）；若渲染高度小于容器高度，居中展示且上下留黑（不够上下黑）
- **AND** 轮播右下角展示页码角标（`1/5`，黑色半透明 `rgba(0,0,0,0.5)` 圆角胶囊，白色 10pt 字）
- **AND** 页面左上角展示悬浮返回按钮（黑色半透明圆角矩形，白色返回箭头）

#### Scenario: 区域二 — 价格与简介区

- **WHEN** Banner 下方渲染价格与简介
- **THEN** 价格头部：橙红色渐变卡片（`#FD383F` → `#FE8A54`），内置 `package_detail_price_bg` 购物袋暗纹与流光背景图，顶部左右圆角 20pt，展示「¥」（18pt 粗体）+ 价格（28pt 粗体）+「元起」（14pt 常规）
- **AND** **价格兜底规则**：若接口未配置价格或拿不到价格，**禁止展示「面议」**，统一展示为「¥ 0 元起」
- **AND** 简介卡片：白色带微渐变与白边框圆角卡片（`cornerRadius = 16`），展示套餐标题（20pt 粗体 `#1F2430`）、副标题简介（14pt 常规 `#6D7381`）
- **AND** 右上角展示印章角标（`recommend == 1` 为「推荐」`package_detail_stamp_recommend`，`recommend == 2` 为「热销」`package_detail_stamp_hot`），金色波浪外圈与双层金环

#### Scenario: 区域三 — 权益与详情连续楼层

- **WHEN** 用户浏览主体下半区
- **THEN** 使用独立白色圆角卡片（`cornerRadius = 16`）包裹「权益」分组与「详情」全量长图
- **AND** 顶部展示「权益」「详情」标题及「BENEFITS」半透明背景水印，右上角展示 `package_detail_benefits_illust` 礼品盒插图（`alpha = 0.4`）
- **AND** 「权益」楼层：按 `checkType` 渲染为 必选 / 单选 / 可选 卡片
  - 卡片背景为 `#FFFCF8`，边框为 1pt `#FFEEDC`，圆角 16pt
  - 卡片顶部为装饰渐变条带（`#FFF7F0` → `#FFEDDB`），居中文案两侧各带有金褐色渐变羽翼装饰（左侧 `package_detail_wing_left`，右侧 `package_detail_wing_right`），居中为「必选」「单选」「可选」（16pt 中粗体 `#A25300`）
  - 必选组：不展示勾选框，明细项直接靠左展示；不可取消
  - 单选组：左侧圆形 radio 控件（选中为 `package_detail_radio_checked` 红圈+红实心圆点，未选为灰色圆圈）；首项默认选中
  - 可选组：左侧圆角方框 checkbox 控件（选中为 `package_detail_checkbox_checked` 红底白勾，未选为灰色边框）；按 `defaultCheck` 默认选中
  - 每行展示：名称（14pt 常规 `#1F2430`，支持多行）、数量（14pt 常规 `#1F2430`，如「1项」「1次」）、单价（14pt 中粗体 `#A25300` / `#1F2430`）
  - 子项缩进 24pt，不展示控件
- **AND** 「详情」楼层：紧接权益卡片下方，将 `imageDetailsUrl1~3` 全部长图按原图宽高比自适应高度完整加载，**禁止截取/固定高度**，全部长图连续无缝展示

#### Scenario: 移除吸顶 Tab

- **WHEN** 用户上下滚动套餐详情页
- **THEN** 页面自然纵向滚动，**不得**出现任何吸顶悬浮 Tab 栏
- **AND** 权益与详情全部平铺连续展示

#### Scenario: 底部操作栏

- **WHEN** 用户查看底部固定栏
- **THEN** 左侧展示「应付」（14pt `#1F2430`）+「¥」（14pt 中粗体 `#F93838`）+ 实时已选总价（20pt 粗体 `#F93838`）
- **AND** 右侧展示「加入购物车」（112x40 胶囊按钮，白底橙框 `#FF7A50`）与「立即下单」（112x40 胶囊按钮，橙色背景 `#FF7A50`，白字）
- **AND** 底部对齐安全区域，背景纯白带有浅灰色顶部分割线

### Requirement: 列表返回套餐 id

`GET /v1/hospitalPackage/getEnabledHospitalPackagePage` 列表项 SHALL 解析商品主键 `id`，并写入 `HealthPackageItem.id`，供详情页作为 `packageId`。

#### Scenario: 推荐 / 搜索列表

- **WHEN** 列表接口返回记录含 `id`（String 或 Number）
- **THEN** `HospitalPackagePageVO.id` 解码为字符串
- **AND** `HealthPackageItem.id` 等于该值（除非 `id` 缺失）

### Requirement: 套餐详情接口

服务模块套餐详情 SHALL 调用 `GET /v1/hospitalPackage/getHospitalPackageDetail`（Query：`hospitalId`、`packageId`；Apifox 层级 `App端/商城/商城套餐相关接口`）。

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
