## ADDED Requirements

### Requirement: 选择服务机构页

系统 SHALL 提供对齐 funde-client `InstitutionSelectView` 的选择服务机构页，供服务模块套餐列表切换机构使用。

#### Scenario: 页面结构

- **WHEN** 用户进入 `/services/institution`
- **THEN** 导航标题为「选择服务机构」
- **AND** 顶部展示「当前定位」条（定位中 / 地址文案）与「重新定位」
- **AND** 展示搜索框，placeholder 为「搜索机构名称或地址」
- **AND** 列表展示机构名称、机构类型标签、完整地址（`fullAddress`）；**不展示**距离字段
- **AND** 当前选中项高亮并显示勾选

#### Scenario: 搜索与分页

- **WHEN** 用户输入关键词或进入页面
- **THEN** 调用 `GET /v1/hospital/searchPage`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/488248475e0)）
- **AND** Query 可含：`keyword`、`longitude`、`latitude`、`pageNum`、`pageSize`
- **AND** 有定位时传入坐标；无定位时不传经纬度，按接口默认排序
- **AND** 搜索无结果展示「未找到匹配机构」

#### Scenario: 坐标系

- **WHEN** 向 searchPage 上报当前定位
- **THEN** 经纬度 MUST 为**腾讯地图坐标系**（文档虽写高德，后端按腾讯存取）
- **AND** 设备/`CLLocation` 按高德同系 GCJ-02 处理后，经 `MapCoordinateConverter.gaodeToTencent` 再上传
- **WHEN** 需要将接口返回的医院坐标与设备定位对齐
- **THEN** 使用 `MapCoordinateConverter.tencentToGaode`

#### Scenario: 选中回写（服务模块）

- **WHEN** `source=services` 且用户点击某机构
- **THEN** 将机构 id/名称/类型/地址写入服务模块选中态（UserDefaults）
- **AND** 返回上一页；套餐列表刷新机构信息条、业务分类与套餐

#### Scenario: hospitalType 文案

- **WHEN** `hospitalType` 为 1 / 2 / 3
- **THEN** 分别展示「医院」/「社康」/「平台」

### Requirement: 服务模块机构选中态

系统 SHALL 持久化当前服务机构，供套餐列表、搜索、详情等接口的 `hospitalId` 使用。

#### Scenario: 优先级

- **WHEN** 解析 API `hospitalId`
- **THEN** 优先：服务模块已选机构 id → 用户 loginUserInfo.hospitalId → 临时常量
- **AND** 禁止把 mock 非数字 id 传入 API

#### Scenario: 登出清空

- **WHEN** 用户退出登录或注销账号成功并清理本地会话
- **THEN** 系统 SHALL 调用 `InstitutionSelectionStore.clear()`，删除 UserDefaults 中的已选机构
- **AND** 清理顺序与 `ServiceHubCacheService.clear()` 同级（在 IM clear 之后、断融云 / UserManager.clear 之前或紧邻 Hub clear）
- **AND** 再次登录进入「德系 → 选择套餐」时，不得沿用上一账号选中的医疗机构

## ADDED Requirements (location)

### Requirement: 高德与腾讯经纬度互转

`DAL/Location` SHALL 提供高德坐标系与腾讯地图坐标系互转方法，供医院搜索等接口使用。

#### Scenario: 互转 API

- **WHEN** 调用 `MapCoordinateConverter.gaodeToTencent`
- **THEN** 返回腾讯坐标系下的 `CLLocationCoordinate2D`
- **WHEN** 调用 `MapCoordinateConverter.tencentToGaode`
- **THEN** 返回高德（GCJ-02 同系）坐标系下的 `CLLocationCoordinate2D`

#### Scenario: 单次定位

- **WHEN** 选择机构页请求定位
- **THEN** 通过 `LocationManager` 按需授权并单次定位
- **AND** 可得到坐标与逆地理展示文案；失败时提示可手动搜索，列表仍可加载
