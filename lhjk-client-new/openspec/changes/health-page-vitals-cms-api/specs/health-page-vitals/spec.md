# health-page-vitals Specification

## Purpose

健康 Tab Hub「体征监测」与下方快捷入口接入 CMS / 监测卡片 API；「编辑卡片」读写用户监测卡片配置。评分卡、档案卡不在本规格范围。

## Requirements

### Requirement: CMS 配置加载

系统 SHALL 使用 `GET /v1/healthPage/getCmsConfig` 拉取健康页 CMS，Query 必须包含合法数字串 `hospitalId` 与 `code=column_health`。

#### Scenario: 成功返回快捷入口与卡片元数据

- **WHEN** 请求成功且 `data` 含 `quickEntryList` / `monitorCardMeta`
- **THEN** 快捷入口按 `sortId` 升序展示；卡片元数据可用于空壳与编辑页卡池

#### Scenario: hospitalId 非法

- **WHEN** 无法解析为纯数字 `hospitalId`
- **THEN** 不发起 CMS / 卡片列表请求；体征区与快捷入口为空（评分 / 档案仍可本地展示）

### Requirement: 监测卡片列表与空壳回退

系统 SHALL 使用 `GET /v1/monitorHealth/getMonitorCardList`（同 Query）获取用户当前展示卡片及监测值，并与 CMS 合并。

#### Scenario: 列表非空

- **WHEN** `getMonitorCardList` 返回非空数组
- **THEN** Hub 体征区按列表顺序渲染卡片；展示 `monitorData` 解析出的数值、单位与 `result`/`resultType` 状态；图标优先 `iconUrl`；卡片背景优先 `backgroundUrl`

#### Scenario: 列表空或失败

- **WHEN** 列表为空或请求失败，且 CMS `monitorCardMeta` 可用
- **THEN** Hub 按 meta 渲染空壳，数值为 `--`；背景使用本地 `metric_*` 资源（meta 无 backgroundUrl）

#### Scenario: 两者皆无

- **WHEN** 列表空/失败且无可用 meta
- **THEN** 体征监测 section 不展示（或空列表）

### Requirement: 体征卡片背景图优先级

系统 SHALL 按以下优先级渲染体征监测卡片背景（水印铺满卡片）：

1. `getMonitorCardList` 单项的 `backgroundUrl`（非空合法 URL）— 网络图（Kingfisher）
2. 否则按 `metricKey` 映射本地 Assets：`metric_bp` / `metric_bs` / `metric_weight` / `metric_hr` / `metric_sleep` / `metric_ecg` / `metric_fundus` / `metric_exercise` / `metric_spo2` / `metric_digestive` / `metric_temperature` 等
3. 若本地亦无对应资源，则不展示背景图（仅卡片底色）

CMS 空壳路径（仅 `monitorCardMeta`）无 `backgroundUrl`，MUST 走本地映射。

#### Scenario: 接口下发 backgroundUrl

- **WHEN** 卡片项 `backgroundUrl` 为非空 http(s) URL
- **THEN** `MetricCardCell` 用该 URL 加载背景；加载失败时 SHOULD 回退到本地 `metric_*`（若有）

#### Scenario: backgroundUrl 缺失或空白

- **WHEN** `backgroundUrl` 为 nil、空串或仅空白
- **THEN** 使用本地 `metric_*` 水印；无本地图则背景为空

### Requirement: 快捷入口仅来自 CMS

系统 SHALL 仅使用 CMS `quickEntryList` 驱动 Hub 下方快捷入口；禁止硬编码入口列表。

#### Scenario: 快捷入口为空

- **WHEN** `quickEntryList` 为空或缺失
- **THEN** 隐藏快捷入口 section

#### Scenario: 点击跳转

- **WHEN** 用户点击快捷入口
- **THEN** 使用 `quickEntryList[].pageUrl`（`FundeH5:` / `FundeApp:`）经 `FundePageURL` 打开

- **WHEN** 用户点击体征卡片且该项 `pageUrl` 为 `FundeH5:` 或已注册的 `FundeApp:`
- **THEN** 经 `FundePageURL.open` 打开（`FundeH5:` 即使本地无对应 metric 也打开该 H5）

- **WHEN** 用户点击体征卡片且 `pageUrl` 为空或无法解析
- **THEN** 按 `cardType` 映射为 `/health/metrics/{key}` 并打开对应 H5

### Requirement: 编辑卡片配置

系统 SHALL 提供编辑页：查询 `GET /v1/userMonitorCardConfig/getUserMonitorCardConfig`，保存 `POST /v1/userMonitorCardConfig/saveUserMonitorCardConfig`。

#### Scenario: 进入编辑页

- **WHEN** Hub 点击「编辑卡片」或路由 `/health/metrics/edit`（及兼容 `/health/metrics`）
- **THEN** 打开 `MetricCardEditViewController`，展示当前可见卡片与可选卡池
- **AND** MUST NOT 因张数将已显示卡片截断进隐藏区

#### Scenario: 无可见张数上限

- **WHEN** 用户从隐藏区将卡片加入显示区
- **THEN** 系统允许加入，不以张数上限拒绝

#### Scenario: 保存

- **WHEN** 用户确认保存
- **THEN** Body 提交 `hospitalId`、`code=column_health`、`addCardVOList`（含 `cardType`、可选 `cardName`、`sortId` 从 0 递增）；不提交 `hiddenCardVOList`；成功后返回 Hub 并刷新体征区

#### Scenario: 返回未保存

- **WHEN** 用户有未保存修改并返回
- **THEN** 弹出确认；确认丢弃后返回，取消则留在编辑页

### Requirement: cardType 映射

