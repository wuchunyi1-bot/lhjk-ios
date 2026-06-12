# Project Architecture

## Purpose

定义整个 iOS 项目的基础架构规范，包括技术栈选型、应用生命周期管理、分层架构模式以及最低系统版本要求。

## Requirements

### Requirement: Technology Stack
系统 SHALL 使用以下技术栈进行开发：

- **语言**：Swift（最新稳定版）
- **UI 框架**：UIKit（纯代码布局，不使用 Storyboard）
- **布局库**：SnapKit（自动布局 DSL，统一页面布局方式）
- **依赖管理**：CocoaPods
- **最低支持**：iOS 15.0

#### Scenario: 创建新文件
- **WHEN** 开发者创建新的源代码文件
- **THEN** 文件必须使用 `.swift` 扩展名，且使用 UIKit 框架

#### Scenario: 页面布局
- **WHEN** 开发者编写 UI 布局代码
- **THEN** 必须使用 SnapKit 进行自动布局，不得使用原生 NSLayoutConstraint 或 frame 手动计算

#### Scenario: 添加第三方依赖
- **WHEN** 需要引入第三方库
- **THEN** 必须通过 CocoaPods（Podfile）进行管理，不得手动导入 `.framework` 或 `.xcframework`

#### Scenario: 使用系统 API
- **WHEN** 使用 iOS SDK 提供的 API
- **THEN** 必须确保该 API 在 iOS 15.0 及以上版本可用，或使用 `@available(iOS 15.0, *)` 进行可用性标注

---

### Requirement: App Lifecycle
系统 SHALL 使用 AppDelegate + SceneDelegate 管理应用生命周期。

- AppDelegate 负责应用级别的初始化（数据库、推送注册、第三方 SDK 初始化等）
- SceneDelegate 负责 UI 场景的生命周期管理

#### Scenario: 应用启动
- **WHEN** 应用首次启动
- **THEN** AppDelegate 的 `application(_:didFinishLaunchingWithOptions:)` 方法中完成 SDK 初始化、数据库迁移、推送注册等全局配置

#### Scenario: 场景创建
- **WHEN** 系统创建一个新的 UI 场景
- **THEN** SceneDelegate 的 `scene(_:willConnectTo:options:)` 方法中创建并配置主窗口 `UIWindow` 和根视图控制器

#### Scenario: 应用进入后台
- **WHEN** 应用进入后台
- **THEN** SceneDelegate 的 `sceneDidEnterBackground(_:)` 方法中处理状态保存和资源释放

---

### Requirement: Layered Architecture (PL/BLL/DAL)
系统 SHALL 严格遵循三层架构模式：

```
┌─────────────────────────────────────┐
│           PL (Presentation Layer)   │
│   ViewController + View             │
│   负责 UI 展示与用户交互              │
│   按业务模块组织子目录                │
├─────────────────────────────────────┤
│           BLL (Business Logic Layer)│
│   Service / Manager / Helper        │
│   负责业务逻辑处理                    │
│   按业务模块组织子目录（与 PL 对应）   │
├─────────────────────────────────────┤
│           DAL (Data Access Layer)   │
│   Repository / DB / API Client      │
│   负责数据存取与持久化                │
│   按基础设施类型组织子目录             │
└─────────────────────────────────────┘
```

#### Scenario: 用户操作传递
- **WHEN** 用户在界面上触发操作（如点击按钮）
- **THEN** PL 层调用 BLL 层对应方法，PL 不得直接访问 DAL 层或数据库

#### Scenario: 业务逻辑执行
- **WHEN** BLL 层需要存取数据
- **THEN** BLL 层必须通过 DAL 层提供的接口进行数据操作，BLL 不得直接操作数据库或发起网络请求

#### Scenario: 数据层变更
- **WHEN** DAL 层的实现发生变化（如更换数据库或网络库）
- **THEN** BLL 层和 PL 层不应受到影响，依赖倒置原则确保高层模块不依赖低层模块的具体实现

---

### Requirement: AI Configuration Restriction
AI（包括 Claude 等代码助手）SHALL NOT 修改以下项目配置类文件，所有配置变更必须由开发者手动完成：

