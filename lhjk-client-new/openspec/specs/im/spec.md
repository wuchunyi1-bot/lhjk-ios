# Instant Messaging (IM)

## Purpose

提供即时通讯能力，作为健康管理服务的沟通枢纽。健管师/医生与客户在聊天中完成服务触达、健康数据推送和咨询回复。参考 funde-im `prototype/src/` 全部 Vue 组件及 `conversations.json` / `messages.json` mock 数据模型。

> **Reference**: funde-im `prototype/src/components/ConvoList.vue`、`ConvoItem.vue`、`MessageList.vue`、`MessageBubble.vue`、`Composer.vue`、`docs/v0.1/`

---

## Data Model

### Conversation (会话)

| Field | Type | 说明 |
|-------|------|------|
| `id` | String | 会话唯一 ID，格式 `CV0001` |
| `patientCid` | String | 关联客户 ID |
| `name` | String | 客户姓名 |
| `doctorTeam` | String | 医生团队名称 |
| `tags` | [String] | 标签列表：`bmi`, `glucose`, `pressure`, `sleep`, `gut`, `uric`, `hyc` |
| `preview` | String | 最后一条消息预览 |
| `lastMessageAt` | Date | 最后消息时间 |
| `unreadCount` | Int | 未读消息数 |
| `priority` | Enum | `high` / `normal` / `low` |
| `status` | Enum | `active` / `pending` / `closed` |

### Message (消息)

| Field | Type | 说明 |
|-------|------|------|
| `id` | String | 消息唯一 ID，格式 `MSG0001` |
| `conversationId` | String | 所属会话 ID |
| `type` | Enum | `text` / `image` / `notification` / `system` / `file` |
| `sender` | Enum | `patient` / `staff` / `system` |
| `senderName` | String? | 发送者显示名称（staff 类型时使用） |
| `senderRole` | String? | 发送者角色（如"健康管理师"） |
| `avatarText` | String? | 头像文字（staff avatar 首字） |
| `content` | String | 文本内容 / 通知标题 |
| `payload` | NotificationPayload? | 健康通知卡片数据（type=notification 时） |
| `createdAt` | Date | 消息时间 |
| `recalled` | Bool | 是否已撤回 |

### NotificationPayload (健康通知卡片)

| Field | Type | 说明 |
|-------|------|------|
| `title` | String | 卡片标题（如"血糖上传通知"） |
| `icon` | String | 指标 icon key：`glucose` / `ecg` / `pressure` / `spo2` / `weight` / `sleep` |
| `accent` | String | 主题色：`coral` / `pink` / `gold` / `green` / `purple` |
| `rows` | [NotificationRow] | 键值对行数据 |
| `footnote` | String? | 底部建议文本 |

### NotificationRow

| Field | Type | 说明 |
|-------|------|------|
| `label` | String | 指标名称 |
| `value` | String | 指标值 |
| `statusText` | String? | 状态文字（如"偏高"、"需关注"） |
| `statusTone` | String? | 状态色调：`danger` / `warning` / `success` |

---

## Requirements

### Requirement: Conversation List
系统 SHALL 展示会话列表，支持按标签筛选、未读计数和优先级标识。

**实现方案**: `UITableView` + 自定义 `ConversationCell`

#### Scenario: 列表排序
- **WHEN** 用户进入消息列表页
- **THEN** 会话按 `lastMessageAt` 倒序排列，置顶会话始终在前

#### Scenario: 会话行展示
- **WHEN** ConversationCell 渲染
- **THEN** 展示：
  - 左侧圆形头像（44×44pt，显示客户姓名首字，背景色按姓名 hash 分配）
  - 客户姓名（16pt bold，`fdText`）
  - 医生团队名（12pt，`fdSubtext`）
  - 右侧最后消息时间（12pt，`fdMuted`）
  - 底部消息预览文字（14pt，`fdSubtext`，单行截断）
  - 标签 pill（圆角 999，按 tag 分配背景色）
  - 未读红点 badge（红色圆角，仅 unreadCount > 0 时显示）

#### Scenario: 优先级标识
- **WHEN** `priority` 为 `high`
- **THEN** 左侧显示 3pt 宽品牌色竖条高亮
- **WHEN** `priority` 为 `normal` / `low`
- **THEN** 无特殊标识

#### Scenario: 标签筛选
- **WHEN** 用户点击顶部标签 chip
- **THEN** 会话列表按选中标签过滤（全部 / BMI / 血糖 / 血压 / 睡眠 / 肠道 / 尿酸 / HYC），chip 切换为选中态样式（品牌色底白字）

#### Scenario: 滑动操作
- **WHEN** 用户左滑会话行
- **THEN** 显示"删除"（红色）和"置顶"（橙色）操作

