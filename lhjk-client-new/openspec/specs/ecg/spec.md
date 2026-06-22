# ECG

## Purpose

提供实时心电图（ECG）波形的数据缓冲与绘制能力，支持标准医学 ECG 网格、平滑滚动波形、可配置走纸速度与增益，适用于胎心监护、心电监测等医疗健康场景。

本模块替代旧版 `HeartLive` / `PointContainer`（ObjC），解决其 O(n) 位移、x 坐标错位、单例限制、网格缺失竖线、每次重绘网格等固有问题。

## Reference

- Vue 原型：`funde-client/prototype/src/views/health/metrics/EcgView.vue`
- Page Spec：`funde-client/docs/page-specs/health-metrics-ecg.page.yaml`
- Mock 数据：`funde-client/prototype/src/mock/ecg.json`
- 路由：`/health/metrics/ecg`，无底部 Tab Bar

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                    PL / BLL                           │
│  (调用 append / reset / startRendering)               │
├──────────────────────────────────────────────────────┤
│                   DAL / ECG                           │
│  ┌────────────────────┐  ┌─────────────────────────┐ │
│  │   ECGDataBuffer    │  │     ECGChartView        │ │
│  │   (环形缓冲区)      │  │     (UIView 子类)        │ │
│  │                    │  │                         │ │
│  │  • append(_:)      │  │  • buffer (注入)         │ │
│  │  • chronological   │  │  • grid (缓存 UIImage)   │ │
│  │    Points()        │  │  • waveform (CG 绘制)    │ │
│  │  • reset()         │  │  • CADisplayLink 驱动    │ │
│  │  • NSLock 线程安全  │  │  • 平滑滚动插值          │ │
│  └────────────────────┘  └─────────────────────────┘ │
│  ┌────────────────────┐                              │
│  │   ECGSimulator     │  (Demo / 开发阶段)           │
│  │   P-QRS-T 合成波形  │                              │
│  └────────────────────┘                              │
└──────────────────────────────────────────────────────┘
```

---

## Page Layout: EcgViewController

路由 `/health/metrics/ecg`，布局类型 `topbar-scroll`：顶部导航栏 + 可滚动内容 + 底部固定按钮。

```
┌──────────────────────────────────────┐
│ ← 心电监测                           │  ← UINavigationBar
├──────────────────────────────────────┤
│ 蓝牙设备状态横条 (P1, 预留)           │  ← region: bluetooth-banner
├──────────────────────────────────────┤
│ ┌──────────────────────────────────┐ │
│ │ 最新报告          本月 12 日     │ │  ← region: ecg-result-card
│ │ 窦性心律 · 正常心电图            │ │    深蓝渐变 #1a5276 → #2e86c1
│ │ 心率：76 bpm                    │ │
│ │ ┌────────────────────────────┐  │ │
│ │ │     ECG 波形图 (实时滚动)    │  │ │    简化波形预览
│ │ └────────────────────────────┘  │ │
│ └──────────────────────────────────┘ │
│                                      │
│ [日] [周] [月]                       │  ← region: period-tabs
│ ‹  04/01 – 05/17  ›                 │  ← 日期翻页导航
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ 历次测量心率趋势                  │ │  ← region: ecg-hr-chart
│ │ 05-12 ████████░░ 76 bpm 正常    │ │    横条宽度按心率/120缩放
│ │ 04-10 ████████░░ 78 bpm 正常    │ │
│ │ ...                              │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │  76       │   3     │   正常     │ │  ← region: stats-panel (NEW)
│ │ 最近心率   │ 历史测量 │ 心律状态  │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ ▎心电记录                        │ │  ← region: records-list
│ │ 本月12日 09:15                   │ │    来源标签: 蓝牙(蓝) / 手动(灰)
│ │ 正常窦性心律 76bpm    [蓝牙记录] │ │    异常结论标红
│ │ ...                              │ │
│ └──────────────────────────────────┘ │
│                                      │
├──────────────────────────────────────┤
│ [     手动输入数据     ]             │  ← region: add-cta (FIXED)
│ 背景 #ff7a50, height 52, radius 14  │    固定在屏幕底部，不随滚动
└──────────────────────────────────────┘
```

### Regions (7)

| # | Key | Component | Notes |
|---|-----|-----------|-------|
| 1 | `bluetooth-banner` | MetricBtBanner 占位 | P1，展示 ECG 设备连接状态 |
| 2 | `ecg-result-card` | 深蓝渐变卡片 | 结论 + 心率 + 简化波形图 |
| 3 | `period-tabs` | UISegmentedControl + 日期导航 | 日/周/月 + ‹ 日期范围 › |
| 4 | `ecg-hr-chart` | 历次心率条状图 | 横条宽度 = heartRate/120 × 100%，附结论标签 |
| 5 | `stats-panel` | 三项统计面板 | 最近心率(bpm) / 历史测量(次) / 心律状态 |
| 6 | `records-list` | 历史记录列表 | 时间倒序，来源标签区分蓝牙(蓝色)/手动(灰色)，异常标红 |
| 7 | `add-cta` | 固定底部按钮 | "手动输入数据"，背景 #ff7a50，height 52，跳转 /health/metrics/ecg/add |

### Business Rules

- 心电波形为简化示意展示，不代表真实医疗级诊断波形（完整医疗级波形在 "暂不做" 范围）
- 历次心率条状图横条宽度按 `heartRate / 120 bpm` 等比缩放（120 bpm 为参考最大值）
- 心律状态汇总：历史记录中所有结论均正常则显示"正常"，任一次异常则显示"异常"
- 历史记录来源标签：蓝牙记录（蓝 `#3d6fb8`）/ 手动记录（灰 `#999`）
- 异常结论（如"房颤"、"室早"）在历史记录中文字标红
- 手动录入时用户输入心率值和文字结论，不要求输入波形数据
- 底部按钮固定在屏幕底部，不跟随 ScrollView 滚动

