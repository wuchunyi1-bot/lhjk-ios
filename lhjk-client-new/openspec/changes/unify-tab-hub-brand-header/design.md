## Context

四 Tab 顶栏文案不同，但应共享同一套排版几何。Vue：标题 22/700、副标题 12、间距 2、水平 16；首页标题色 primary，健康/服务/消息为 text。

## Goals / Non-Goals

**Goals:** 字号、行距、左右边距、相对 safeArea 顶部位置四处一致。  
**Non-Goals:** 不改「我的」Tab Hero；不改顶栏右侧操作区业务（服务页暂无右侧按钮）。

## Decisions

1. 组件 `TabHubBrandHeaderView`：`configure(title:subtitle:titleColor:)`
2. Token：标题 `.fdH2`（22 bold）；副标题 `.fdFont(ofSize: 12)`（对齐 Vue 12，不用 fdCaption 13）
3. 几何：leading/trailing 16；safeArea 下 top 12；title→subtitle 2；底 8
4. 四页均将 header **钉在 `safeAreaLayoutGuide.top`**，内容在其下（首页取消 brand cell + contentInset 顶 hack）
5. 首页 `titleColor = .fdPrimary`；其余 `.fdText`

## Risks / Trade-offs

- [首页顶栏改为固定不随列表滚] → 与健康/服务/消息一致，接受与 Vue home 可滚动头的微小差异
