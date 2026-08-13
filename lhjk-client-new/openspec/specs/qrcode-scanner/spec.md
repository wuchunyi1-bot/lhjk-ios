# 二维码扫描 (QR Code Scanner)

## Purpose

DAL 封装系统 `AVFoundation` 扫码能力（**无第三方 SDK**），供绑定权益卡等业务复用。

## 现状

工程内原无扫码实现；Podfile 无 ZXing / ZBar 等依赖。采用系统 `AVCaptureMetadataOutput` 识别二维码与常见条码。

## API

| 类型 | 说明 |
|------|------|
| `QRCodeScanner` | 会话：权限、预览层、start/stop、`onCodeScanned` |
| `QRCodeScanViewController` | 全屏「扫描二维码」页 |

路由（可选）：`/scan/qrcode`

## 绑定页

「扫码绑定」→ push `QRCodeScanViewController` → 回填卡密（支持纯文本 / URL query：`benefitsKey`/`key`/`code`）。

## 工程配置（开发者）

在 `Info.plist` 增加：

```xml
<key>NSCameraUsageDescription</key>
<string>用于扫描权益卡二维码完成绑定</string>
```

并将 `DAL/QRCode/QRCodeScanner.swift` 加入 Xcode Target。
