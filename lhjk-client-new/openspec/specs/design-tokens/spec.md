# Design Tokens

## Purpose

定义整个 iOS 项目的设计规范（Design Token），包括颜色体系和字体体系。所有 UI 代码必须通过 Token 引用颜色和字体，禁止直接使用硬编码的 hex 值或魔法数字。

## Color System

颜色 Token 来源于 funde-client 的 `prototype/src/styles/tokens.css`，实现在 `Other/Common/Extensions/UIColor/UIColor+Theme.swift`。
字体 Token 来源于同一 tokens.css 和 `docs/design/design-system.md`，实现在 `Other/Common/Extensions/UIFont/UIFont+Funde.swift`。

所有颜色使用 `fd` 前缀（funde 缩写），通过 `UIColor` 扩展暴露。

### Requirement: Brand Palette — 品牌色

系统 SHALL 使用以下品牌色 Token：

| Token | 色值 | 用途 |
|-------|------|------|
| `fdPrimary` | `#FF7A50` | 主品牌色 · 暖橙 — 主按钮、选中态、强调元素 |
| `fdPrimaryDeep` | `#E55A2E` | 按下 / hover 态 |
| `fdPrimarySoft` | `#FFF3EE` | 浅橙背景 — chip、badge 背景 |
| `fdPrimaryEdge` | `#FFD9C7` | 主色描边 / 分割线 |

#### Scenario: 主按钮
- **WHEN** 创建主要操作按钮
- **THEN** 背景色使用 `fdPrimary`，按下态使用 `fdPrimaryDeep`

#### Scenario: 标签/Badge
- **WHEN** 创建品牌色标签或徽章
- **THEN** 背景色使用 `fdPrimarySoft`，文字色使用 `fdPrimary`

---

### Requirement: Semantic Colors — 语义色

系统 SHALL 使用以下语义色 Token 表示状态信息：

| Token | 色值 | 用途 |
|-------|------|------|
| `fdSuccess` | `#2DB983` | 正常 / 绿色 |
| `fdSuccessSoft` | `#E6F7EF` | 绿色浅背景 |
| `fdWarning` | `#F5A524` | 需关注 / 黄色 |
| `fdWarningSoft` | `#FFF3DC` | 黄色浅背景 |
| `fdDanger` | `#E5564B` | 危险 / 红橙 |
| `fdDangerSoft` | `#FCE9E6` | 红色浅背景 |
| `fdInfo` | `#5C8DC9` | 信息 / 蓝色 |
| `fdInfoSoft` | `#EBF1FA` | 蓝色浅背景 |

#### Scenario: 成功状态
- **WHEN** 展示成功状态（如操作成功、数值正常）
- **THEN** 图标/文字使用 `fdSuccess`，背景块使用 `fdSuccessSoft`

#### Scenario: 警告状态
- **WHEN** 展示需关注的警告信息（如指标异常、即将过期）
- **THEN** 图标/文字使用 `fdWarning`，背景块使用 `fdWarningSoft`

#### Scenario: 危险/错误状态
- **WHEN** 展示危险或错误状态（如操作失败、数值超标）
- **THEN** 图标/文字使用 `fdDanger`，背景块使用 `fdDangerSoft`

#### Scenario: 信息提示
- **WHEN** 展示中性信息提示
- **THEN** 图标/文字使用 `fdInfo`，背景块使用 `fdInfoSoft`

---

### Requirement: Neutral Colors — 中性色

系统 SHALL 使用以下中性色 Token 构建界面层级：

**文字层级（由深到浅）:**

| Token | 色值 | 用途 |
|-------|------|------|
| `fdText` | `#1F2430` | 主文字 — 标题、正文 |
| `fdText2` | `#3D4555` | 次主文字 — 副标题 |
| `fdSubtext` | `#6B7280` | 辅助说明、标签文字 |
| `fdMuted` | `#9AA0AC` | 最弱文字 — 占位符、元信息 |

**描边:**

| Token | 色值 | 用途 |
|-------|------|------|
| `fdBorder` | `#ECE4DD` | 常规描边（暖色调） |
| `fdBorderStrong` | `#D9D0C7` | 强调描边 |

**背景面:**

| Token | 色值 | 用途 |
|-------|------|------|
| `fdSurface` | `#FFFFFF` | 卡片面 / 表层 |
| `fdSurface2` | `#FAF4EF` | 嵌套卡片面 |
| `fdBg` | `#FDF6F3` | 全局暖米底色 |
| `fdBg2` | `#F6ECE4` | 次级背景 — segment 底色等 |

