## Context

当前 `PLProtocol` 定义了 `associatedtype ViewModel` + `bindViewModel()` 方法，但无任何 ViewController 实际遵循此模式。本次重构将 PLProtocol 的设计意图落地。

ViewModel 属于 **PL 层**，不是 BLL 层。原因：
- ViewModel 持有的是 UI 展示所需的状态（格式化后的文本、UI 专用的 flag）
- ViewModel 直接调用 BLL Service 获取数据并转换为 UI-ready 格式
- ViewModel 不包含业务规则（业务规则仍在 BLL Service 中）

## Decisions

### 1. ViewModel 类型：ObservableObject class

**选择**: `final class` + `ObservableObject` + `@Published`。

**理由**:
- `@Published` 需要 class + ObservableObject
- Combine 发布者让 ViewController 以声明方式绑定
- 不引入第三方响应式框架
- 更简单直观（相比于 struct + PassthroughSubject）

### 2. ViewModel 文件位置

```
PL/{Module}/
├── XxxViewController.swift
├── ViewModels/           ← 新增
│   └── XxxViewModel.swift
├── Cells/
└── Components/
```

**跨模块共享的 ViewModel**（如 ConversationListViewModel 被 Message 模块和 TabBar 使用）放在 `PL/{Module}/ViewModels/` 下。

### 3. 依赖注入

ViewModel 通过 `init` 注入 BLL Service（默认值使用 `.shared`）。

```swift
final class HomeViewModel: ObservableObject {
    private let userManager: UserManager

    init(userManager: UserManager = .shared) {
        self.userManager = userManager
    }
}
```

**理由**: 渐进式去单例 — 当前默认仍用 `.shared`，但 init 注入为未来 DI 和测试留了接口。

### 4. ViewController 绑定方式

ViewController 持有 ViewModel 实例，在 `bindViewModel()` 中订阅 `@Published` 属性：

```swift
final class HomeViewController: BaseViewController {
    private let viewModel = HomeViewModel()
    private var cancellables = Set<AnyCancellable>()

    override func bindViewModel() {
        viewModel.$snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.dataSource.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &cancellables)
    }
}
```

### 5. 一次性 UI 事件用 PassthroughSubject

对于 Toast、滚动、图片预览等无法用 `@Published` 表达的一次性事件，ViewModel 暴露 `PassthroughSubject`：

```swift
let toastPublisher = PassthroughSubject<String, Never>()
let scrollToBottomPublisher = PassthroughSubject<Bool, Never>()
```

### 6. 职责拆分原则

| 留在 ViewController | 移到 ViewModel |
|---|---|
| UI 布局 (SnapKit) | 数据数组 (@Published) |
| TableView/CollectionView dataSource/delegate | API 调用 + 错误处理 |
| 导航 (Router.push) | Combine 订阅管理 |
| 键盘处理、ImagePicker | 数据过滤、排序、格式化 |
| Toast、Alert 展示 | loading/empty 状态 |
| 生命周期 (viewWillAppear 等) | NotificationCenter 监听 |
| 滚动控制 | 数据缓存策略 |

### 7. 不引入协议抽象（本次）

**选择**: 不创建 ViewModelProtocol。

**理由**: 当前没有多态需求，等首个需要多实现的场景出现时再抽象。

### 8. 已处理与待处理

**已处理（6 个）**: HomeVC、ChatVC、ConversationListVC、AddressListVC、VoucherListVC、MyVC

**待处理**: LoginViewController（1058 行，最复杂，建议独立变更）

**跳过**: 容器型 VC（MessagesVC、OrderListVC）、纯静态数据 VC（HealthVC、ServiceVC）、过于简单的 VC（NotificationListVC）
