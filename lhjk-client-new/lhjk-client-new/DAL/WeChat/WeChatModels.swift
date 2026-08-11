import Foundation
import UIKit

// MARK: - Errors

enum WeChatSDKError: Error, LocalizedError, Equatable {
    case notConfigured
    case sdkNotLinked
    case notInstalled
    case notSupported
    case sendFailed
    case userCancelled
    case authDenied
    case payFailed(code: Int, message: String)
    case underlying(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "微信尚未配置 AppID / Universal Link"
        case .sdkNotLinked:
            return "未集成微信 Open SDK，请启用 WechatOpenSDK-XCFramework 后重试"
        case .notInstalled:
            return "当前设备未安装微信"
        case .notSupported:
            return "当前微信版本不支持该功能"
        case .sendFailed:
            return "调起微信失败"
        case .userCancelled:
            return "已取消"
        case .authDenied:
            return "微信授权被拒绝"
        case .payFailed(_, let message):
            return message.isEmpty ? "微信支付失败" : message
        case .underlying(let message):
            return message
        }
    }
}

// MARK: - Share scene

enum WeChatShareScene: Int {
    /// 聊天界面
    case session = 0
    /// 朋友圈（小程序卡片不支持）
    case timeline = 1
    /// 收藏
    case favorite = 2
}

enum WeChatMiniProgramType: Int {
    case release = 0
    case test = 1
    case preview = 2
}

// MARK: - Share payloads

struct WeChatWebpageSharePayload {
    var title: String
    var description: String
    var webpageURL: String
    var thumbImage: UIImage?
    var scene: WeChatShareScene

    init(
        title: String,
        description: String = "",
        webpageURL: String,
        thumbImage: UIImage? = nil,
        scene: WeChatShareScene = .session
    ) {
        self.title = title
        self.description = description
        self.webpageURL = webpageURL
        self.thumbImage = thumbImage
        self.scene = scene
    }
}

/// 分享小程序卡片（会话）
struct WeChatMiniProgramSharePayload {
    /// 兼容低版本的网页兜底 URL（微信必填）
    var webpageURL: String
    /// 小程序原始 id；空则用 `WeChatConfig.miniProgramUserName`
    var userName: String
    /// 小程序页面 path（可带 query，如 `pages/benefit-card/receive/index?operationNo=xxx`）
    var path: String
    var title: String
    var description: String
    var hdImage: UIImage?
    var hdImageData: Data?
    var miniProgramType: WeChatMiniProgramType
    var withShareTicket: Bool

    init(
        webpageURL: String,
        userName: String = "",
        path: String,
        title: String,
        description: String = "",
        hdImage: UIImage? = nil,
        hdImageData: Data? = nil,
        miniProgramType: WeChatMiniProgramType = .release,
        withShareTicket: Bool = false
    ) {
        self.webpageURL = webpageURL
        self.userName = userName
        self.path = path
        self.title = title
        self.description = description
        self.hdImage = hdImage
        self.hdImageData = hdImageData
        self.miniProgramType = miniProgramType
        self.withShareTicket = withShareTicket
    }

    var resolvedUserName: String {
        let custom = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty { return custom }
        return WeChatConfig.miniProgramUserName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Auth

struct WeChatAuthRequest {
    var scope: String
    var state: String

    init(scope: String = "snsapi_userinfo", state: String = UUID().uuidString) {
        self.scope = scope
        self.state = state
    }
}

struct WeChatAuthResult: Equatable {
    let code: String
    let state: String?
    let lang: String?
    let country: String?
}

// MARK: - Pay（服务端预下单字段）

struct WeChatPayRequest: Equatable {
    var partnerId: String
    var prepayId: String
    var nonceStr: String
    var timeStamp: String
    var package: String
    var sign: String

    init(
        partnerId: String,
        prepayId: String,
        nonceStr: String,
        timeStamp: String,
        package: String = "Sign=WXPay",
        sign: String
    ) {
        self.partnerId = partnerId
        self.prepayId = prepayId
        self.nonceStr = nonceStr
        self.timeStamp = timeStamp
        self.package = package
        self.sign = sign
    }
}

struct WeChatPayResult: Equatable {
    let returnKey: String?
}