#### Scenario: 空状态
- **WHEN** 无会话数据
- **THEN** 居中展示"暂无消息"空状态插画和文字

---

### Requirement: Chat / Message Detail
系统 SHALL 展示会话的完整消息流，支持文本气泡、健康通知卡片和系统消息。

**实现方案**: `UITableView` + 自定义 `MessageBubbleCell` / `NotificationCardCell` / `SystemMessageCell`

#### Scenario: 文本气泡（患者端）
- **WHEN** `sender` 为 `patient` 的文本消息
- **THEN** 右侧对齐、品牌色气泡背景（`fdPrimarySoft`）、文字 `fdText`、圆角 16pt（右下角为直角），气泡外显示时间（11pt `fdMuted`）

#### Scenario: 文本气泡（健管师端）
- **WHEN** `sender` 为 `staff` 的文本消息
- **THEN** 左侧对齐、白色气泡背景（`fdSurface`）、文字 `fdText`、圆角 16pt（左下角为直角），气泡上方显示发送者头像（36×36pt 圆形）+ 姓名 + 角色

#### Scenario: 健康通知卡片
- **WHEN** `type` 为 `notification`
- **THEN** 居中展示结构化卡片：
  - 白色圆角卡片（16pt 圆角，阴影）
  - 顶部 icon + 标题（14pt semibold）
  - 中间多行 key-value 数据（label 12pt `fdSubtext`，value 14pt `fdText`）
  - 异常值显示 status badge（绿/黄/红底对应色字）
  - 底部建议文字（12pt `fdSubtext`，浅灰背景）

#### Scenario: 系统消息
- **WHEN** `type` 为 `system`
- **THEN** 居中灰色文字（12pt `fdMuted`），无气泡

#### Scenario: 消息时间分组
- **WHEN** 相邻两条消息的 `createdAt` 间隔 > 5 分钟
- **THEN** 在中间插入时间分隔符（居中灰色文字，格式 `MM-dd HH:mm`）

#### Scenario: 滚动至底
- **WHEN** 进入聊天页或新消息到达
- **THEN** 自动滚动至最底部（若已在底部则平滑滚动，否则显示"新消息"提示按钮）

---

### Requirement: Message Composer / Input Bar
系统 SHALL 提供底部输入栏，支持文本发送和工具入口。

#### Scenario: 输入栏布局
- **WHEN** 聊天页渲染
- **THEN** 底部固定输入栏包含：
  - 左侧工具按钮（`+` icon，32×32pt）
  - 中间文本输入框（圆角 18pt，`fdBg2` 背景，placeholder "输入消息..."）
  - 右侧发送按钮（品牌色文字"发送"，15pt semibold）

#### Scenario: 键盘适配
- **WHEN** 键盘弹出
- **THEN** 输入栏跟随键盘上移，消息列表 contentInset 同步调整，保持底部消息可见

#### Scenario: 发送文本
- **WHEN** 用户输入文本并点击发送或键盘回车
- **THEN** 清空输入框，消息以 `sending` 状态追加到列表，mock 返回成功后更新为 `sent`

#### Scenario: 输入中状态
- **WHEN** 输入框为空
- **THEN** 发送按钮灰色置灰，不可点击
- **WHEN** 输入框有内容
- **THEN** 发送按钮恢复品牌色，可点击

---

### Requirement: Composer Tool Bar
系统 SHALL 支持输入栏工具入口，提供快捷操作入口。

#### Scenario: 工具面板
- **WHEN** 用户点击 `+` 按钮
- **THEN** 弹出底部工具选择面板（半屏弹层），展示工具入口网格（13 个入口，3 列布局）：
  | 入口 | icon SF Symbol | 说明 |
  |------|---------------|------|
  | 图片 | `photo` | 从相册选择 |
  | 拍照 | `camera` | 拍摄照片 |
  | 健康档案 | `doc.text` | 发送健康档案卡片 |
  | 随访计划 | `calendar.badge.plus` | 创建随访计划 |
  | 服务套餐 | `giftcard` | 推荐服务套餐 |
  | 用药提醒 | `pills` | 发送用药提醒 |
  | 饮食建议 | `fork.knife` | 发送饮食建议 |
  | 运动处方 | `figure.walk` | 发送运动建议 |
  | 预约挂号 | `calendar.badge.clock` | 预约挂号 |
  | 健康问卷 | `checklist` | 发送问卷 |
  | 在线问诊 | `stethoscope` | 发起在线问诊 |
  | 知识库 | `book` | 发送健康知识 |
  | 转派工单 | `arrow.triangle.swap` | 创建工单转派 |

