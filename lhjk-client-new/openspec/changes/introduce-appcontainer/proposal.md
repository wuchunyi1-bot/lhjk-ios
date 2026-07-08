## Why

当前项目中有 20+ 个 `.shared` 单例散落在 ViewController、ViewModel、BLL Service 各处。例如：

- `APIManager.shared.getAsync(...)` — 网络请求
- `LoginService.shared.loginByPhone(...)` — 登录逻辑
- `UserManager.shared.currentUser` — 用户信息
- `IMService.shared.loadConversations()` — IM 会话

这导致：
1. **隐式依赖**：从类的外部接口看不出它依赖哪些 Service
2. **不可测试**：无法替换 mock 实现
3. **生命周期不可控**：单例在首次访问时初始化，顺序隐式且脆弱

虽然 ViewModel 层已支持 `init` 注入（`extract-viewmodels` 变更），但默认值仍是 `.shared`，依赖关系仍然分散在各文件中。

## What Changes

1. 新建 `DAL/AppContainer.swift` — 应用级依赖容器，收敛所有 `.shared` 到一处
2. 更新 6 个已有的 ViewModel 的 `init` 默认值：从 `.shared` 改为 `AppContainer.shared.xxx`

**不改变的**：
- 现有的 `.shared` 单例仍然存在（保持向后兼容）
- ViewController 内部直接访问 `.shared` 不做修改（留待后续变更）
- BLL Service 之间互相引用 `.shared` 不做修改

## Capabilities

- `project-architecture`: 新增 AppContainer 依赖管理规范

## Impact

- **DAL/AppContainer.swift**: 新增（~70 行）
- **PL/Home/ViewModels/HomeViewModel.swift**: 默认值改为 `AppContainer.shared.userManager`
- **PL/Message/Chat/ViewModels/ChatViewModel.swift**: 默认值改为 `AppContainer.shared.*`
- **PL/Message/ViewModels/ConversationListViewModel.swift**: 默认值改为 `AppContainer.shared.*`
- **PL/My/Address/ViewModels/AddressListViewModel.swift**: 默认值改为 `AppContainer.shared.*`
- **PL/My/Vouchers/ViewModels/VoucherListViewModel.swift**: 默认值改为 `AppContainer.shared.*`
- **PL/My/Home/ViewModels/MyViewModel.swift**: 默认值改为 `AppContainer.shared.*`
- **无工程配置变更**
