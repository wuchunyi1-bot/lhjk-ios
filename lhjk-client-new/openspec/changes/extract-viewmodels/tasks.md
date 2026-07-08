## 1. Spec 文档

- [x] 1.1 创建 `openspec/changes/extract-viewmodels/` 目录及 `.openspec.yaml`
- [x] 1.2 编写 `proposal.md` — 变更提案
- [x] 1.3 编写 `design.md` — 设计决策
- [x] 1.4 编写 `specs/project-architecture/spec.md` — PL 层目录规范新增 ViewModels/
- [x] 1.5 编写 `specs/home/spec.md` — HomeViewModel 定义
- [x] 1.6 编写 `specs/im/spec.md` — ChatViewModel + ConversationListViewModel 定义
- [x] 1.7 编写 `specs/shipping-address/spec.md` — AddressListViewModel 定义
- [x] 1.8 编写 `specs/vouchers/spec.md` — VoucherListViewModel 定义
- [x] 1.9 编写 `specs/me/spec.md` — MyViewModel 定义

## 2. HomeViewModel 实现

- [x] 2.1 创建 `PL/Home/ViewModels/HomeViewModel.swift`
- [x] 2.2 重构 `PL/Home/HomeViewController.swift`

## 3. ChatViewModel 实现

- [x] 3.1 创建 `PL/Message/Chat/ViewModels/ChatViewModel.swift`
- [x] 3.2 重构 `PL/Message/Chat/ChatViewController.swift`

## 4. ConversationListViewModel 实现

- [x] 4.1 创建 `PL/Message/ViewModels/ConversationListViewModel.swift`
- [x] 4.2 重构 `PL/Message/ConversationListViewController.swift`

## 5. AddressListViewModel 实现

- [x] 5.1 创建 `PL/My/Address/ViewModels/AddressListViewModel.swift`
- [x] 5.2 重构 `PL/My/Address/AddressListViewController.swift`

## 6. VoucherListViewModel 实现

- [x] 6.1 创建 `PL/My/Vouchers/ViewModels/VoucherListViewModel.swift`
- [x] 6.2 重构 `PL/My/Vouchers/VoucherListViewController.swift`

## 7. MyViewModel 实现

- [x] 7.1 创建 `PL/My/Home/ViewModels/MyViewModel.swift`
- [x] 7.2 重构 `PL/My/Home/MyViewController.swift`

## 8. 验证

- [ ] 8.1 编译验证：确保无编译错误
- [ ] 8.2 运行 `ruby generate_project.rb` 将新文件纳入 Xcode 项目（需开发者手动执行）

## 9. 后续

- [ ] 9.1 LoginViewController ViewModel 提取（独立变更，1058 行 → 预计 ~600 行）
- [ ] 9.2 HealthViewController / ServiceViewController 接入 API 后提取 ViewModel
