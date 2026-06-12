## 1. 项目工程创建

- [ ] 1.1 使用 Xcode 创建新项目，选择 iOS App 模板，语言 Swift，界面 UIKit，生命周期含 SceneDelegate
- [ ] 1.2 配置项目 Deployment Target 为 iOS 15.0
- [ ] 1.3 创建 Podfile 并在项目根目录执行 `pod init`，添加基础依赖框架
- [ ] 1.4 配置 .gitignore，排除 Pods/、.xcworkspace、DerivedData、.DS_Store 等
- [ ] 1.5 执行 `pod install` 生成 .xcworkspace

## 2. 应用生命周期配置

- [ ] 2.1 完善 AppDelegate.swift — 添加 SDK 初始化入口、推送注册、数据库初始化等调用占位（放在 Other/ 目录）
- [ ] 2.2 完善 SceneDelegate.swift — 创建 UIWindow，设置根视图控制器，处理前后台生命周期（放在 Other/ 目录）
- [ ] 2.3 配置 Info.plist — 添加蓝牙权限（NSBluetoothAlwaysUsageDescription）、推送注册、URL Scheme（微信/支付宝回调）

## 3. PL/BLL/DAL/Other 目录结构搭建

- [ ] 3.1 创建 Other/Common/Protocols/ 目录，定义基础协议：`PLProtocol`、`BLLProtocol`、`DALProtocol`
- [ ] 3.2 创建 Other/Common/Extensions/ 目录，添加常用 UIKit 扩展（UIColor+Hex、UIView+Layout、UIViewController+Alert 等）
- [ ] 3.3 创建 Other/Common/Base/ 目录，添加 `BaseViewController`、`BaseNavigationController` 基类
- [ ] 3.4 创建 Other/Resources/ 目录，添加 Assets.xcassets（AppIcon 占位）和 LaunchScreen.storyboard
- [ ] 3.5 创建 PL/ 下 6 个业务模块目录：RegisterLogin、Home、Health、Service、Message、My
- [ ] 3.6 创建 BLL/ 下 6 个业务模块目录：RegisterLogin、Home、Health、Service、Message、My
- [ ] 3.7 创建 DAL/ 下 4 个基础设施目录：Networking、Bluetooth、IM、Payment
- [ ] 3.8 创建 RootTabBarController.swift（放在 Other/ 目录），集成各模块入口页面

## 4. 网络请求模块（DAL/Networking）

- [ ] 4.1 在 Podfile 中添加 Alamofire、Moya 依赖，执行 `pod install`
- [ ] 4.2 创建 `APIManager.swift` — 封装 Moya Provider，支持多环境 Base URL 切换
- [ ] 4.3 创建 `APIInterceptor.swift` — 实现 Moya Plugin 协议，处理 Token 注入、请求日志、401 拦截
- [ ] 4.4 创建 `NetworkMonitor.swift` — 使用 NWPathMonitor 监控网络状态变化
- [ ] 4.5 创建 `APIError.swift` — 定义统一错误枚举（networkError、serverError、businessError、timeout）
- [ ] 4.6 创建 `BaseTargetType.swift` — 定义 API Target 协议，包含 baseURL、path、method、task、headers

## 5. 蓝牙连接模块（DAL/Bluetooth）

- [ ] 5.1 创建 `BluetoothManager.swift` — 封装 CBCentralManager，定义 BLE 状态枚举
- [ ] 5.2 实现设备扫描功能 — `startScan(serviceUUIDs:)`、`stopScan()`，返回 `Peripheral` 模型
- [ ] 5.3 实现连接管理 — `connect(_:)`、`disconnect(_:)`，含重试逻辑（最多 3 次）
- [ ] 5.4 实现服务与特征发现 — `discoverServices()`、`discoverCharacteristics(for:)`，缓存至 `Service` 模型
- [ ] 5.5 实现数据通信 — `readValue(for:)`、`writeValue(_:for:type:)`、`setNotify(_:for:enabled:)`
- [ ] 5.6 创建 `BluetoothService.swift`（BLL/Health/）— 协调蓝牙业务逻辑，提供 Combine Publisher 供 PL 层订阅
- [ ] 5.7 创建 `PeripheralCell.swift`（PL/Health/）— 设备列表 Cell 视图

## 6. IM 即时通讯模块（DAL/IM）

- [ ] 6.1 在 Podfile 中添加 RongCloudIM 融云 SDK 依赖，执行 `pod install`
- [ ] 6.2 创建 `Message.swift` — 定义消息模型（id、type、senderId、receiverId、content、timestamp、status），映射融云消息类型
- [ ] 6.3 创建 `Conversation.swift` — 定义会话模型（id、title、lastMessage、unreadCount、isPinned、updatedAt），映射融云会话类型
- [ ] 6.4 创建 `RongCloudManager.swift` — 封装融云 `RCIMClient`，实现 SDK 初始化、用户连接/断开、连接状态监听
- [ ] 6.5 创建 `RongCloudMessageDelegate.swift` — 实现 `RCIMClientReceiveMessageDelegate`，处理消息接收回调并分发至 BLL 层
- [ ] 6.6 创建 `IMService.swift`（BLL/Message/）— 消息发送/接收协调，状态同步、已读回执、会话管理
- [ ] 6.7 创建 `ConversationListViewController.swift`（PL/Message/）— 会话列表 UI 骨架
- [ ] 6.8 创建 `ChatViewController.swift`（PL/Message/）— 聊天页面 UI 骨架

## 7. 支付模块（DAL/Payment）

- [ ] 7.1 创建 `PaymentProtocol.swift` — 定义统一支付渠道协议（pay、verify、handleCallback）
- [ ] 7.2 创建 `PaymentOrder.swift` — 定义订单模型（orderId、productId、amount、channel、status、timestamp）
- [ ] 7.3 创建 `IAPManager.swift` — 封装 StoreKit，实现商品查询、购买、恢复购买、凭证验证
- [ ] 7.4 创建 `WechatPayChannel.swift` — 微信支付渠道骨架（预支付请求、SDK 调起）
- [ ] 7.5 创建 `AlipayChannel.swift` — 支付宝渠道骨架（签名字符串请求、SDK 调起）
- [ ] 7.6 创建 `PaymentService.swift`（BLL/Service/）— 统一支付协调，渠道选择、订单创建、回调分发
- [ ] 7.7 创建 `PaymentViewController.swift`（PL/Service/）— 支付页面 UI 骨架

## 8. 最终集成与验证

- [ ] 8.1 创建 RootTabBarController（放在 Other/），集成各模块入口页面
- [ ] 8.2 在 AppDelegate 中串联所有模块的初始化调用
- [ ] 8.3 配置 URL Scheme 和 Universal Link 处理（支付回调）
- [ ] 8.4 执行 `pod install` 确认所有依赖安装成功
- [ ] 8.5 编译项目确保无编译错误，Target iOS 15.0 Simulator 可正常运行
