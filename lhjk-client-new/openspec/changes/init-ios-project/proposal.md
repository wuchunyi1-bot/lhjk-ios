## Why

本项目是一个全新的 iOS 应用，需要一个完整的工程基础架构来支撑蓝牙连接、即时通讯、支付等核心业务模块。当前项目目录为空，需要从零搭建符合 PL/BLL/DAL 三层架构的 Xcode 工程，确保代码结构清晰、可维护、可扩展。

## What Changes

- 使用 Swift + UIKit + CocoaPods 初始化 Xcode 项目工程
- 配置 AppDelegate + SceneDelegate 应用生命周期管理
- 搭建 PL/BLL/DAL 三层架构目录结构与基础类
- 实现蓝牙 BLE 连接模块（CoreBluetooth）
- 实现统一网络请求模块（HTTP Client、拦截器、错误处理）
- 实现即时通讯 IM 模块（WebSocket、消息类型、会话管理）
- 实现支付模块（Apple IAP、微信支付、支付宝）
- 配置最低支持 iOS 15.0

## Capabilities

### New Capabilities
- `project-architecture`: 项目基础架构 — 技术栈、应用生命周期、PL/BLL/DAL 分层规范
- `bluetooth`: 蓝牙 BLE 连接 — 设备扫描、连接管理、服务发现、数据通信
- `networking`: 网络请求 — HTTP Client、拦截器链、错误处理、网络状态监控
- `im`: 即时通讯 — WebSocket 实时通信、多类型消息、会话管理、离线消息
- `payment`: 支付模块 — Apple IAP、微信/支付宝 SDK、订单管理、支付安全

### Modified Capabilities
<!-- 首次创建，无已有规范需修改 -->

## Impact

- **工程结构**: 创建全新的 `.xcworkspace`、`.xcodeproj`、`Podfile`，影响所有后续开发
- **依赖管理**: CocoaPods 引入第三方库（Alamofire、SocketRocket 等），影响编译配置
- **系统框架**: 依赖 CoreBluetooth、StoreKit、UserNotifications 等 iOS 系统框架
- **最低版本**: iOS 15.0，影响 API 选择范围
