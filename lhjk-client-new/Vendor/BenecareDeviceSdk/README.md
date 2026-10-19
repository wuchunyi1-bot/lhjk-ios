# 心护士设备 SDK：iOS / Android 接入指南

适用 SDK 版本：`0.1.0`。

本文面向原生 App 接入方。SDK 内部使用 Flutter 实现监测、扫码和波形页面，对外提供 Swift / Objective-C、Kotlin / Java 接口；宿主无需编写 Dart 代码或安装 Flutter 开发工具。

推荐直接接入完整监测页面：iOS 使用一个 `DeviceMonitorViewController`，Android 打开一个 `DeviceMonitorActivity`。页面自行完成初始化、扫码、本地绑定、蓝牙连接、波形显示与 Holter 开启。

## 1. 能力与接入方式

| 能力 | 当前支持范围 |
| --- | --- |
| 设备扫码 | 复用心护士 App 的 Flutter 扫码页面，识别设备 MAC 和可选 SN |
| 本地绑定 / 解绑 | 在宿主 App 内保存或清除目标设备，重新进入时恢复绑定 |
| 蓝牙连接 | 扫描、连接、断开、绑定设备的断线重连 |
| 设备状态 | 心率、电量、充电状态、导联状态、固件版本 |
| 心电波形 | 实时单导联、12 导联显示，走速、增益和导联切换；心电贴提供 II 导 |
| Holter | 通过蓝牙开启设备端存卡，读取录制状态及已录 / 剩余时间 |

SDK 只提供设备蓝牙能力，不接心护士账号、渠道校验、手机号绑定或服务端。宿主自行管理用户身份与业务服务；SDK 的本地绑定不代表服务端的设备归属。

| 接入方式 | iOS | Android | 宿主需要负责 |
| --- | --- | --- | --- |
| 完整监测页面（推荐） | `DeviceMonitorViewController` | `DeviceMonitorActivity` | 引入依赖、配置权限、传入监测用户标识、打开 / 退出页面 |
| 自定义集成 | `DeviceSdk` + `DeviceSdkContainer` | `BenecareDeviceSdk` + `DeviceSdkFragment` | 初始化、事件订阅、设备操作、容器生命周期和资源释放 |

完整页面与自定义集成应选择一种。每个进程只支持一个 SDK 实例，同一时间只能有一个已创建、未释放的 SDK 容器。

## 2. 交付包与接入准备

| 项目 | Android | iOS |
| --- | --- | --- |
| 交付文件 | `benecare-device-sdk-android-0.1.0.zip` | `benecare-device-sdk-ios-0.1.0.zip` |
| 包内依赖 | 本地 Maven 仓库，包含 SDK、Flutter 模块及插件的 AAR / POM / Gradle 元数据 | 8 个 XCFramework，包含原生接口、Flutter 引擎、业务模块和插件 |
| 最低系统 | Android 7.0（API 24） | iOS 13.0 |
| 当前示例使用的工具 | JDK 17、Android SDK 36、AGP 8.11.1、Kotlin 2.2.20 | Xcode 26.5 |
| 验证设备 | Android 真机 + 心电设备 | arm64 iPhone / iPad + 心电设备 |

两端 ZIP 都附带本说明、`build-info.json` 和 `THIRD_PARTY_NOTICES`。`build-info.json` 记录 SDK 版本、构建号及内置引擎版本；反馈问题时请一并提供。

保留同一次交付的完整依赖，升级时整体替换，不混用不同构建的 AAR 或 XCFramework。宿主已自行集成 Flutter 的场景尚未验证，需要单独进行引擎和插件兼容测试。

当前 iOS 交付包中的业务及插件框架只含真机切片，用于真机运行和打包。`Flutter.xcframework` 保留官方完整引擎及签名；它包含模拟器切片并不代表整个 SDK 支持模拟器。模拟器开发需要另行准备对应依赖。

## 3. Android 接入

### 3.1 放置完整 Maven 仓库

