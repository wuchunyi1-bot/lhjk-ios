## 1. ViewModel 数据

- [x] 1.1 更新 `MyViewModel`：会员状态模型、`commonActions`、健康管理 6 项、设置与支持分组；移除 stats/fulfillment/services 对 Hub 的依赖
- [x] 1.2 提供会员卡展示文案（benefit/date/CTA）计算属性

## 2. Hub UI

- [x] 2.1 改 Hero：按钮文案「个人信息」；健康档案 → `/me/health-profile`；去掉统计条
- [x] 2.2 会员卡按状态渲染（渐变卡 + 主/次按钮）；去掉「注销演示」
- [x] 2.3 新增常用功能宫格 Cell/Section（8 项）
- [x] 2.4 Section：常用功能 → 健康管理 → 设置与支持；底部退出登录
- [x] 2.5 退出登录复用与 Settings 相同清理链

## 3. 路由

- [x] 3.1 确认常用功能路由均已注册；必要时注册 `/me/membership/open` 占位

## 4. 校验

- [x] 4.1 对照 Vue Hub 结构自检；新文件提示加入 Xcode
