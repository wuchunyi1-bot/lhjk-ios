# IM 消息卡片 — iOS 实现

> 代码：`IMCardResolver` / `IMCardResolved` / `SysNotifyCell`  
> AD:SysNotify **不再**按 `extra.type` / `rows` 拆三态；实时提醒卡已取消。

---

## AD:SysNotify 统一卡

所有 `AD:SysNotify` 都是 **同一种卡片样式**（原数据上传卡骨架：圆标 + 标题 + 可选正文 + 可选 extra 行 + 可选底部按钮）。

识别只看 **顶层 `messageType`（Int）**，不是 `extra.type`。缺省或其它值按 **1**。

| `messageType` | 读取字段 | 忽略 |
|---------------|----------|------|
| **1** | `title`、`content`、`imageUrl` | `extra` |
| **2** | `title`、`imageUrl`、`extra` | `content` |
| **3** | `title`、`content`、`imageUrl`、`extra` | — |

```
┌─────────────────────────────────┐
│ (imageUrl 28pt 圆)  title       │  ← imageUrl 空则隐藏图标，无 SF 兜底
│ content（仅 type 1 / 3）         │
│ ─────────────────────────────── │  ← 仅 type 2 / 3 且 extra.rows 非空
│ extra.rows KV / 结果胶囊 / 表    │
│ ┌──────── skipTxt ───────────┐ │  ← 仅 urlKey 非空；空文案默认「去查看」
└─────────────────────────────────┘
```

| 元素 | 规则 |
|------|------|
| 圆标 | 顶层 `imageUrl` → Kingfisher 填入 28pt 圆；空则隐藏 |
| 标题 | 顶层 `title` |
| 正文 | type 1/3 读 `content`；空则不占位 |
| extra 行 | type 2/3 解析 `extra.rows`（KV / 结果胶囊 / 表）；`cells` 兼容 `[[String]]` 与多包一层 `[[[String]]]` |
| 来源 tag | type 2/3 读 `extra.dataSourceTag`（空则隐藏；灰底胶囊贴标题行右侧） |
| 封面 | **不展示**封面大图 |
| 饮食卡 | `extra.monitorType == diet` 时改走下方饮食卡，不用本表的圆标和底部按钮 |
| `businessData` | **不参与绘制** |
| 头像 | `isShowUser` + `user.portraitUri` 不变 |
| 会话摘要 | `lastMsgDisplayContent` |

### 跳转

- **仅底部按钮可点**，整卡不可点。
- `urlKey` 非空才出按钮；文案 = `skipTxt`，空则「去查看」。
- 点击走 `NotificationMessageMapper.openRoute`：`FundeH5:` → `FundePageURL.open` 直开 H5（解析 path/query 后拼 `token` + `platform=ios`，**不要求**本地路由已注册）；`FundeApp:` / `/path` 走别名后再 `Router.push`（仅已注册）。
- `businessData.taskId` 在 urlKey 未带 `taskId` 时补进路由。

### 示例（type=1 套餐）

`title=19.9体验会员`，`content` 空，`imageUrl` 有值，`urlKey=FundeApp:/services/pkg?id=…`，`skipTxt=去查看`：

`[圆标] 19.9体验会员` + 底部「去查看」。

---

## 饮食卡（`extra.monitorType == diet`）

仍是 `AD:SysNotify`，不新开消息类型。`monitorType` 去空白、忽略大小写后为 `diet` 即饮食卡。其它监测卡保持上面的统一卡。

`messageType` 缺省按 1。空块不占位，顺序从上到下：

| 块 | 条件 |
|----|------|
| 标题 | `content.title` 非空。左侧固定 22pt 饮食图标（`#FFF2E6` 圆底），不用 `content.imageUrl`。右侧 `extra.dataSourceTag` 仅 type 2/3 且非空，10pt `#FF7A50` 描边 |
| 说明 | type 1/3 的 `content.content`，以及 type 2/3 的 `extra.rows` 里 `kind: text`（餐次等）。都在照片上面，按行拆成「标签 + 数值」：优先用第一个 `：` / `:`，没有则用第一处空白；标签 12 regular `#8591AB`，数值 12 medium `#1F2942`，间距 8，不画冒号。`color` 只给数值上色 |
| 餐食照片 | `extra.image` 非空。放在说明 / 文字明细下面、表格上面。内容宽、高 80、圆角 12，点击只预览大图 |
| 表格 | type 2/3 且 `extra.rows` 含 `kind: table`。白底、`#FDF6F3` 表头与描边、表头字 `#FF7A50`、单元格 12 regular |
| 专业团队分析 | `extra.analysis.content` 非空才显示整块（底 `#F4F7FC`、描边 `#E3F0FB`、圆角 12）。`title` 有值才显示标题。正文保留换行；行首「表扬：」「建议：」为 `#3664B1` medium |

饮食卡不展示底部「去查看」。`dataSourceTag` 跟着明细，type 1 不显示。

---

## 其它 ObjectName（未改）

`AD:Vip` / `AD:ServiceComment` / `AD:CheckUserMsg` 仍走各自 variant。
