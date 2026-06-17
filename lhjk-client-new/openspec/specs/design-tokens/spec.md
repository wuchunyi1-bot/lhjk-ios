# Design Tokens

## Purpose

定义整个 iOS 项目的设计规范（Design Token），包括颜色体系和字体体系。所有 UI 代码必须通过 Token 引用颜色和字体，禁止直接使用硬编码的 hex 值或魔法数字。

## Color System

颜色 Token 来源于 funde-client 的 `prototype/src/styles/tokens.css`，实现在 `Other/Common/Extensions/UIColor/UIColor+Theme.swift`。

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

当前字体系统使用系统字体 `UIFont.systemFont(ofSize:weight:)`，以下为实际代码中的使用规范总结。

### Requirement: Font Sizes — 字号层级

| 用途 | 字号 | 字重 | 示例场景 |
|------|------|------|---------|
| 超大数值 | 38pt | `.bold` | Hero 区域核心指标数字 |
| 大标题 | 24pt | `.bold` | 健康指标卡片数值 |
| 页面标题 | 22pt | `.semibold` | Hero 区域问候语 |
| 次级大数值 | 18pt | `.semibold` | 列表中的指标数值 |
| 模块标题 | 17pt | `.bold` | 服务 banner 标题 |
| 主按钮文字 | 15pt | `.semibold` | 主要操作按钮 |
| 品牌名 | 15pt | `.bold` | 品牌标识文字 |
| 正文/列表项 | 14pt | `.semibold` / `.medium` | 任务卡片标题、文章标题 |
| 描述文字 | 13pt | `.regular` | 健康指标描述 |
| 辅助信息 | 12pt | `.regular` / `.bold` | 积分、标签 |
| 小标签 | 11pt | `.regular` / `.semibold` | 文章分类 tag、设备名 |
| 图表标注 | 10pt | `.regular` / `.semibold` | 图表轴标签、badge 文字 |
| 极小文字 | 9pt | `.regular` / `.semibold` | 单位、角标 |

#### Scenario: 标题文字
- **WHEN** 设置页面或区块标题
- **THEN** 使用 22pt `.semibold`（页面级）或 17pt `.bold`（模块级）或 14pt `.semibold`（卡片级）

#### Scenario: 正文文字
- **WHEN** 设置正文或描述文字
- **THEN** 使用 14pt `.regular` 或 13pt `.regular`

#### Scenario: 辅助/元信息文字
- **WHEN** 设置辅助说明、时间戳、来源标注
- **THEN** 使用 11-12pt `.regular`，颜色使用 `fdSubtext` 或 `fdMuted`

#### Scenario: 按钮文字
- **WHEN** 设置按钮标题
- **THEN** 主要按钮使用 15pt `.semibold`

---

### Requirement: Font Usage Rules — 字体使用规则

#### Scenario: 使用系统字体
- **WHEN** 设置字体
- **THEN** 使用 `UIFont.systemFont(ofSize:weight:)`，当前项目不引入自定义字体

#### Scenario: 字号一致性
- **WHEN** 相同语义层级的文字
- **THEN** 必须使用相同的字号和字重，保持全局统一

#### Scenario: 颜色与字体搭配
- **WHEN** 设置文字样式
- **THEN** 文字颜色必须使用颜色 Token（`fdText` / `fdText2` / `fdSubtext` / `fdMuted`），与字号共同构成视觉层级

---

## Implementation Reference

| 规范 | 实现文件 |
|------|---------|
| 颜色 Token 定义 | `Other/Common/Extensions/UIColor/UIColor+Theme.swift` |
| 颜色 Hex 工具 | `Other/Common/Extensions/UIColor/UIColor+Hex.swift` |
| DGCharts 图表样式 | `Other/Common/Extensions/DGCharts/DGCharts+Theme.swift` |
| 按钮预设样式 | `Other/Common/Extensions/UIButton/UIButton+Funde.swift` |
