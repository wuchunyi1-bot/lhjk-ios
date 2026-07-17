## Context

funde-client 选择服务机构页（`InstitutionSelectView.vue` / `auth-profile-setup-institution.page.yaml`）复用于：

1. 完善个人信息「所属机构」
2. 服务模块套餐列表「切换机构」

本变更优先打通 **服务模块切换机构** 主路径，页面结构与交互对齐 funde；数据源改为真实接口 `GET /v1/hospital/searchPage`。

坐标系约束（产品确认）：

- Apifox 文档写「高德 GCJ-02」
- **后端实际按腾讯地图坐标系**存取医院坐标与查询入参
- iOS `CLLocation` 在国内通常为 GCJ-02（与高德同系），上报 searchPage 前须转为腾讯坐标；展示医院坐标时如需与设备定位对齐，则腾讯 → 高德

## Goals / Non-Goals

**Goals:**

- 选择服务机构页：定位条、搜索、列表、空态、选中回写
- searchPage 分页拉取；有定位时后端按距离排序（传腾讯经纬度）
- 选中机构持久化，列表页 hospitalId 使用选中值
- DAL 提供高德 ⇄ 腾讯互转

**Non-Goals:**

- 完善个人信息流程完整联调（页面可复用，本变更不强制改 onboarding）
- 地图选点 / 第三方地图 SDK
- 机构详情页

## Decisions

1. **路由**：`/services/institution`，params：`selectedId`（可选）、`source=services`
2. **持久化 key**：`lhjk.services.selectedInstitution.v1`（UserDefaults，Codable）
3. **HospitalService（BLL）**：封装 searchPage；经纬度入参由调用方传入已转腾讯的字符串
4. **坐标互转**：`MapCoordinateConverter` 放在 `DAL/Location/`，与 `LocationManager` 并列
5. **列表卡片距离**：选择页机构卡片 **不展示**距离文案（对齐 funde）；距离仅用于服务端排序
6. **hospitalType**：1 医院 / 2 社康 / 3 平台 → 展示文案

## Risks

| Risk | Mitigation |
|------|------------|
| 分页字段中英不一致 | Decoder 兼容 `list`/`数据集合` 等 |
| 坐标互转公式与后端不一致 | 公式集中在 Converter；与后端联调时单点调整 |
| 无定位 | 不传 lat/lng，按接口默认排序 |