### Out of Scope

- ECG 原始波形完整图（医疗级渲染）— 当前展示简化示意波形
- AI 心律分析结论自动生成 — 需医疗器械软件许可
- ECG 报告 PDF 导出/分享

---

## Requirements

### Requirement: Ring Buffer Data Storage
系统 SHALL 使用环形缓冲区（Ring Buffer）存储 ECG 波形数据，提供 O(1) 追加和线程安全保证。

#### Scenario: 追加数据点
- **WHEN** 新的 ECG 采样值到达
- **THEN** `ECGDataBuffer.append(_:)` 以 O(1) 时间将数据写入环形缓冲区，内部索引自增

#### Scenario: 缓冲区未满
- **WHEN** 缓冲区中数据量小于 capacity
- **THEN** `count` 每次追加后递增，不发生覆盖

#### Scenario: 缓冲区已满
- **WHEN** 缓冲区达到 capacity
- **THEN** 新数据点覆盖最旧的数据点，`count` 保持为 capacity，`head` 循环移动

#### Scenario: 按时间顺序读取
- **WHEN** 渲染层需要读取数据进行绘制
- **THEN** `chronologicalPoints()` 返回按时间顺序（旧→新）排列的数据点数组，复杂度 O(n)

#### Scenario: 线程安全并发读写
- **WHEN** 蓝牙回调线程写入数据的同时，主线程正在读取
- **THEN** NSLock 保证读写互斥，不产生数据竞争或崩溃

#### Scenario: 批量追加
- **WHEN** 一次收到多个采样点（如蓝牙数据包）
- **THEN** `append(contentsOf:)` 在单次加锁内完成批量写入

#### Scenario: 获取最新值
- **WHEN** 需要获取最近一个数据点
- **THEN** `latest()` 返回最新值（O(1)），缓冲区为空时返回 nil

#### Scenario: 获取最近 N 个值
- **WHEN** 需要获取最近 N 个数据点
- **THEN** `latest(_ n:)` 返回最近 n 个数据点（按时间顺序），请求量超过 count 时返回全部可用数据