将 Android ZIP 解压到宿主工程的固定目录，例如 `vendor/benecare-device-sdk/`。仓库根目录就是包含 `com/`、`dev/`、`io/` 和 `README.md` 的目录：

```text
HostApp/
├── settings.gradle.kts
├── gradle.properties
├── app/
└── vendor/benecare-device-sdk/
    ├── com/benefm/device-sdk/...
    ├── com/benefm/benecare_device_module/...
    ├── dev/...
    ├── io/...
    ├── README.md
    ├── build-info.json
    └── THIRD_PARTY_NOTICES/
```

ZIP 是完整依赖仓库；其中各模块仍以 AAR 交付。保留目录层级与 POM / Gradle 元数据，使用 Maven 依赖解析，不要只取 `device-sdk-*.aar` 放入 `libs/`，否则会遗漏引擎或插件依赖。

### 3.2 配置 Gradle

在宿主 `settings.gradle.kts` 的依赖仓库配置中添加本地目录和 Flutter 引擎仓库：

```kotlin
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        maven { url = uri("$rootDir/vendor/benecare-device-sdk") }
    }
}
```

上述路径指向解压后的仓库根目录。SDK 和插件由本地仓库提供；AndroidX、Kotlin 及 Flutter 引擎等依赖仍需从配置的远端仓库下载，构建机需能访问这些仓库。

宿主 `gradle.properties` 开启 AndroidX：

```properties
android.useAndroidX=true
```

在 `app/build.gradle.kts` 中设置接入基线并添加 SDK 依赖：

```kotlin
android {
    compileSdk = 36
    defaultConfig {
        minSdk = 24
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("com.benefm:device-sdk:0.1.0")
}
```

此处只展示需要合并到现有工程的配置。Kotlin 宿主可参考示例的 Kotlin 2.2.20 / AGP 8.11.1 组合；SDK 已通过依赖传递引入 Flutter 模块和 AndroidX Fragment，无需逐个声明包内的 AAR。

### 3.3 打开完整监测页面

从宿主 Activity 调用：

```kotlin
import android.content.Intent
import com.benefm.device.sdk.DeviceMonitorActivity

// 来自宿主当前监测用户，必须符合第 5 节的标识格式。
val monitorUserId = "00112233445566778899AABBCCDDEEFF" // 示例值，正式接入替换
val monitorIntent = Intent(this, DeviceMonitorActivity::class.java)
    .putExtra(DeviceMonitorActivity.EXTRA_HOLTER_USER_ID, monitorUserId)
startActivity(monitorIntent)
```

SDK Manifest 已声明 `DeviceMonitorActivity`，直接打开无需再次注册。页面关闭时自动停止扫描、断开连接、释放相机、订阅与引擎，保留本地绑定；下一次打开会恢复绑定并尝试连接。

默认本地存储空间为 `device_monitor`。需要自定义存储空间时，继承入口 Activity 并覆盖配置：

```kotlin
import com.benefm.device.sdk.DeviceMonitorActivity
import com.benefm.device.sdk.SdkConfig

class HostDeviceMonitorActivity : DeviceMonitorActivity() {
    override fun sdkConfiguration() = SdkConfig(
        storageNamespace = "my_host",
        holterUserId = intent.getStringExtra(DeviceMonitorActivity.EXTRA_HOLTER_USER_ID)
    )
}
```

将自定义 Activity 注册到宿主 Manifest，并将启动 Intent 的目标改成该类；用户标识仍通过相同 Extra 传入：

```xml
<activity
    android:name=".HostDeviceMonitorActivity"
    android:exported="false"
    android:theme="@android:style/Theme.Material.Light.NoActionBar"
    android:hardwareAccelerated="true"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode" />
```

### 3.4 权限与生命周期

SDK 的 Manifest 会自动合并蓝牙与相机权限声明，完整页面在需要时处理授权流程：