> **V1.0 实现**: 工具入口以 UI 占位为主，点击后 toast 提示功能名。后续版本接入真实能力。

---

### Requirement: Design Tokens
所有 UI 颜色 SHALL 通过 `UIColor.fd*` Token 引用。

#### Scenario: 消息气泡色
| 角色 | 气泡背景 | 文字 |
|------|---------|------|
| Patient（右侧） | `fdPrimarySoft` (#FFF3EE) | `fdText` |
| Staff（左侧） | `fdSurface` (white) | `fdText` |

#### Scenario: 通知卡片 accent 映射
| accent | 主色 | 浅底色 |
|--------|------|--------|
| `coral` | `#FF7A50` (fdPrimary) | `#FFF3EE` |
| `pink` | `#E5564B` (fdDanger) | `#FCE9E6` |
| `gold` | `#F5A524` (fdWarning) | `#FFF3DC` |
| `green` | `#2DB983` (fdSuccess) | `#E6F7EF` |
| `purple` | `#7B5E9F` | `#F3EFFC` |

#### Scenario: 标签 chip 色
| tag | 背景色 | 文字色 |
|-----|--------|--------|
| `bmi` | `#FFF3EE` | `#FF7A50` |
| `glucose` | `#E6F7EF` | `#2DB983` |
| `pressure` | `#FFF3DC` | `#F5A524` |
| `sleep` | `#F3EFFC` | `#7B5E9F` |
| `gut` | `#EBF1FA` | `#5C8DC9` |
| `uric` | `#FCE9E6` | `#E5564B` |
| `hyc` | `#FFE9DF` | `#D6602B` |

---

## Component Inventory

| Component | Type | funde ref | 说明 |
|-----------|------|-----------|------|
| `ConversationCell` | UITableViewCell | `ConvoItem.vue` | 会话行（头像 + 姓名 + 预览 + 标签 + 未读） |
| `ConversationListViewController` | UIViewController | `ConvoList.vue` | 会话列表页 + 标签筛选 chips |
| `MessageBubbleCell` | UITableViewCell | `MessageBubble.vue` | 文本气泡（患者/健管师双样式） |
| `NotificationCardCell` | UITableViewCell | `MessageBubble.vue` (notification) | 健康通知卡片 |
| `SystemMessageCell` | UITableViewCell | `MessageList.vue` | 系统消息行 |
| `ComposerView` | UIView | `Composer.vue` | 底部输入栏（工具按钮 + 输入框 + 发送） |
| `ComposerToolSheet` | UIViewController | `ComposerToolModal.vue` | 工具选择弹层 |
| `ChatViewController` | UIViewController | `ChatPanel.vue` + `MessageList.vue` | 聊天详情页 |

---

## States

| State | 表现 |
|-------|------|
| **默认（会话列表）** | 15 条 mock 会话，已读/未读、标签、优先级完整 |
| **标签筛选** | 切换 chip 过滤会话列表 |
| **空会话** | "暂无消息"空状态 |
| **聊天页** | 消息流（文本 + 通知卡片 + 系统消息），键盘适配 |
| **发送中** | 新消息以 `sending` 状态追加，气泡半透明 |
| **键盘弹起** | 输入栏上移，消息列表上滚 |

## Acceptance Checklist

### 会话列表
- [ ] 会话列表 15 条 mock 数据完整渲染
- [ ] 每行：头像（首字圆形）、姓名、团队名、预览、时间、标签 pill、未读 badge
- [ ] 8 个标签 chips 可点击切换筛选
- [ ] 高优先级会话左侧竖条高亮
- [ ] 左滑显示删除 / 置顶操作
- [ ] 空状态展示

### 聊天页
- [ ] 消息流渲染：文本气泡（患者右侧 + 健管师左侧）、通知卡片（居中）、系统消息（居中灰色）
- [ ] 患者气泡品牌色软底 + 右下角直角
- [ ] 健管师气泡白底 + 左下角直角 + 头像/姓名/角色
- [ ] 时间分组分隔线（间隔 > 5 分钟显示）
- [ ] 健康通知卡片完整渲染（icon + 标题 + KV 行 + status badge + 建议）
- [ ] 进入页面自动滚到底部

### 输入栏
- [ ] 底部固定：工具按钮 + 输入框 + 发送按钮
- [ ] 空文本时发送按钮置灰
- [ ] 键盘弹起时输入栏跟随，消息列表同步上滚
- [ ] `+` 按钮弹出工具选择面板（13 个入口，3 列）
- [ ] 工具入口点击 toast 提示功能名

### 通用
- [ ] 所有颜色通过 `UIColor.fd*` Token 引用
- [ ] 导航栏正常显示（Title 为客户姓名）
