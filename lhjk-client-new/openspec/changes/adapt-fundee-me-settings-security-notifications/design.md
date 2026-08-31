## Context

对齐 funde-client PRD / page-spec / Vue；替换 iOS 旧安全中心与通知页实现。

## Goals / Non-Goals

**Goals:**

- 安全中心 UI/文案/分组/下钻完全对齐 Vue
- 微信授权独立页
- 通知页：系统通知状态 + 四类开关本地存储

**Non-Goals:**

- 不在本 change 重做修改手机号 / 登录密码 / 注销账号内部流程（沿用已有 VC，仅校正路由）
- 不接真实微信 SDK（绑定仍为本地演示昵称「富德联好健康用户」）

## Decisions

1. **状态卡固定文案**：始终「账号安全状态良好」+「已绑定手机号，建议定期更新登录密码…」，不做动态「建议完善」。
2. **密码展示**：`UserDefaults fd_login_password_set` 优先；否则回退 `user.pwd` 非空 →「已设置」/「去设置」。
3. **微信展示**：`fd_wechat_nickname` 或用户 `openIdWechat` → 昵称 /「未绑定」；解绑仅在微信页。
4. **注销文案**：右侧「谨慎操作」，颜色警告橙 `#D47A58`；标题「注销账号」。
5. **系统通知**：读取 `UNUserNotificationCenter` 真实授权；未授权 toast 引导系统设置并可 `openSettings`；已开启 toast「手机系统通知已开启」。
6. **偏好存储**：JSON `fd_notification_settings`，默认 service/health/appointment=true，marketing=false。

## Open Questions

- 无