| 系统 / 功能 | 所需权限 |
| --- | --- |
| Android 11 及以下 BLE 扫描 | 蓝牙权限及 `ACCESS_FINE_LOCATION`；部分系统还需开启系统定位服务 |
| Android 12 及以上 BLE 扫描 / 连接 | `BLUETOOTH_SCAN`、`BLUETOOTH_CONNECT` |
| 扫描设备二维码 | `CAMERA` |

直接使用 `DeviceMonitorActivity` 或上述子类时，SDK 已转发生命周期、返回键、权限与 Activity 结果。自定义子类覆盖这些方法时调用 `super`，保留 SDK 的转发行为。

纯接口或自定义 Fragment 集成的宿主使用 AndroidX `FragmentActivity`，相关转发要求见第 7 节。

## 4. iOS 接入

### 4.1 添加全部 XCFramework

将 iOS ZIP 解压到宿主工程的固定目录。在 Xcode 中将以下 8 个 XCFramework 全部加入 App target 的 **General → Frameworks, Libraries, and Embedded Content**，全部设置为 **Embed & Sign**：

| XCFramework | 作用 |
| --- | --- |
| `BenecareDeviceSdk.xcframework` | 原生接口与监测控制器 |
| `Flutter.xcframework` | 内置 Flutter 运行引擎 |
| `App.xcframework` | 监测、扫码和波形业务模块 |
| `objective_c.xcframework` | Dart 原生互操作支持 |
| `device_info_plus.xcframework` | 设备和系统信息 |
| `flutter_blue_plus_darwin.xcframework` | 蓝牙通信 |
| `mobile_scanner.xcframework` | 相机扫码 |
| `shared_preferences_foundation.xcframework` | 本地绑定存储 |

这些是运行所需的动态框架，不能只引入 `BenecareDeviceSdk.xcframework`。SDK 内部完成引擎初始化和插件注册，宿主不需要自行注册插件，也不需要通过 CocoaPods 编译 Flutter 源码。

将 App target 的 Deployment Target 设置为 iOS 13.0 或以上，使用真机进行运行验证。宿主已有自己的 `App.framework` 或 `Flutter.framework` 时，应先处理同名模块与引擎冲突。

### 4.2 配置用途说明

在宿主 App 的 Info.plist 中添加以下字段，说明文字可按宿主产品调整：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>用于连接心电设备并接收心电波形</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>用于连接心电设备</string>
<key>NSCameraUsageDescription</key>
<string>用于扫描设备二维码并绑定设备</string>
```

完整页面自行处理授权流程；这些用途说明必须由宿主提供。

### 4.3 打开完整监测页面

Swift 宿主在已有导航控制器中打开：

```swift
import UIKit
import BenecareDeviceSdk

// 来自宿主当前监测用户，必须符合第 5 节的标识格式。
let monitorUserId = "00112233445566778899AABBCCDDEEFF" // 示例值，正式接入替换
let config = SdkConfig(storageNamespace: "my_host", holterUserId: monitorUserId)
let monitor = DeviceMonitorViewController(configuration: config)
navigationController?.pushViewController(monitor, animated: true)
```

也可以作为独立页面展示：

```swift
let monitor = DeviceMonitorViewController(configuration: config)
monitor.modalPresentationStyle = .fullScreen
present(monitor, animated: true)
```

`present` 的宿主需要提供关闭入口，并在结束时 `dismiss`；导航方式由宿主提供返回入口。控制器被 pop、dismiss 或移出父控制器后，会自动关闭内部页面、断开设备并释放引擎，本地绑定保留。下一次进入时创建新的控制器，不复用已关闭实例。

需要嵌入自己的页面时，使用标准子控制器关系：

```swift
addChild(monitor)
monitor.view.translatesAutoresizingMaskIntoConstraints = false
view.addSubview(monitor.view)
NSLayoutConstraint.activate([
    monitor.view.topAnchor.constraint(equalTo: view.topAnchor),
    monitor.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
    monitor.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    monitor.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
])
monitor.didMove(toParent: self)
```

退出时移除子控制器，SDK 自动清理：

```swift
monitor.willMove(toParent: nil)
monitor.view.removeFromSuperview()
monitor.removeFromParent()
```

仅被其他页面遮挡时，监测页保持设备连接；宿主需要提前结束监测时调用 `monitor.close()`，之后再按自己的导航方式退出。

Objective-C 宿主使用 SDK 生成的头文件：

```objc
#import <UIKit/UIKit.h>
#import <BenecareDeviceSdk/BenecareDeviceSdk-Swift.h>