系统 SHALL 按天使枚举识别卡片类型：`2` 血压、`3` 血糖、`4` 体温、`5` 体重、`10` 饮食运动、`14` 血脂。

#### Scenario: 未知 cardType

- **WHEN** `cardType` 不在已知集合
- **THEN** 该卡片不进入 Hub 展示映射（或跳过），不影响其它卡片

### Requirement: 饮食运动卡（cardType = 10）

系统 SHALL 在 Hub 体征网格以独立布局渲染饮食运动卡（Figma 3543:3425）：图标 + 标题「饮食运动」+ 状态徽标 + 三列热量 + 时间；不得用单值+单位布局替代。

热量数字只展示整数（向 0 截断，不四舍五入）。「还可摄入」展示值下限为 0，不出现负数。

字段映射：

| 展示 | 数据来源 |
|------|----------|
| 今日摄入 | `dietSportData.intake`（否则 `calculateCaloricVo.intake`） |
| 今日消耗 | `dietSportData.sport.consumeNum` |
| 还可摄入 | `dietSportData.remainingIntake`，`< 0` 时展示 `0` |
| 推荐摄入 | `calculateCaloricVo.finalIntake`（否则 `totalCalories`） |

圆环进度：

```
ratio = remaining / recommended     // remaining、recommended 同上
ratio = clamp(ratio, 0, 1)          // >1 取 1，<0 取 0
progress = 1 - ratio
```

推荐摄入 `<= 0` 时 `progress = 0`（环全灰、无进度弧）。进度弧从 12 点起沿**逆时针**填充。线宽按设计稿 52pt 直径、3pt 描边随卡片缩放。

标题与三列之间 MUST 留出间距，标题垂直方向压缩优先级为 required，避免「饮食运动」底部被三列盖住。

#### Scenario: 还可摄入为正且小于推荐

- **WHEN** remaining=279、recommended=627
- **THEN** ratio≈0.445，圆环进度≈0.555；中心数字展示 `279`

#### Scenario: 还可摄入为 0 或负数

- **WHEN** remainingIntake ≤ 0
- **THEN** 中心数字展示 `0`；ratio 钳为 0；圆环画满（progress=1）

#### Scenario: 还可摄入大于推荐

- **WHEN** remaining / recommended > 1
- **THEN** ratio 取 1；圆环为空（progress=0）

#### Scenario: 无推荐热量

- **WHEN** finalIntake 与 totalCalories 均缺失或为 0
- **THEN** 圆环全灰（progress=0）；三列数字仍按整数规则展示

### Requirement: 血脂卡（cardType = 14）

系统 SHALL 在 Hub 体征网格以独立 2×2 布局渲染血脂卡：图标 + 标题「血脂」+ 状态徽标 + TC / TG / HDL / LDL + 时间；不得用单值+单位布局替代。卡片不展示 `mmol/L` 单位。时间只展示到日期（今天 / 昨天 / `MM/dd`），不带时分。

字段映射：

| 展示 | 数据来源 |
|------|----------|
| TC | `monitorData.totalCholesterol` |
| TG | `monitorData.triglycerides` |
| HDL | `monitorData.highDensityLipoprotein` |
| LDL | `monitorData.lowDensityLipoprotein` |

无对应字段时该项展示 `--`。四项均无数据时展示「去记录」。

徽标：

- `abnormalCount > 0` → 「N项异常」（warning）
- 否则有数据时展示 `result`，缺省「正常」（success）

图标优先 `iconUrl`；背景优先 `backgroundUrl`。点击合法 `pageUrl`（如 `FundeH5:/blood-lipid`）经 `FundePageURL.open` 打开。

#### Scenario: 四项齐全且无异常

- **WHEN** `totalCholesterol=4.8`、`triglycerides=1.3`、`highDensityLipoprotein=1.4`、`lowDensityLipoprotein=2.5`，`abnormalCount=0`，`result=正常`
- **THEN** 卡片展示四项数值，徽标为绿色「正常」

#### Scenario: 多项异常

- **WHEN** `abnormalCount=2`
- **THEN** 徽标展示「2项异常」（warning）

### Requirement: 柔性字段解码

系统 SHALL 兼容后端将 `monitorTime`、数值 id、`sortId` 等以字符串下发的情况，解码为 Int/Int64 而不导致整包失败。

#### Scenario: monitorTime 为字符串时间戳

- **WHEN** JSON 中 `monitorTime` 为字符串数字
- **THEN** 成功解码为 `Int64`，卡片列表可用

### Requirement: 分层与依赖

系统 SHALL 遵守 PL → BLL → DAL：VC/VM 只调用 `HealthPageService`；网络经 `APIManager`；依赖经 `AppContainer.shared.healthPageService` 注入。

#### Scenario: ViewModel 注入

- **WHEN** 创建 `HealthViewModel` / `MetricCardEditViewModel`
- **THEN** 默认注入 `AppContainer.shared.healthPageService`，可测时可替换

## API Reference

Base：`{gateway}/mobile` + path。Apifox 只读文档链接见 proposal。

| Method | Path | 用途 |
|--------|------|------|
| GET | `/v1/healthPage/getCmsConfig` | 健康页 CMS |
| GET | `/v1/monitorHealth/getMonitorCardList` | 用户监测卡片列表 |
| GET | `/v1/userMonitorCardConfig/getUserMonitorCardConfig` | 用户卡片配置 |
| POST | `/v1/userMonitorCardConfig/saveUserMonitorCardConfig` | 保存用户卡片配置 |

共用 Query/Body 字段：`hospitalId`（数字串）、`code`（固定 `column_health`）。

`getMonitorCardList` 单项额外字段：`backgroundUrl`（卡片背景图 URL，可选）。

保存 Body 额外：`addCardVOList: [{ cardType, cardName?, sortId }]`。
