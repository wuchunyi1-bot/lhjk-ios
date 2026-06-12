## Context

项目从零开始，当前目录为空。需要搭建一个完整的 iOS 工程骨架，承载蓝牙、网络、IM、支付四大业务模块。所有模块基于 PL/BLL/DAL 三层架构，使用 CocoaPods 管理依赖。

## Goals / Non-Goals

**Goals:**
- 创建 Xcode 项目（.xcodeproj）和 CocoaPods 工作空间（.xcworkspace）
- 配置 AppDelegate + SceneDelegate 生命周期
- 建立 PL/BLL/DAL 目录结构与基础协议（Protocol）
- 搭建蓝牙 BLE 模块骨架（CoreBluetooth 封装）
- 搭建网络请求模块骨架（纯 Alamofire + AuthenticationInterceptor）
- 搭建 IM 模块骨架（融云 SDK + 消息模型）
- 搭建支付模块骨架（微信支付 + 支付宝）
- 搭建数据存储基础设施（FMDB + UserDefaults + Keychain 分类存储）
- 搭建路由基础设施（CTMediator 中间件模式）
- 集成图片加载库（Kingfisher）
- 统一 UI 布局方式（SnapKit）
- 配置 .gitignore、Podfile、Info.plist 等工程文件
- 最低支持 iOS 15.0

**Non-Goals:**
- 不实现 Apple IAP（应用内购买）
- 不实现具体的业务 UI 界面（仅创建基础架构和协议定义）
- 不实现完整的消息推送逻辑（仅配置 APNs 注册入口）
- 不实现第三方 SDK 的具体对接代码（仅定义支付抽象层接口）

## Decisions

### 1. 网络层技术选型：Alamofire（纯）

**选择**: Alamofire 作为唯一的网络层框架，不引入 Moya。利用 Alamofire 内置的 `AuthenticationInterceptor` + 自定义 `Authenticator` 协议处理 Token 注入、过期刷新和并发控制。

**备选方案**:
- Alamofire + Moya — Moya 的 TargetType 抽象增加了一层不必要的间接引用，其 Plugin 机制与 Alamofire 原生的 RequestInterceptor / EventMonitor 功能重叠
- URLSession 原生封装 — 代码量大，缺少社区验证的重试/拦截器机制

**理由**: Alamofire 5.x 内置的 `AuthenticationInterceptor` 已经完美解决了 Token 管理的核心痛点——自动注入、过期刷新、并发控制（多请求同时触发刷新时自动排队，无需手动管理锁和队列）。配合自定义 `Authenticator` 协议实现（OAuthAuthenticator），代码更简洁、健壮。Alamofire 原生的 `RequestInterceptor` 和 `EventMonitor` 协议已覆盖拦截器和日志需求，无需 Moya 的 Plugin 层。

### 2. IM 技术选型：融云 SDK

**选择**: 融云（RongCloud）IM SDK — `RongCloudIM`，通过 CocoaPods 集成。

**备选方案**:
- Starscream 自建 WebSocket — 需要自行实现心跳、重连、消息路由、会话管理等基础能力，开发成本高
- SocketRocket — Objective-C 库，Swift API 不够原生

**理由**: 融云 SDK 提供成熟的长连接管理、消息路由、会话管理、离线消息、已读回执等开箱即用能力，大幅降低 IM 模块开发成本。融云 CocoaPods 方式集成简单，符合项目依赖管理规范。DAL 层封装 `RCIMClient` 对外暴露业务友好的接口。

### 3. 数据存储技术选型：FMDB + UserDefaults + Keychain

**选择**: 根据数据类型分层存储 — FMDB (SQLite) 存结构化业务数据，UserDefaults 存简单键值配置，Keychain 存安全凭证。

**数据分类原则**:

| 存储方式 | 适用场景 | 示例 |
|---------|---------|------|
| FMDB (SQLite) | 需 SQL 查询/分页/关联的结构化数据 | 用户信息、消息记录、会话列表、健康数据、订单记录 |
| UserDefaults | 简单键值对，无需查询能力 | 主题模式、通知开关、功能开关、环境配置 |
| Keychain | 安全敏感数据 | Token、RefreshToken、支付密码 |

**理由**: FMDB 的 `FMDatabaseQueue` 提供线程安全的串行数据库访问，适合 IM 消息、健康数据等高频读写场景。UserDefaults 适合轻量级配置，无需 SQL 查询的简单键值对。Keychain 提供系统级安全加密存储，适合 Token 等敏感信息。

### 4. 蓝牙架构模式

**选择**: 将 CoreBluetooth 封装为独立 DAL 层服务 `BluetoothManager`，向上暴露基于 Delegate + Combine 的异步 API。

**理由**: CoreBluetooth 原生 API 基于 delegate 回调，封装后对 BLL 层暴露 Combine Publisher，更符合现代 Swift 异步编程范式。

### 5. 支付模块架构

