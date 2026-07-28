## Context

参考：

- `funde-client/prototype/src/views/me/MeView.vue`
- `funde-client/prototype/src/mock/me.json`
- `funde-client/docs/page-specs/me-hub.page.yaml`（落后：仍写 membership / stats / fulfillment）
- 既有 change：`adapt-fundee-me-hub`（曾要求会员卡 + 设置与支持）

产品补充决议（2026-07-28）：**Hub 去掉「健康大会员」**，即使 Vue/PRD 暂未删代码。

目标信息架构：

```
Hero（渐变）
  头像 + 姓名 + 设置
  个人信息 | 健康档案
常用功能（4×2 宫格）
健康管理（功能行列表）
退出登录
```

## Goals / Non-Goals

**Goals:**

- Hub 对齐 Vue 现行布局，并强制去掉会员卡
- 健康管理项与 `me.json` 一致
- 清理 ViewModel / VC 中会员卡死代码

**Non-Goals:**

- 不删除 `/me/membership` 子页实现（仅 Hub 无入口）
- 不接真实订单/积分/会员 API
- 不改 Settings / Profile 内部

## Decisions

1. **Vue 优先于 me-hub.page.yaml**：yaml 中的 membership / stats / fulfillment 不作为本 change 要求。
2. **会员卡**：Hub MUST NOT 渲染；`MeMembershipCardView` 可不挂载；ViewModel 可删除会员展示态。
3. **设置与支持**：Vue 无此 Section → Hub 删除；设置仅 Hero 齿轮。
4. **健康管理**：按 `healthManagementActions` 7 项；`健康评估` → `/me/health-assessment`（占位），`健康测评` → `/me/health-evaluations`。
5. **地址路由**：iOS 用 `/me/address`（不用 Vue `/me/settings/addresses`）。

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Vue 仍显示会员卡导致对照不一致 | Spec 写明产品决议优先；后续 Vue 再删 |
| 用户找不到会员入口 | 本期无入口；若运营需要再单独加 |

## Open Questions

- 无
