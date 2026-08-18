# IM 消息类型 · 卡片样式 · Model↔样式对照

> 以 **当前 iOS 代码** 为准。监测上传格式见 `monitor-im-card-frontend-handoff.md` v0.4；实现说明见 [`message-cards.md`](./message-cards.md)。

---

## 0. 总览：两套「卡片」不要混

| 体系 | 来源 | 进真实会话？ | 样式入口 |
|------|------|-------------|----------|
| **A. 融云生产消息** | ObjectName + 自定义 `RCMessageContent` | ✅ | 各 Bubble / `SysNotifyCell` |
| **B. funde-client 原型卡** | 本地 `MessageType` + `ServiceCard` 等 | ❌ | `ServiceCardCell` 等 |

---

## 1. 生产消息：Type → Model → Cell

### 1.0 Cell 族谱

```
生产消息 Cell
├─ A. 气泡族：Text / Image / Voice
├─ B. 媒体族：File（F1/F2/F3）/ Video
├─ C. 协议卡：SysNotifyCell
│     AD:SysNotify → monitorReminder | monitor | sysNotify(C-sys)
│     AD:Vip / ServiceComment / CheckUserMsg
└─ D. 居中提示：CenteredTipCell（撤回）
```

### 1.1 Type → Model → Cell

| MessageType | ObjectName | Content Model | Cell | 内样式 |
|-------------|------------|---------------|------|--------|
| `text` | `RC:TxtMsg` | `text` / `reply` | `TextBubbleCell` | 文本 |
| `image` | `RC:ImgMsg` | `imagePath` | `ImageBubbleCell` | 图片 |
| `voice` | `RC:HQVCMsg` | path + 时长 | `VoiceBubbleCell` | 语音 |
| `file` | `AD:FileMsg` | `fileContent` | `FileBubbleCell` | F1/F2/F3 |
| `video` | `AD:VideoMsg` | `videoContent` | `VideoBubbleCell` | 视频 |
| `sysNotify` | `AD:SysNotify` | `sysNotifyContent` → Resolved | `SysNotifyCell` | **C-monitorReminder / C-monitor / C-sys** |
| `vip` | `AD:Vip` | `vipContent` | `SysNotifyCell` | C-vip |
| `serviceComment` | `AD:ServiceComment` | … | `SysNotifyCell` | C-comment |
| `checkUserMsg` | `AD:CheckUserMsg` | … | `SysNotifyCell` | C-check |
| `recall` | `RC:RcNtf` | `text` | `CenteredTipCell` | 撤回 |

### 1.2 FileBubbleCell

| 样式 | `fileSuffix` | 摘要 |
|------|--------------|------|
| F1 | `mp3` | `[音频]` |
| F2 | `richText` | `[团队知识]` |
| F3 | 其它 | `[文件]` |

### 1.3 SysNotifyCell（handoff 后）

#### AD:SysNotify — 3 态

| 样式类 | variant | 条件 | UI |
|--------|---------|------|-----|
| **C-monitorReminder** | `monitorReminder` | `extra.type == "realTime"` | 提醒卡：圆标 + title + tag + **content** + rows + **去完成**；可点 |
| **C-monitor** | `monitor` | rows 非空（且非 realTime） | 录入成功卡：圆标 + title + tag + KV/结果/表；不读 content；不可点 |
| **C-sys** | `sysNotify` | 其它 | title + content；可选封面 |

详见 [`message-cards.md`](./message-cards.md)。

#### 其它 ObjectName

| 样式类 | variant | UI |
|--------|---------|-----|
| C-vip | `vip` | 无封面，content 分行 |
| C-comment | `serviceComment` | 只读星级 |
| C-check | `checkUser` | title + 正文 |

#### 判定

```
AD:SysNotify + extra.type=realTime → monitorReminder
AD:SysNotify + rows 非空           → monitor
AD:SysNotify 其它                  → sysNotify（C-sys）
AD:Vip / ServiceComment / CheckUserMsg → 各自 variant
```

实时提醒可点（未完成）；录入成功协议卡不可点。

---

## 2. Model 字段

| 字段 | 用途 |
|------|------|
| `sysNotifyContent` 等 | 四种协议 Content |
| 顶层 `messageType` | 协议卡整型类型（安卓字段；如监测上传为 `2`）。与 `extra.type`（如 `warning` / `realTime`）不是同一字段 |
| Resolved.`monitorRows` | 新监测卡行 |
| Resolved.`dataSourceTag` / `monitorType` | tag / 图标 |
| `lastMsgDisplayContent` | 会话列表摘要 |

展示统一：`IMCardResolver.resolve` → `IMCardResolved` → `SysNotifyCell`。
