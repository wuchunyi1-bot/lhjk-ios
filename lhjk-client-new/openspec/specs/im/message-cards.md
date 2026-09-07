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
| `businessData` | **不参与绘制** |
| 头像 | `isShowUser` + `user.portraitUri` 不变 |
| 会话摘要 | `lastMsgDisplayContent` |

### 跳转

- **仅底部按钮可点**，整卡不可点。
- `urlKey` 非空才出按钮；文案 = `skipTxt`，空则「去查看」。
- 点击走 `NotificationMessageMapper.openRoute`：`FundeH5:` → `FundePageURL.open`（不要求本地路由已注册）；`FundeApp:` / `/path` 走别名后再 `Router.push`（仅已注册）。

### 示例（type=1 套餐）

`title=19.9体验会员`，`content` 空，`imageUrl` 有值，`urlKey=FundeApp:/services/pkg?id=…`，`skipTxt=去查看`：

`[圆标] 19.9体验会员` + 底部「去查看」。

---

## 其它 ObjectName（未改）

`AD:Vip` / `AD:ServiceComment` / `AD:CheckUserMsg` 仍走各自 variant。
