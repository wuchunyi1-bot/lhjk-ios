## Why

个人信息页字段行对齐与姓名可编辑规则需对齐 `ProfileView.vue` / `me-profile.page.yaml`：title 左、value 右；姓名为必填可编辑字段（手机号仍只读）。当前 iOS 将姓名设为只读，且行布局未严格保证 value 贴右。

## What Changes

- 所有资料行：label 左对齐固定宽，value 右对齐并占用剩余空间，可编辑行带 ›
- **姓名可编辑**（text + 必填校验：非空、至少 2 字）；保存映射 `chineseName`
- 姓名行展示必填红色 `*`（对齐 Vue）
- 手机号保持只读脱敏

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `me-profile`: 行布局对齐规则 + 姓名可编辑

## Impact

- `PL/My/Profile/ProfileViewController.swift`
- OpenSpec：本 change 的 `me-profile` delta
- 参考：`ProfileView.vue`、`docs/page-specs/me-profile.page.yaml`
