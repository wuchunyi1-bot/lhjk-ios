## 1. Spec 文档

- [x] 1.1 创建 `openspec/changes/introduce-appcontainer/` 目录及 `.openspec.yaml`
- [x] 1.2 编写 `proposal.md` — 变更提案
- [x] 1.3 编写 `design.md` — 设计决策
- [x] 1.4 编写 `specs/project-architecture/spec.md` — AppContainer 依赖管理规范

## 2. AppContainer 实现

- [ ] 2.1 创建 `DAL/AppContainer.swift`
- [ ] 2.2 注册所有现有 Service/Manager 实例

## 3. ViewModel 默认值更新（6 个）

- [ ] 3.1 `HomeViewModel` — `userManager` 默认值
- [ ] 3.2 `ChatViewModel` — `imService`、`rongCloudManager`、`rongCloudMessageDelegate` 默认值
- [ ] 3.3 `ConversationListViewModel` — `imService`、`rongCloudManager` 默认值
- [ ] 3.4 `AddressListViewModel` — `addressService` 默认值
- [ ] 3.5 `VoucherListViewModel` — `voucherService` 默认值
- [ ] 3.6 `MyViewModel` — `userManager` 默认值

## 4. 验证

- [ ] 4.1 编译验证：确保无编译错误
- [ ] 4.2 运行 `ruby generate_project.rb` 将新文件纳入 Xcode 项目