**选择**: 定义统一的 `PaymentChannelProtocol` 协议，每个支付渠道实现该协议。不支持 Apple IAP，仅支持微信支付和支付宝。

```
┌───────────────────────────────────────────┐
│              BLL: PaymentService           │
│              (统一支付协调)                  │
├───────────────────────────────────────────┤
│  DAL: PaymentChannelProtocol               │
│  ┌─────────────────┬──────────────────┐    │
│  │ WeChat Pay      │ Alipay           │    │
│  │ Channel         │ Channel          │    │
│  └─────────────────┴──────────────────┘    │
└───────────────────────────────────────────┘
```

**理由**: 策略模式天然适配多支付渠道场景，新增渠道只需实现协议即可。

### 6. UI 布局选型：SnapKit

**选择**: 使用 SnapKit 作为统一的自动布局 DSL，所有页面布局代码使用 SnapKit API。

**理由**: SnapKit 提供了比原生 NSLayoutConstraint 更简洁、可读性更强的 DSL 语法，减少布局代码量。统一布局方式避免团队内多种布局方案混用（frame / Masonry / 原生 anchor），降低维护成本。

### 7. 图片加载选型：Kingfisher

**选择**: 使用 Kingfisher 作为统一的图片加载和缓存库。

**理由**: Kingfisher 是 Swift 原生图片加载库，提供异步下载、多层缓存（内存 + 磁盘）、图片预处理（缩放/裁剪/圆角）、下载进度等开箱即用能力。纯 Swift 实现，API 对 UIKit 友好，无 Objective-C 桥接开销。

### 8. 路由选型：CTMediator

**选择**: 使用 CTMediator 中间件模式实现模块间解耦路由，支持 URL-based 导航和 Target-Action 注册。

**理由**: CTMediator 通过 Target-Action 模式实现模块间零依赖跳转——PL 层模块不直接 import 其他模块的 ViewController，而是通过 Router 和 URL 路径间接调用。这确保 6 个业务模块（RegisterLogin / Home / Health / Service / Message / My）可以独立开发、编译和测试。URL Scheme（`lhjk://module/action?params`）同时支持内部跳转、Deep Link 外部唤起和推送通知导航。

### 6. 项目目录结构

```
lhjk-client/
├── Podfile
├── lhjk-client.xcworkspace
├── lhjk-client/
│   ├── Info.plist
│   ├── PL/                              # 表现层 — 按业务模块组织
│   │   ├── RegisterLogin/               # 注册/登陆模块 UI
│   │   ├── Home/                        # 首页模块 UI
│   │   ├── Health/                      # 健康模块 UI
│   │   ├── Service/                     # 服务模块 UI
│   │   ├── Message/                     # 消息模块 UI
│   │   └── My/                          # 我的模块 UI
│   ├── BLL/                             # 业务逻辑层 — 按业务模块组织
│   │   ├── RegisterLogin/               # 注册/登陆业务逻辑
│   │   ├── Home/                        # 首页业务逻辑
│   │   ├── Health/                      # 健康业务逻辑
│   │   ├── Service/                     # 服务业务逻辑
│   │   ├── Message/                     # 消息业务逻辑
│   │   └── My/                          # 我的业务逻辑
│   ├── DAL/                             # 数据访问层 — 按基础设施类型组织
│   │   ├── Networking/                  # 网络请求封装
│   │   ├── Bluetooth/                   # BLE 蓝牙封装
│   │   ├── IM/                          # 即时通讯封装
│   │   ├── Payment/                     # 支付封装
│   │   ├── Storage/                      # 数据存储（FMDB + UserDefaults）
│   │   └── Router/                       # 路由导航（CTMediator）
│   └── Other/                           # 其他 — 应用级基础设施
│       ├── AppDelegate.swift            # 应用生命周期
│       ├── SceneDelegate.swift          # 场景生命周期
│       ├── RootTabBarController.swift   # 根标签栏控制器
│       ├── Common/                      # 公共组件
│       │   ├── Extensions/              # UIKit 扩展
│       │   ├── Protocols/               # 基础协议
│       │   └── Base/                    # 基类
│       └── Resources/                   # 资源文件
│           ├── Assets.xcassets
│           └── LaunchScreen.storyboard
```

**设计理由**: PL 和 BLL 按业务模块（6 大模块）组织，确保业务模块在两层中一一对应；DAL 按基础设施类型组织，为各业务模块提供统一的基础能力；Other 集中管理应用级入口和公共组件。

## Risks / Trade-offs

- **融云 SDK 版本兼容**: 融云 SDK 版本与 iOS 系统版本有兼容性要求 → 参考融云官方文档锁定稳定版本，升级前在测试环境验证
- **CocoaPods vs SPM**: CocoaPods 是用户指定要求，部分库可能对 SPM 支持更好 → 在 Podfile 中锁定版本以保持构建稳定性

## Open Questions

<!-- 暂无。后续变更中逐步细化各模块的详细实现 -->
