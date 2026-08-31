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
│     AD:SysNotify → 统一卡（messageType 1/2/3）
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
| `sysNotify` | `AD:SysNotify` | `sysNotifyContent` → Resolved | `SysNotifyCell` | **统一卡（messageType 1/2/3）** |
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

- 文件大小：`fileSize` 为纯数字字节时展示为 `B` / `KB` / `MB`（如 `266886` → `260.6KB`）；已带单位则原样展示
- 点击气泡：非 `mp3` 文件 → `WebViewController` 打开 `fileUrl`（http(s) / file:// / 本地路径）；`mp3` → 走语音播放

### 1.3 SysNotifyCell

#### AD:SysNotify — 统一卡

所有 SysNotify **同一套 UI**。按顶层 `messageType` 取字段（缺省 1）；**不再**用 `extra.type == realTime` / `rows` 拆三态。

| `messageType` | 字段 | UI |
|---------------|------|-----|
| **1** | title + content + imageUrl | 圆标 + 标题 + 可选正文 + 可选 CTA |
| **2** | title + imageUrl + extra | 圆标 + 标题 + extra.rows + 可选 CTA |
| **3** | 全部 | 圆标 + 标题 + 正文 + extra.rows + 可选 CTA |

- 圆标：`imageUrl`，空则隐藏（无 SF 兜底）
- CTA：仅 `urlKey` 非空时展示，文案 `skipTxt`（空→「去查看」）；**仅按钮可点**
- 跳转：`FundePageURL.open(urlKey)`
- type 2/3 展示 `extra.dataSourceTag`（空则隐藏）
- 不画封面；`businessData` 不参与绘制

详见 [`message-cards.md`](./message-cards.md)。

#### 其它 ObjectName

| 样式类 | variant | UI |
|--------|---------|-----|
| C-vip | `vip` | 无封面，content 分行 |
| C-comment | `serviceComment` | 只读星级 |
| C-check | `checkUser` | title + 正文 |

#### 判定

```
AD:SysNotify → 统一 sysNotify（按 messageType 1/2/3 取字段）
AD:Vip / ServiceComment / CheckUserMsg → 各自 variant
```

SysNotify 整卡不可点；仅底部按钮在 `urlKey` 非空时跳转。

---

## 2. Model 字段

| 字段 | 用途 |
|------|------|
| `sysNotifyContent` 等 | 四种协议 Content |
| 顶层 `messageType` | 协议卡整型：1 title+content+imageUrl；2 title+imageUrl+extra；3 全部。缺省按 1。与 `extra.type` 不是同一字段 |
| `skipTxt` | SysNotify 跳转按钮文案；`urlKey` 非空时展示，空则「去查看」 |
| Resolved.`monitorRows` | type 2/3 的 `extra.rows` |
| Resolved.`dataSourceTag` | type 2/3 的 `extra.dataSourceTag`（空则隐藏 tag） |
| `lastMsgDisplayContent` | 会话列表摘要 |

展示统一：`IMCardResolver.resolve` → `IMCardResolved` → `SysNotifyCell`。