BNSdkConfig *config = [[BNSdkConfig alloc]
    initWithStorageNamespace:@"my_host"
    holterUserId:@"00112233445566778899AABBCCDDEEFF"]; // 示例值，正式接入替换
BNDeviceMonitorViewController *monitor = [[BNDeviceMonitorViewController alloc]
    initWithConfiguration:config];
[self.navigationController pushViewController:monitor animated:YES];
```

## 5. 宿主配置与用户切换

| 参数 | 含义与约束 |
| --- | --- |
| `storageNamespace` | 本地绑定存储空间，允许字母、数字、下划线、点和短横线，长度 1～64；完整页面默认 `device_monitor`，直接创建 `SdkConfig()` 默认 `default` |
| `holterUserId` | 当前监测用户的 16 字节业务标识；接受 32 位十六进制字符串或标准 UUID，可不传 |

`holterUserId` 示例：`00112233445566778899AABBCCDDEEFF` 或 `00112233-4455-6677-8899-AABBCCDDEEFF`。SDK 会去掉 UUID 中的短横线并统一大写，不生成用户身份，也不持久化该值。传入手机号、普通文本或不符合格式的标识会导致初始化返回 `invalidArgument`。

宿主应将自己的用户映射到一个稳定的、符合格式的业务标识，并在每次打开页面时传入。示例中的固定值只用于演示，正式接入不能让不同监测用户共用该值。

未传 `holterUserId` 时，扫码、连接和波形仍可使用；开启 Holter 会提示未配置监测用户，并返回 `holterUserMissing`。

更换用户前退出并关闭当前监测页面，再传入新配置创建页面。同一 `storageNamespace` 会恢复同一份本地绑定；若绑定需按用户隔离，宿主使用各用户独立且符合格式的命名空间，或在自定义集成中显式解绑。关闭页面本身不会清除绑定。

## 6. 完整页面的操作流程与 Holter

正常启动后直接进入 Flutter 监测页面：

1. 未绑定时，通过「扫码绑定设备」进入与 App 共用的扫码页面。
2. 识别设备二维码后保存本地绑定并连接；再次打开页面会恢复绑定并尝试连接。
3. 连接后查看心率、电量、导联情况和实时波形，调整走速 / 增益 / 导联，进入 12 导页面；心电贴以 II 导显示。
4. 设备状态就绪后「开启Holter监测」，确认时长，设备受理后显示录制状态与计时。
5. 设备菜单可断开或解绑。断开保留绑定；解绑清除绑定并断开连接。
6. 退出原生页面时释放相机、蓝牙和引擎；正在设备端进行的 Holter 记录继续。

Holter 是设备端存卡功能，开启及状态读取只通过蓝牙进行，不需要心护士服务端：

| 设备 | 可开启时长 | 条件 |
| --- | --- | --- |
| 记录仪 | 24 小时 | 页面开启前二次确认；设备已连接且状态就绪 |
| 心电贴 | 12 小时 | 电量至少 60%，设备已连接且状态就绪 |
| 心电贴 | 24 小时 | 电量至少 90%，设备已连接且状态就绪 |

设备状态未知、充电中、设备异常、未收到电量或导联状态时不能开启；实时型设备还需收到有效波形。已经录制时不能重复开启。

SDK 等待设备实际受理回执；回执超时时主动查询确认，不自动重复下发开启命令。录制状态以设备反馈为准，未收到时间时保持未知；收到设备计时后在两次回包之间更新显示。

断开连接、解绑或关闭页面只释放蓝牙连接，不会停止已经开始的设备端记录。当前版本不提供停止 Holter、记录文件传输 / 上传、报告、固件升级或后台持续采集接口。

## 7. 自定义集成与接口参考

仅在需要自行编排设备流程、接收设备事件或单独嵌入扫码 / 波形视图时使用本节。完整页面接入方无需再手动初始化 SDK，也不要在页面运行期间创建第二个实例。

### 7.1 初始化

Android 将 SDK 保存为宿主的成员变量，传入当前 `FragmentActivity`，等待成功后再调用其他操作：

```kotlin
import com.benefm.device.sdk.BenecareDeviceSdk
import com.benefm.device.sdk.SdkCallback
import com.benefm.device.sdk.SdkConfig
import com.benefm.device.sdk.SdkError
import com.benefm.device.sdk.SdkInfo

