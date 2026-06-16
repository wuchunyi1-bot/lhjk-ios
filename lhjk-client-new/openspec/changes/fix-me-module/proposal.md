## Why

对比 funde-client `MeView.vue`，iOS `MyViewController` 存在以下问题：

**Bug**:
1. "健康档案" 按钮无响应（缺 `.addTarget`）
2. "全部订单 ›" 点击弹出 toast 而非导航到订单页
3. 服务履约统计数字（待使用/使用中/已完成/待评价）不可点击

**UI 差距**:
4. Hero 区域缺少 funde 的暖色渐变背景
5. 服务履约统计无路由跳转

## What Changes

- `MyViewController.swift`: 修复 3 个 bug + 添加 Hero 渐变背景
- `MeServiceFulfillmentCell.swift`: 统计数字可点击，每个 stat 独立回调

## Impact

- **PL/My/MyViewController.swift**: ~15 行修改
- **PL/My/Cells/MeServiceFulfillmentCell.swift**: 添加 stat tap 支持