- **Xcode 项目配置**：`.xcodeproj/project.pbxproj`、`.xcscheme` 等工程文件
- **CocoaPods 配置**：`Podfile`、`Podfile.lock`
- **Info.plist**：应用配置 plist 文件
- **Build Settings**：编译选项、签名配置、部署目标版本等
- **依赖变更**：新增/删除/升级 Pod 依赖
- **Workspace 配置**：`.xcworkspace` 内容

AI 可以读写业务代码（`PL/`、`BLL/`、`DAL/`、`Other/` 下的 `.swift` 文件）和 spec 文档，但不得修改上述配置类文件。

#### Scenario: 需要修改项目配置
- **WHEN** 需要修改 Build Settings、Podfile、Info.plist 等配置
- **THEN** AI 应给出明确的修改建议和步骤，由开发者手动执行

#### Scenario: 需要新增 Pod 依赖
- **WHEN** 业务代码需要引入新的第三方库
- **THEN** AI 应告知开发者需要在 Podfile 中添加的依赖项，由开发者手动编辑 Podfile 并执行 `pod install`

#### Scenario: AI 尝试修改配置
- **WHEN** AI 尝试编辑配置类文件（`.xcodeproj`、`Podfile`、`Info.plist` 等）
- **THEN** AI 必须停止操作，转为给出操作建议让开发者手动执行

---

### Requirement: Project Directory Structure
系统 SHALL 按照以下目录结构组织代码：

```
lhjk-client/
├── PL/                              # 表现层 — 按业务模块组织
│   ├── RegisterLogin/               # 注册/登陆模块 UI
│   ├── Home/                        # 首页模块 UI
│   ├── Health/                      # 健康模块 UI
│   ├── Service/                     # 服务模块 UI
│   ├── Message/                     # 消息模块 UI
│   └── My/                          # 我的模块 UI
├── BLL/                             # 业务逻辑层 — 按业务模块组织（与 PL 一一对应）
│   ├── RegisterLogin/               # 注册/登陆业务逻辑
│   ├── Home/                        # 首页业务逻辑
│   ├── Health/                      # 健康业务逻辑
│   ├── Service/                     # 服务业务逻辑
│   ├── Message/                     # 消息业务逻辑
│   └── My/                          # 我的业务逻辑
├── DAL/                             # 数据访问层 — 按基础设施类型组织
│   ├── Networking/                  # 网络请求封装（Moya + Alamofire）
│   ├── Bluetooth/                   # BLE 蓝牙封装（CoreBluetooth）
│   ├── IM/                          # 即时通讯封装（融云 SDK）
│   └── Payment/                     # 支付封装（IAP / 微信 / 支付宝）
└── Other/                           # 其他 — 应用级基础设施
    ├── AppDelegate.swift            # 应用生命周期
    ├── SceneDelegate.swift          # 场景生命周期
    ├── RootTabBarController.swift   # 根标签栏控制器
    ├── Common/                      # 公共组件
    │   ├── Extensions/              # UIKit 扩展（UIColor+Hex 等）
    │   ├── Protocols/               # 基础协议（PLProtocol、BLLProtocol、DALProtocol）
    │   └── Base/                    # 基类（BaseViewController、BaseNavigationController）
    └── Resources/                   # 资源文件（Assets.xcassets 等）
```

#### Scenario: 新增业务模块
- **WHEN** 需要新增一个业务模块（如"健康"模块）
- **THEN** 在 `PL/` 下创建对应业务文件夹（如 `PL/Health/`）存放 UI 代码，在 `BLL/` 下创建对应业务文件夹（如 `BLL/Health/`）存放业务逻辑代码

#### Scenario: 新增基础设施
- **WHEN** 需要新增一种基础设施封装（如推送模块）
- **THEN** 在 `DAL/` 下创建对应文件夹（如 `DAL/Push/`），存放该基础设施的封装代码

#### Scenario: PL 与 BLL 的模块对应
- **WHEN** PL 层某业务模块需要调用业务逻辑
- **THEN** 该模块调用 BLL 层同名业务模块下的 Service，确保 PL 与 BLL 的业务模块一一对应