#### Scenario: 文字层级
- **WHEN** 设置标签文字颜色
- **THEN** 一级标题/正文使用 `fdText`，副标题使用 `fdText2`，辅助说明使用 `fdSubtext`，占位符/时间戳使用 `fdMuted`

#### Scenario: 卡片布局
- **WHEN** 构建卡片式布局
- **THEN** 最外层卡片使用 `fdSurface` 背景，嵌套卡片使用 `fdSurface2` 背景，页面底色使用 `fdBg`

#### Scenario: 分割线与描边
- **WHEN** 需要分割线或边框
- **THEN** 常规分割线使用 `fdBorder`，需要强调的分割线使用 `fdBorderStrong`

---

### Requirement: Third-Party Brand Colors — 第三方品牌色

| Token | 色值 | 用途 |
|-------|------|------|
| `fdWechatGreen` | `#07C160` | 微信品牌绿 — 微信分享/登录入口 |

#### Scenario: 微信相关 UI
- **WHEN** 展示微信登录按钮或微信图标
- **THEN** 使用 `fdWechatGreen` 作为微信品牌色

---

### Requirement: Color Usage Rules — 颜色使用规则

系统 SHALL 遵守以下颜色使用规则：

#### Scenario: 禁止硬编码颜色
- **WHEN** 在 UI 代码中设置颜色
- **THEN** 必须使用 `fd*` Token（如 `.fdPrimary`、`.fdText`），不得直接写 hex 值或使用 `UIColor(red:green:blue:alpha:)`

#### Scenario: 新增颜色
- **WHEN** 设计稿中出现新的颜色值
- **THEN** 在 `UIColor+Theme.swift` 中新增对应的 `fd*` Token，并同步更新本 spec 文件

---

## Font System

字体系统来源于 funde-client 的 `prototype/src/styles/tokens.css` 和 `docs/design/design-system.md`，实现在 `Other/Common/Extensions/UIFont/UIFont+Funde.swift`。

### Font Stack — 字体栈

系统 SHALL 使用以下两级字体栈，通过 `UIFont` 扩展暴露：

| Token | 字体栈 | 用途 |
|-------|--------|------|
| `fdFont` | `"PingFang SC", -apple-system, "Helvetica Neue", "Segoe UI", "Microsoft YaHei", sans-serif` | 全局主字体 — 所有中文/英文正文 |
| `fdMono` | `"SF Mono", "DIN Alternate", "PingFang SC", monospace` | 等宽数字字体 — 健康指标数值、统计数字、badge 数字 |

> **规则**: 普通文字使用 `fdFont` 族，数字展示（指标值、评分、统计数据）使用 `fdMono` 族。iOS 上 `fdFont` 等价于系统字体（PingFang SC 为 iOS 中文默认），`fdMono` 使用 `SF Mono` + `.monospacedDigit` 确保数字等宽对齐。

---

### Requirement: Type Scale — 字号层级

系统 SHALL 使用以下 Token 定义字号，禁止使用魔法数字（如 `UIFont.systemFont(ofSize: 17)`）：

**标题系:**

| Token | 标准值 | 老年模式 | 字重 | 语义 |
|-------|--------|---------|------|------|
| `fdH1` | 28pt | 34pt | `.bold` | 页面大标题 |
| `fdH2` | 22pt | 26pt | `.bold` | 区块标题、Topbar 标题 |
| `fdH3` | 18pt | 22pt | `.semibold` | 小节标题、卡片标题 |

**正文系:**

| Token | 标准值 | 老年模式 | 字重 | 语义 |
|-------|--------|---------|------|------|
| `fdBody` | 15pt | 19pt | `.regular` | 正文、列表项、按钮文字 |
| `fdCaption` | 13pt | 16pt | `.regular` | 说明文字、标签、辅助信息 |
| `fdMicro` | 11pt | 14pt | `.regular` | 最小级别 — badge、角标、元信息 |

**数字系（使用 `fdMono` 字体）:**

| Token | 标准值 | 老年模式 | 字重 | 语义 |
|-------|--------|---------|------|------|
| `fdNumXL` | 56pt | 64pt | `.bold` | 超大数字 — 健康评分 |
| `fdNumL` | 36pt | 44pt | `.bold` | 大数字 — 关键指标 |
| `fdNumM` | 22pt | 26pt | `.bold` | 中数字 — 统计数值、趋势值 |

#### Scenario: 页面/区块标题
- **WHEN** 设置页面大标题（如登录页品牌标语）
- **THEN** 使用 `UIFont.fdH1`（28pt bold）
- **WHEN** 设置区块标题或二级页面 topbar 标题
- **THEN** 使用 `UIFont.fdH2`（22pt bold）
- **WHEN** 设置小节/卡片标题
- **THEN** 使用 `UIFont.fdH3`（18pt semibold）