---

### Requirement: ECG Grid Rendering
系统 SHALL 绘制标准医学 ECG 网格背景，包含横线和竖线，区分大方格和小方格。

#### Scenario: 小方格绘制
- **WHEN** 视图加载或尺寸变化
- **THEN** 以 `smallSquareSize` 为间距绘制细线网格（默认 5pt × 5pt，代表 1mm × 1mm）

#### Scenario: 大方格绘制
- **WHEN** 绘制网格线
- **THEN** 每 `squaresPerLargeSquare`（默认 5）条线使用加粗线宽，形成 5mm × 5mm 大方格

#### Scenario: 网格缓存
- **WHEN** 网格样式未变化
- **THEN** 网格渲染为 UIImage 缓存，后续 drawRect 直接贴图（O(1)），不重复绘制线条

#### Scenario: 网格缓存失效
- **WHEN** `smallSquareSize`、`squaresPerLargeSquare`、`gridLineColor`、`gridThinLineWidth`、`gridBoldLineWidth` 或 bounds 发生变化
- **THEN** 网格缓存标记失效，下一次 drawRect 重建缓存

---

### Requirement: ECG Waveform Rendering
系统 SHALL 在网格背景上绘制 ECG 波形曲线，支持平滑滚动。

#### Scenario: 波形绘制
- **WHEN** drawRect 执行
- **THEN** 从 `ECGDataBuffer.chronologicalPoints()` 读取数据，按 `verticalRange` 映射到 view 纵坐标，最旧点在左、最新点在右，以折线连接

#### Scenario: 值域映射
- **WHEN** 将数据值转换为屏幕纵坐标
- **THEN** `verticalRange.lowerBound` 映射到 view 底部，`verticalRange.upperBound` 映射到 view 顶部，越界值截断至可见范围

#### Scenario: 水平滚动（平移模式）
- **WHEN** 不断追加新数据点
- **THEN** 最新点固定在 `viewWidth - trailingMargin` 位置，老点依次向左移动，超出屏幕左侧的线段被裁剪以提升性能

#### Scenario: 不可见点裁剪
- **WHEN** 数据点的 x 坐标超出 `[-pointSpacing, viewWidth + pointSpacing]` 范围
- **THEN** 跳过该点不绘制，减少 GPU 开销

#### Scenario: 样式可变
- **WHEN** `waveformColor` 或 `waveformLineWidth` 发生变化
- **THEN** 下次渲染使用新样式绘制波形

---

### Requirement: Smooth Scrolling via CADisplayLink
系统 SHALL 使用 CADisplayLink 驱动 60fps 渲染，避免每次数据到达都触发重绘。

#### Scenario: 开始渲染
- **WHEN** 调用 `startRendering()`
- **THEN** 创建 CADisplayLink 并加入 `common` run loop mode，以屏幕刷新率触发

#### Scenario: 停止渲染
- **WHEN** 调用 `stopRendering()` 或视图被释放
- **THEN** CADisplayLink 失效并从 run loop 移除，停止消耗 CPU/GPU

#### Scenario: 无新数据时跳过绘制
- **WHEN** CADisplayLink 触发但自上次绘制后无新数据到达
- **THEN** `displayLinkFired` 中检测 `needsRedraw == false` 并直接返回，不调用 `setNeedsDisplay`

#### Scenario: 视觉滚动平滑
- **WHEN** 数据到达速率不均匀（如批量到达）
- **THEN** `visualScrollOffset` 通过指数平滑向目标滚动位置趋近，避免画面跳跃

---

### Requirement: Multi-Instance Support
系统 SHALL 支持创建多个 ECGChartView 实例，各自独立管理数据和状态。

#### Scenario: 多导联场景
- **WHEN** 需要同时展示多个 ECG 导联（如 12 导联）
- **THEN** 每个 `ECGChartView` 实例绑定独立的 `ECGDataBuffer`，互不干扰

