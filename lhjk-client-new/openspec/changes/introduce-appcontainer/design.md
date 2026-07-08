## Context

当前项目架构分析了单例泛滥问题（见 `/analyze` 输出），建议逐步引入依赖注入。`extract-viewmodels` 变更已完成了第一步——ViewModel 支持 `init` 注入。本变更完成第二步——引入轻量 `AppContainer` 收敛所有单例引用。

> **Related**: `openspec/changes/extract-viewmodels/` — ViewModel 提取变更

## Decisions

### 1. 容器模式：纯 Swift 聚合对象，不引入框架

**选择**: 手写 ~70 行的 `AppContainer`，用 `lazy var` 持有所有 Service 实例。

**理由**:
- 零依赖，零学习成本
- 编译时类型安全（每个 service 的类型明确）
- 可以按需替换单个 service（测试时）
- 足够小，维护成本低

**不选择**:
- Swinject / Cleanse：第三方 DI 框架太重，增加编译时间和学习成本
- `@Injected` Property Wrapper：隐式依赖，跟 `.shared` 没本质区别

### 2. `AppContainer` 自身也是单例

**选择**: `AppContainer.shared`，但这是**唯一允许**的单例。所有其他 Service 通过 Container 访问。

**理由**: Container 作为"应用启动时组装、应用退出时销毁"的根对象，单例是合适的。它不是业务单例——它在 `main.swift` / `AppDelegate` 层面被持有。

### 3. 用 `lazy var` 而非 `let`

**选择**: `private(set) lazy var xxxService: XxxService = .shared`

**理由**:
- `lazy` 保持懒加载语义（跟原来的 `.shared` 行为一致）
- `private(set)` 允许测试时替换，但禁止外部随意修改
- 后续可将 `= .shared` 改为 `= XxxService(apiManager: apiManager)`（构造器注入）

### 4. 组织方式：按职责分组

**选择**: 不按层（DAL/BLL）分组，而是按初始化顺序和依赖关系排列。

```swift
// 1. 基础设施（无依赖）
private(set) lazy var router: Router = .shared
private(set) lazy var databaseManager: DatabaseManager = .shared
private(set) lazy var networkMonitor: NetworkMonitor = .shared

// 2. 网络层
private(set) lazy var apiManager: APIManager = .shared

// 3. SDK 封装
private(set) lazy var rongCloudManager: RongCloudManager = .shared
private(set) lazy var bluetoothManager: BluetoothManager = .shared

// 4. 业务服务
private(set) lazy var loginService: LoginService = .shared
private(set) lazy var userManager: UserManager = .shared
// ...
```

### 5. ViewModel 默认值：从 `.shared` 改为 `AppContainer.shared.xxx`

**选择**: ViewModel 的 `init` 参数默认值使用 `AppContainer.shared.xxx`。

**之前**:
```swift
init(imService: IMService = .shared) { ... }
```

**之后**:
```swift
init(imService: IMService = AppContainer.shared.imService) { ... }
```

**理由**:
- 运行时行为完全不变（`AppContainer.shared.imService` 返回的就是 `IMService.shared`）
- 把"依赖图的入口"收敛到 `AppContainer` 一个文件
- 测试时直接传 mock，不走 Container

### 6. 什么不动（本次）

| 层级 | 当前状态 | 本次变更 |
|------|---------|---------|
| ViewModel | `init` 注入 + `.shared` 默认值 | 默认值改为 `AppContainer.shared.xxx` |
| ViewController | 直接调 `XxxService.shared` | **不动** |
| BLL Service 内部 | 互相调 `.shared` | **不动** |
| AppDelegate / SceneDelegate | 直接初始化 SDK | **不动** |

### 7. 后续步骤

1. ViewController 不再直接调 `.shared`，改为通过 ViewModel（ViewModel 由 Container 组装）
2. BLL Service 支持构造器注入，由 Container 负责组装依赖链
3. 当有测试需求时，按需对需要 mock 的 Service 抽 Protocol
