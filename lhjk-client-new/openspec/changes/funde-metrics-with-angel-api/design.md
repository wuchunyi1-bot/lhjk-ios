## Context

四个体征模块的 BLL/DAL 已按 Angel Doctor 契约落地。PL 侧现有两套 UI：

1. Funde 风格单页（趋势图 + 统计 + 近期记录）— 用户期望的 Hub 展示
2. Angel 风格多页（服务首页 / 手动 / 历史 Tab / 详情）— 录入与明细流仍有价值

产品决策：Hub 用 1，录入/历史/添加继续用 2。

## Goals / Non-Goals

**Goals**

- Funde 四页展示真实 API 数据，无 mock
- 日/周/月（或等价 period）切换触发重新请求
- 空态展示空文案 / 空图，不编造数值
- 导航保留「添加 / 历史」入口跳到已有子路由

**Non-Goals**

- 不重画 Angel 服务首页为 Hub
- 不引入 Funde 独有、后端不存在的指标假数据（如饮食页三大营养素、步数目标等，若接口无字段则隐藏该区块或显示 `--`）
- 不修改 `.xcodeproj` / Podfile

## Decisions

| 决策 | 选择 | 理由 |
|------|------|------|
| Hub 入口 VC | 恢复 Funde `*ViewController` | 产品要求保留 Funde 视觉 |
| 数据层 | 复用现有 BLL Service | 接口已对齐 Angel，避免双实现 |
| Angel 多页 | 保留代码，子路由继续注册 | 手动录入 / 历史 / 饮食添加仍需要 |
| 架构 | Funde VC + 专用 ViewModel + Service 注入 | 符合项目 PL ViewModel 规范 |
| 血压 period | Funde「日/周/月」→ API `timeType` 1 / 7 / 30 | 近似映射；无「日」精确接口时用 7 天缩量或 1 天 |
| 血糖双曲线 | 用 `getSugarHistory` + 餐次 type 拆空腹/餐后；缺餐次时退化为单曲线 | 对齐已有糖接口 |
| 体重 | `selectWeightHistoryData` 作趋势；首页最新点作当前 | 与 WeightService 一致 |
| 饮食运动 | `getSportDietListByToday`；隐藏无 API 的营养素条；运动卡用 `sport.consumeNum` | 避免 mock 营养比例 |

## Period 映射

| Funde UI | BP `timeType` | Sugar `timeType` | Weight |
|----------|---------------|------------------|--------|
| 日 | 1（若后端不支持则 7） | 1 | 当日最新 + 近 7 点或全部裁剪 |
| 周 | 7 | 7 | chart 全量按近 7 天过滤 |
| 月 | 30 | 30 | 近 30 天过滤 |

体重历史接口无 timeType，在客户端按 `dayStr` 过滤。

## Risks / Trade-offs

- Funde「动态血糖」Tab：Angel 侧无独立 CGM 接口 → 二期或与指血同源提示
- 营养素 / 步数：接口无字段 → UI 区块隐藏或 `--`，spec 明确禁止 mock 填充

## Migration Plan

1. 写本 change 规格
2. 恢复 Funde 四页 + ViewModel 绑 Service
3. 改 `HealthRoutes` Hub 路径
4. 手动把文件加回 Xcode；冒烟：Hub → 有数据 / 空态 / 进手动页

## Open Questions

- 血压「日」后端是否支持 `timeType=1`：实现时先试 1，失败回退 7
- 饮食页是否暂时保留「AI 拍照」按钮（延后功能）：保留入口，点击 Toast「即将上线」
