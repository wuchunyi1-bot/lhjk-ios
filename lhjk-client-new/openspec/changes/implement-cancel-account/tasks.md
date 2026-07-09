## 1. Spec 文档

- [x] 1.1 创建 `openspec/changes/implement-cancel-account/` 目录及 `.openspec.yaml`
- [x] 1.2 编写 `proposal.md`
- [x] 1.3 编写 `design.md`
- [x] 1.4 编写 `specs/cancel-account/spec.md`

## 2. BLL: UserService API

- [ ] 2.1 `UserService` 新增 `cancelCurrentUser()` 方法

## 3. PL: CancelAccountViewModel

- [ ] 3.1 创建 `PL/My/Settings/Security/ViewModels/CancelAccountViewModel.swift`

## 4. PL: CancelAccountViewController 重构

- [ ] 4.1 移除 mock 延迟和 `.shared` 直调
- [ ] 4.2 添加 `bindViewModel()` 订阅
- [ ] 4.3 接入真实 API 调用

## 5. 验证

- [ ] 5.1 编译验证
- [ ] 5.2 在 Xcode 中手动将新文件加入 `lhjk-client-new` target（Add Files to "lhjk-client-new"...）
