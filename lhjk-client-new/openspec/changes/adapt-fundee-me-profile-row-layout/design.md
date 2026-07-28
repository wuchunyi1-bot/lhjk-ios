## Context

对齐：

- `funde-client/prototype/src/views/me/ProfileView.vue`（`.info-row__label` / `__value`）
- `funde-client/docs/page-specs/me-profile.page.yaml`（姓名可编辑必填）
- 既有 `adapt-fundee-me-profile`（曾将姓名设为只读，需修正）

## Goals / Non-Goals

**Goals:**

- 行布局：title 左、value 右
- 姓名可编辑并走 `updateCurrentProfile(chineseName:)`

**Non-Goals:**

- 不改头像上传、三组字段集合、手机号修改入口
- 不实现 Vue demo query 异常态

## Decisions

1. **行布局**：label 宽 88pt、左对齐；value `textAlignment = .right` + 低 hugging / 高 compression resistance 反向，贴右；可编辑行右侧 ›。
2. **姓名**：`FieldKind.text`；保存前校验非空与 `count >= 2`；必填星号红色。
3. **手机号**：仍 `readonly`，无箭头、不可点。

## Open Questions

- 无