// 以下代码置于 FragmentActivity 内。
private lateinit var sdk: BenecareDeviceSdk

private fun initializeDeviceSdk(monitorUserId: String) {
    sdk = BenecareDeviceSdk(this)
    sdk.initialize(
        SdkConfig(storageNamespace = "my_host", holterUserId = monitorUserId),
        object : SdkCallback<SdkInfo> {
            override fun onSuccess(value: SdkInfo) {
                // 此后可订阅事件、创建容器或发起设备操作。
            }
            override fun onError(error: SdkError) {
                android.util.Log.e("DeviceSdk", "${error.code}: ${error.message}")
            }
        }
    )
}
```

iOS 同样保存 SDK 的强引用。所有公开模型可供 Objective-C 使用，Swift 示例：

```swift
import BenecareDeviceSdk

// 以下代码置于宿主控制器内。
private let sdk = DeviceSdk()

private func initializeDeviceSdk(monitorUserId: String) {
    sdk.initialize(SdkConfig(storageNamespace: "my_host", holterUserId: monitorUserId)) { info, error in
        if let error {
            let code = error.userInfo["sdkCode"] as? String ?? "operationFailed"
            print("\(code): \(error.localizedDescription)")
            return
        }
        // 此后可订阅事件、创建容器或发起设备操作。
    }
}
```

初始化只恢复本地绑定；纯接口集成需显式调用 `connectBoundDevice` 才开始连接。所有操作回调和事件在主线程执行，耗时处理放到宿主的工作队列。Java 可使用同一组类型，无返回值操作的回调为 `SdkCallback<kotlin.Unit>`。

### 7.2 设备接口

两端接口名称基本一致；Android 使用 `SdkCallback<T>`，iOS 使用 completion 回调。

| 接口 | 行为 |
| --- | --- |
| `getSdkInfo` | 获取版本、协议版本和能力清单 |
| `parseDeviceQr` | 解析完整二维码文本，首段为 MAC、第二段为可选 SN，以空白分隔；MAC 统一大写 |
| `bindLocalDevice(identity, autoConnect)` | 保存本地目标设备；传 `false` 后由宿主显式发起连接，传 `true` 则绑定后连接 |
| `getBoundDevice` | 读取已绑定设备；无绑定返回空 |
| `unbindLocalDevice` | 停止扫描、断开连接、取消重连并清除本地绑定 |
| `startScan` / `stopScan` | 开始 / 停止设备发现；单纯扫描不自动连接，显式停扫也会取消等待中的自动重连 |
| `connectBoundDevice` | 扫描匹配已绑定 MAC 并连接，意外断线后重连该目标 |
| `connect(deviceId)` | 连接当前扫描结果，不改变绑定，也不启用绑定目标的自动重连 |
| `disconnect` | 停止扫描、断开连接并取消本轮重连，保留绑定 |
| `getDeviceStatus` | 获取当前状态快照，包含 `holter` 状态 |
| `startHolter` | Android `startHolter(hours, callback)`；iOS `startHolter(hours:completion:)`，等待设备受理或查询确认 |
| `dispose` | 宿主先移除并释放所有容器，再调用此接口停止设备操作、取消订阅、释放引擎；保留绑定 |

连接接口返回成功表示请求已处理，不代表设备已经产生有效波形。实际链路状态通过 `DeviceStatus.linkState` 判断：`disconnected`、`scanning`、`connecting`、`connected`；首批有效波形就绪另有 `waveformReady` 事件。iOS 的扫描 `deviceId` 是系统分配的 UUID，与设备二维码中的 MAC 不同，应使用扫描结果里的 `deviceId` 调用 `connect`。

未知电量、心率为 `null` / `nil`，导联状态 `-1` 表示未知。`HolterStatus` 的 `known`、`starting`、`recording` 表达状态，`elapsedSeconds` 和 `remainingSeconds` 未收到时为空；`known=false` 不能视为设备尚未录制。

### 7.3 事件和波形数据

Android 使用 `setListener(listener, waveform, callback)` 设置 `DeviceSdkListener`；iOS 使用 `setDelegate(delegate, waveform:completion:)` 设置 `DeviceSdkDelegate`。传入空监听器可取消订阅，`waveform=true` 开启波形批次订阅。iOS delegate 为弱引用，宿主需保持其生命周期。

| 事件 | Android 回调 | iOS 回调 |
| --- | --- | --- |
| 设备状态 | `onDeviceStatus` | `deviceSdkDidUpdateStatus` |
| 扫描结果 | `onScanResults` | `deviceSdkDidDiscover` |
| 本地绑定变更 | `onBindingChanged` | `deviceSdkDidChangeBinding` |
| 扫码成功 / 取消 | `onScanCompleted` / `onScanCancelled` | `deviceSdkDidScan` / `deviceSdkDidCancelScan` |
| 波形批次 | `onWaveform` | `deviceSdkDidReceiveWaveform` |
| 首批有效波形 | `onWaveformReady` | `deviceSdkWaveformReady` |
| 异步错误 | `onError` | `deviceSdkDidFail` |

`WaveformChunk` 是已经完成解析与滤波的 mV 样本，Android 为 `Map<String, DoubleArray>`，iOS 为 `[String: [NSNumber]]`。每批包含连接 `sessionId`、累计 `sequence`、`sampleRate` 和 `cleared` 标记；按会话与序号处理连续性，收到清空标记时重置旧显示。

订阅最多排队 32 批。宿主处理过慢或跨桥通信失败时，SDK 停止本轮波形订阅并报告 `streamOverflow`；处理积压后重新订阅，同时识别可能出现的数据缺口。

### 7.4 单独嵌入扫码 / 波形 / 监测视图

| 视图 | 工厂接口 | 行为 |
| --- | --- | --- |
| 完整监测页 | `createMonitorContainer` | 与推荐入口相同的 Flutter 监测页面，但 SDK 实例与容器由宿主管理 |
| 扫码页 | `createScannerContainer` | 仅返回识别的设备身份，宿主收到事件后自行决定绑定与连接 |
| 波形页 | `createWaveformContainer` | 使用 `WaveformOptions` 指定单导 / 12 导、走速和增益；连接由宿主管理 |

`WaveformOptions` 默认 II 导、单导模式、25 mm/s、10 mm/mV。可选走速 12.5 / 25 / 50 mm/s，增益 2.5 / 5 / 10 / 20 / 40 mm/mV。心电贴实际只提供 II 导，其余导联显示 N/A。

Android 工厂返回 `DeviceSdkFragment`，使用宿主的 `FragmentManager` 添加。宿主需转发 `onPostResume`、`onNewIntent`、`onUserLeaveHint`、`onTrimMemory` 及权限 / Activity 结果到 Fragment；没有 SDK Fragment 时，将权限结果和 Activity 结果转发给 `sdk.onRequestPermissionsResult` / `sdk.onActivityResult`。移除 Fragment 后调用 `sdk.releaseContainer(fragment, callback)`，等待完成再创建下一个。

iOS 工厂返回 `DeviceSdkContainer`，按标准子控制器关系添加，或使用 `present`。完成 `removeFromParent` 或 `dismiss` 后调用 `container.close(completion)`，等待完成再创建下一个。

单独释放扫码 / 波形容器不会销毁 SDK 实例，释放波形视图也不会主动断开蓝牙。即使容器从未添加到页面，也需显式释放。最终按「移除容器 → 释放容器 → `dispose`」的顺序清理资源。

Android 自定义宿主 Activity 重建后使用 `setHostActivity` 更新权限宿主，并创建新容器；进程重建后重新初始化 SDK。两端均不复用已释放的容器或 SDK 实例。

## 8. 常见错误与排查

Android 读取 `SdkError.code`；iOS 读取 `NSError.userInfo["sdkCode"]`。不要使用 iOS 的数字 `NSError.code` 区分这些业务错误。

| 错误码 / 现象 | 处理方式 |
| --- | --- |
| `notInitialized` | 等待初始化成功后再调用接口 |
| `initializeTimeout` / `initializeFailed` | 检查完整依赖与宿主配置，记录错误后创建新实例重试 |
| `busy` | 避免重复初始化或重复发起正在执行的操作 |
| `engineInUse` | 关闭已有实例后再创建，不同时运行两套入口 |
| `viewInUse` | 先移除并释放旧容器，完成后再创建或释放 SDK |
| `disposed` | 创建新的 SDK / 页面实例 |
| `invalidArgument` / `invalidQr` / `invalidMac` | 检查命名空间、用户标识、二维码或波形参数格式 |
| `permissionDenied` | 按系统授权状态引导用户开启应用的蓝牙权限；扫码还需相机权限 |
| `bluetoothOff` | 检查手机蓝牙是否开启及是否可用 |
| `notBound` / `deviceNotFound` | 先绑定设备，或重新扫描并使用本轮扫描结果连接 |
| `holterUserMissing` | 打开页面 / 初始化时传入符合格式的监测用户标识 |
| `notConnected` / `deviceNotReady` | 等待设备连接及状态、波形就绪，排除充电和设备异常 |
| `alreadyRecording` | 读取现有录制状态，不重复开启 |
| `lowBattery` | 满足所选心电贴时长的电量要求后再开启 |
| `holterBusy` / `holterNeedInit` / `holterNoResponse` | 依据提示检查设备；未确认受理前不要当作开启成功 |
| `cancelled` | 操作因断开、解绑或释放被取消，根据当前页面状态决定是否重试 |
| `streamOverflow` | 减少主线程处理时间，处理积压并重新订阅，识别波形缺口 |
| Android 找不到依赖 | 检查 Maven 根目录、版本号、完整 ZIP 及远端仓库是否可访问 |
| iOS 找不到模块 / 启动提示动态库缺失 | 检查 8 个 XCFramework 是否加入正确的 App target 并全部 Embed & Sign |
| iOS 模拟器提示缺少匹配切片 | 当前交付包用于真机，请选择真机或准备专用模拟器依赖 |

## 9. 接入验收

先完成宿主 Debug / Release 构建及页面打开、退出验证，再使用实际手机和心电设备确认功能。构建成功本身不代表蓝牙与设备存卡已验收。

- 首次进入、扫码成功 / 取消、拒绝相机权限及恢复授权。
- 蓝牙授权 / 拒绝、蓝牙关闭、Android 旧版本定位权限与定位服务。
- 扫码绑定、连接、取消连接、关闭后重新进入并恢复绑定。
- 心率、电量、充电状态、导联情况、单导 / 12 导及走速 / 增益切换。
- 设备断线重连、主动断开、解绑后不再恢复旧目标。
- 正确用户标识开启 Holter、确认 / 取消、电量门槛、设备端实际存卡及状态计时。
- 退出后相机和蓝牙资源释放，连续重新打开；更换用户后使用新标识与预期绑定。
- Android 旋转或 Activity 重建、iOS pop / dismiss / 子控制器移除，以及宿主 Release 签名运行。

反馈问题时提供平台与系统版本、设备型号 / 固件、操作步骤、错误码、日志及对应 `build-info.json`；用户业务标识和个人信息按宿主自身要求处理。