#### Scenario: 正文与描述
- **WHEN** 设置正文或列表项主文字
- **THEN** 使用 `UIFont.fdBody`（15pt regular）
- **WHEN** 设置说明文字、辅助标签
- **THEN** 使用 `UIFont.fdCaption`（13pt regular），颜色使用 `fdSubtext` 或 `fdMuted`
- **WHEN** 设置 badge、角标、最小文字
- **THEN** 使用 `UIFont.fdMicro`（11pt regular），badge 内文字可用 `.semibold` 变体

#### Scenario: 数字展示
- **WHEN** 展示健康评分等核心大数字
- **THEN** 使用 `UIFont.fdNumXL`（56pt bold mono）
- **WHEN** 展示关键指标数值（如血压、血糖读数）
- **THEN** 使用 `UIFont.fdNumL`（36pt bold mono）或 `UIFont.fdNumM`（22pt bold mono）
- **WHEN** 指标数值需等宽对齐（如列表中的数值列）
- **THEN** 使用 `UIFont.fdMono` 字体族的对应尺寸，确保 `.monospacedDigit` 生效

#### Scenario: 按钮文字
- **WHEN** 设置按钮标题
- **THEN** 使用 `UIFont.fdBody`（15pt），字重为 `.semibold`（通过 `UIFont.fdBodySemibold`）

---

### Requirement: Font Weight Variants — 字重变体

每个字号 Token 提供 `.regular` 和 `.semibold` 两种标准变体：

| 变体 | 访问方式 | 典型场景 |
|------|---------|---------|
| Regular | `UIFont.fdBody` | 正文、描述 |
| Semibold | `UIFont.fdBodySemibold` | 列表项主文字、按钮 |
| Bold | `UIFont.fdH1` (内置 bold) | 标题、数字 |

#### Scenario: 列表行文字
- **WHEN** 设置功能列表行的主标签
- **THEN** 使用 `UIFont.fdBodySemibold`（15pt semibold）

#### Scenario: 卡片内标题
- **WHEN** 设置卡片内部的标题文字
- **THEN** 使用 `UIFont.fdH3` 或 `UIFont.fdCaptionSemibold`（13pt semibold）

---

### Requirement: Senior Mode — 老年模式

系统 SHALL 支持老年模式，所有字号 Token 自动适配放大。

#### Scenario: 激活老年模式
- **WHEN** 用户在设置中开启「大字显示与简洁操作」
- **THEN** 所有使用 `UIFont.fd*` Token 的文字自动切换为老年模式对应字号（见上表），无需修改 UI 代码

#### Scenario: 老年模式实现
- **WHEN** 实现老年模式字号切换
- **THEN** 通过 `UIFont.setSeniorMode(_:)` 全局切换，内部使用 `UIContentSizeCategory` 或自定义 flag 控制 Token 返回值

---

### Requirement: Font Usage Rules — 字体使用规则

#### Scenario: 禁止硬编码字号
- **WHEN** 在 UI 代码中设置字体
- **THEN** 必须使用 `UIFont.fd*` Token（如 `UIFont.fdBody`、`UIFont.fdH2`），不得直接使用 `UIFont.systemFont(ofSize: 14)` 等魔法数字

#### Scenario: 禁止使用非系统字体
- **WHEN** 设置字体
- **THEN** iOS 端 `fdFont`（PingFang SC）即为系统中文默认字体，`fdMono` 使用 SF Mono 系统等宽字体。无需引入自定义字体文件，使用 `UIFont.fd*` Token 即可自动匹配正确字体族

#### Scenario: 颜色与字体搭配
- **WHEN** 设置文字样式
- **THEN** 文字颜色必须使用颜色 Token（`fdText` / `fdText2` / `fdSubtext` / `fdMuted`），与字号 Token 共同构成视觉层级

#### Scenario: 数字等宽对齐
- **WHEN** 列表中数值需要纵向对齐比较（如指标列表中的读数）
- **THEN** 使用 `UIFont.fdMono` 族字体，确保数字等宽（`.monospacedDigit`）

---

## Implementation Reference

| 规范 | 实现文件 |
|------|---------|
| 颜色 Token 定义 | `Other/Common/Extensions/UIColor/UIColor+Theme.swift` |
| 颜色 Hex 工具 | `Other/Common/Extensions/UIColor/UIColor+Hex.swift` |
| 字体 Token 定义 | `Other/Common/Extensions/UIFont/UIFont+Funde.swift` |
| DGCharts 图表样式 | `Other/Common/Extensions/DGCharts/DGCharts+Theme.swift` |
| 按钮预设样式 | `Other/Common/Extensions/UIButton/UIButton+Funde.swift` |