#### Scenario: 共享缓冲区
- **WHEN** 多个视图需要展示同一数据源的不同缩放级别
- **THEN** 允许注入相同的 `ECGDataBuffer` 实例到多个 `ECGChartView`

---

### Requirement: Configurable Clinical Parameters
系统 SHALL 支持临床标准参数的可配置化。

#### Scenario: 走纸速度
- **WHEN** 设置 `paperSpeed`（mm/s）
- **THEN** 配合 `pointSpacing` 和采样率确定水平滚动速度

#### Scenario: 增益
- **WHEN** 设置 `gain`（pt/mV）
- **THEN** 配合 `smallSquareSize` 确定每 mV 对应的 point 数量

#### Scenario: 水平点间距
- **WHEN** 设置 `pointSpacing`（pt/样本）
- **THEN** 决定相邻采样点在屏幕上的水平距离

#### Scenario: 值域范围
- **WHEN** 设置 `verticalRange`
- **THEN** 所有数据值按此范围线性映射到 view 高度

---

### Requirement: EcgViewController Page Layout
系统 SHALL 按照 page-spec 定义的 7 个 region 组织心电监测页面，底部按钮固定在屏幕底部。

#### Scenario: 页面结构
- **WHEN** 进入心电监测页面
- **THEN** 顶部导航栏显示"心电监测"，内容区为 UIScrollView，底部为固定按钮，无 Tab Bar

#### Scenario: 蓝牙设备状态横条
- **WHEN** 页面加载
- **THEN** 在结论卡片上方展示蓝牙 ECG 设备连接状态（P1，当前预留占位）

#### Scenario: 最新 ECG 结论卡片
- **WHEN** 渲染结论卡片
- **THEN** 深蓝渐变背景（#1a5276 → #2e86c1），展示"最新报告"标签、测量时间、结论文字（20px 加粗白色）、心率值、简化 ECG 波形图

#### Scenario: 时段切换
- **WHEN** 用户切换日/周/月 Tab
- **THEN** 历次心率趋势和日期范围联动更新

#### Scenario: 日期翻页导航
- **WHEN** 用户点击 ‹ 或 › 箭头
- **THEN** 日期范围前后翻页，趋势图和历史记录联动更新

#### Scenario: 历次心率条状图
- **WHEN** 渲染趋势图
- **THEN** 每条记录显示日期（左，44px）、横条进度图（蓝色 #2e86c1，宽度 = heartRate/120 × 100%）、心率值（右，52px）、结论标签（绿色）

#### Scenario: 统计面板
- **WHEN** 加载数据后
- **THEN** 展示三项统计：最近心率（bpm）、历史测量次数（次）、心律状态（正常/异常），水平分隔线区分

#### Scenario: 历史记录列表
- **WHEN** 渲染记录列表
- **THEN** 按时间倒序展示每条记录：测量时间 + ECG 结论，右侧来源标签区分蓝牙（蓝 #3d6fb8 背景）和手动（灰 #999 背景），异常结论文字标红

#### Scenario: 底部固定按钮
- **WHEN** 页面显示
- **THEN** 按钮固定在屏幕底部（不随 ScrollView 滚动），背景 #ff7a50，高度 52pt，圆角 14pt，文案"手动输入数据"

#### Scenario: 底部按钮点击
- **WHEN** 用户点击"手动输入数据"
- **THEN** 跳转 `/health/metrics/ecg/add` 录入页面

---

### Requirement: State Management
系统 SHALL 支持重置和生命周期管理。

#### Scenario: 清空数据
- **WHEN** 调用 `reset()`
- **THEN** 缓冲区清空、`totalSamplesReceived` 归零、`visualScrollOffset` 归零，视图清空

#### Scenario: 资源释放
- **WHEN** `ECGChartView` 被释放
- **THEN** `deinit` 自动调用 `stopRendering()` 移除 CADisplayLink，`ECGDataBuffer` 随实例释放
