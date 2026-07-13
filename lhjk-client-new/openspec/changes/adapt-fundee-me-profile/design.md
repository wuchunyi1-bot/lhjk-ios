## Context

权威参考：`funde-client/prototype/src/views/me/ProfileView.vue`（`me-profile.page.yaml` / `docs/v0.1/pages/me/profile.md` 已过时，以 Vue 为准）。

Vue 结构：

1. Nav「个人信息」
2. 居中头像区（80×80，圆角 24，可换图）
3. 单卡片内三组：
   - 个人基础信息：姓名(只读)、性别、出生日期、手机号(只读)、邮箱
   - 身份与职业：职业、文化程度、证件类型、证件号码
   - 地区信息：国籍、民族、籍贯、现居地、省/区、详细地址
4. 可编辑字段 → 底部 popup（取消/标题/保存 + input 或选项列表）

## Goals / Non-Goals

**Goals:**

- UI/字段/只读规则对齐 Vue
- 有后端字段的尽量走 `updateCurrentProfile`；头像继续 OSS
- 底部弹层编辑体验接近 Vue

**Non-Goals:**

- 不实现独立昵称页 / ProfileEdit（健康档案）页
- 不改换绑手机完整流程（手机号只读展示）
- 不强制实名校验文案（产品未定）

## Decisions

1. **Vue 优先于旧 page-spec**。
2. **性别**：UI 显示「男/女」，API 仍存 `"1"`/`"2"`。
3. **证件类型**：UI 中文选项；提交时映射为 `idType` Int（1 身份证…），无法映射则只存展示文案到本地并尽量传 `idNumber`。
4. **职业** 映射 `career`；**籍贯** → `province`/`householdProvince`；**现居地/省区/详细地址** → `addressProvince`/`addressCity`/`addressArea`/`address`。
5. **Payload 扩展** 而非另起 API，保持 `UserService.updateCurrentProfile`。

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| 后端未接受新字段 | 字段 Optional；失败 toast；UI 仍可展示本地/缓存值 |
| idType 枚举不一致 | 映射表 + 未知时不传 idType |

## Migration Plan

写 spec → 扩 payload → 重写 Profile VC → 编译验证。

## Open Questions

- 无
