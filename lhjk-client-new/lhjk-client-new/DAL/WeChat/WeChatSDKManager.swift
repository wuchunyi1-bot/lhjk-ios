import Foundation
import UIKit

#if canImport(WechatOpenSDK)
import WechatOpenSDK
private let wechatOpenSDKLinked = true
#else
private let wechatOpenSDKLinked = false
#endif

/// 微信 Open SDK 统一入口（登录 / 分享 / 支付）
///
/// 官方 Open SDK **同一套库**覆盖三类能力；本类型为工程内唯一建议的 `WXApiDelegate` 持有者。
final class WeChatSDKManager: NSObject {

    static let shared = WeChatSDKManager()

    private(set) var isRegistered = false

    private var shareCompletion: ((Result<Void, WeChatSDKError>) -> Void)?
    private var authCompletion: ((Result<WeChatAuthResult, WeChatSDKError>) -> Void)?
    private var payCompletion: ((Result<WeChatPayResult, WeChatSDKError>) -> Void)?
    /// 当前授权请求的 state，回调时须一致
    private var pendingAuthState: String?

    private override init() {
        super.init()
    }

    // MARK: - Register

    /// App 启动时调用一次
    func register(appId: String = WeChatConfig.appId, universalLink: String = WeChatConfig.universalLink) {
        let id = appId.trimmingCharacters(in: .whitespacesAndNewlines)
        let link = universalLink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty, !link.isEmpty else {
            print("[WeChatSDK] register skipped — AppID / Universal Link 未配置（见 WeChatConfig）")
            isRegistered = false
            return
        }

        #if canImport(WechatOpenSDK)
        let ok = WXApi.registerApp(id, universalLink: link)
        isRegistered = ok
        print("[WeChatSDK] registerApp → \(ok ? "✓" : "✗") appId=\(id)")
        #else
        isRegistered = false
        print("[WeChatSDK] register skipped — WechatOpenSDK 未链接（请 pod 集成 WechatOpenSDK-XCFramework）")
        #endif
    }

    // MARK: - Capability

    var isSDKLinked: Bool { wechatOpenSDKLinked }

    var isWeChatInstalled: Bool {
        #if canImport(WechatOpenSDK)
        return WXApi.isWXAppInstalled()
        #else
        return false
        #endif
    }

    var isWeChatAppSupportApi: Bool {
        #if canImport(WechatOpenSDK)
        return WXApi.isWXAppSupport()
        #else
        return false
        #endif
    }

    // MARK: - URL callbacks

    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool {
        #if canImport(WechatOpenSDK)
        return WXApi.handleOpen(url, delegate: self)
        #else
        return false
        #endif
    }

    @discardableResult
    func handleUniversalLink(_ userActivity: NSUserActivity) -> Bool {
        #if canImport(WechatOpenSDK)
        return WXApi.handleOpenUniversalLink(userActivity, delegate: self)
        #else
        return false
        #endif
    }

    // MARK: - Share

    func shareWebpage(
        _ payload: WeChatWebpageSharePayload,
        completion: @escaping (Result<Void, WeChatSDKError>) -> Void
    ) {
        guard ensureReady(completion: completion) else { return }

        #if canImport(WechatOpenSDK)
        let object = WXWebpageObject()
        object.webpageUrl = payload.webpageURL

        let message = WXMediaMessage()
        message.title = payload.title
        message.description = payload.description
        message.mediaObject = object
        if let image = payload.thumbImage {
            message.setThumbImage(image)
        }

        let req = SendMessageToWXReq()
        req.bText = false
        req.message = message
        req.scene = Int32(payload.scene.rawValue)

        shareCompletion = completion
        WXApi.send(req) { [weak self] success in
            if !success {
                self?.finishShare(.failure(.sendFailed))
            }
        }
        #endif
    }

    func shareMiniProgram(
        _ payload: WeChatMiniProgramSharePayload,
        completion: @escaping (Result<Void, WeChatSDKError>) -> Void
    ) {
        guard ensureReady(completion: completion) else { return }

        let userName = payload.resolvedUserName
        guard !userName.isEmpty else {
            print("[WeChatSDK] shareMiniProgram ✗ missing miniProgramUserName")
            completion(.failure(.underlying("未配置小程序原始 id（WeChatConfig.miniProgramUserName）")))
            return
        }

        #if canImport(WechatOpenSDK)
        let object = WXMiniProgramObject()
        object.webpageUrl = payload.webpageURL
        object.userName = userName
        object.path = payload.path
        object.withShareTicket = payload.withShareTicket
        switch payload.miniProgramType {
        case .release: object.miniProgramType = .release
        case .test: object.miniProgramType = .test
        case .preview: object.miniProgramType = .preview
        }

        // 微信限制：hdImageData ≤ 128KB，否则 WXApi.send 常直接失败
        let hdData = Self.compressedImageData(
            raw: payload.hdImageData,
            image: payload.hdImage,
            maxBytes: 128 * 1024
        )
        object.hdImageData = hdData

        let message = WXMediaMessage()
        message.title = payload.title
        message.description = payload.description
        message.mediaObject = object
        if let thumb = Self.compressedThumbImage(from: payload.hdImage, data: hdData) {
            message.setThumbImage(thumb)
        }

        let req = SendMessageToWXReq()
        req.bText = false
        req.message = message
        req.scene = Int32(WeChatShareScene.session.rawValue)

        print("""
        [WeChatSDK] shareMiniProgram → send
          registered=\(isRegistered) installed=\(isWeChatInstalled) support=\(isWeChatAppSupportApi)
          openAppId=\(WeChatConfig.appId)
          userName=\(userName) type=\(payload.miniProgramType.rawValue)
          path=\(payload.path)
          webpageUrl=\(payload.webpageURL)
          title=\(payload.title)
          descLen=\(payload.description.count) hdBytes=\(hdData?.count ?? 0)
        """)

        shareCompletion = completion
        WXApi.send(req) { [weak self] success in
            if success {
                print("[WeChatSDK] shareMiniProgram send callback ✓ (等待微信 onResp)")
            } else {
                print("""
                [WeChatSDK] shareMiniProgram send callback ✗ → sendFailed
                  registered=\(self?.isRegistered ?? false)
                  installed=\(self?.isWeChatInstalled ?? false)
                  support=\(self?.isWeChatAppSupportApi ?? false)
                  tip=常见原因: Universal Link/AppID 未配对、未关联小程序、hdImage>128KB、模拟器无微信
                """)
                self?.finishShare(.failure(.sendFailed))
            }
        }
        #else
        print("[WeChatSDK] shareMiniProgram ✗ SDK not linked")
        completion(.failure(.sdkNotLinked))
        #endif
    }

    // MARK: - Login

    func sendAuth(
        _ request: WeChatAuthRequest = WeChatAuthRequest(),
        completion: @escaping (Result<WeChatAuthResult, WeChatSDKError>) -> Void
    ) {
        guard ensureReady(completion: completion) else { return }

        #if canImport(WechatOpenSDK)
        let req = SendAuthReq()
        req.scope = request.scope
        req.state = request.state
        pendingAuthState = request.state
        authCompletion = completion
        WXApi.send(req) { [weak self] success in
            if !success {
                self?.pendingAuthState = nil
                self?.finishAuth(.failure(.sendFailed))
            }
        }
        #endif
    }

    // MARK: - Pay

    func pay(
        _ request: WeChatPayRequest,
        completion: @escaping (Result<WeChatPayResult, WeChatSDKError>) -> Void
    ) {
        guard ensureReady(completion: completion) else { return }

        #if canImport(WechatOpenSDK)
        let req = PayReq()
        req.partnerId = request.partnerId
        req.prepayId = request.prepayId
        req.nonceStr = request.nonceStr
        req.timeStamp = UInt32(request.timeStamp) ?? 0
        req.package = request.package
        req.sign = request.sign

        payCompletion = completion
        WXApi.send(req) { [weak self] success in
            if !success {
                self?.finishPay(.failure(.sendFailed))
            }
        }
        #endif
    }

    // MARK: - Private helpers

    private func ensureReady<T>(completion: (Result<T, WeChatSDKError>) -> Void) -> Bool {
        #if !canImport(WechatOpenSDK)
        print("[WeChatSDK] ensureReady ✗ sdkNotLinked")
        completion(.failure(.sdkNotLinked))
        return false
        #else
        if !isRegistered {
            print("[WeChatSDK] ensureReady: not registered yet → try register now")
            register()
        }
        guard WeChatConfig.isConfigured, isRegistered else {
            print("[WeChatSDK] ensureReady ✗ notConfigured isConfigured=\(WeChatConfig.isConfigured) registered=\(isRegistered) appId=\(WeChatConfig.appId)")
            completion(.failure(.notConfigured))
            return false
        }
        guard isWeChatInstalled else {
            print("[WeChatSDK] ensureReady ✗ notInstalled")
            completion(.failure(.notInstalled))
            return false
        }
        if !isWeChatAppSupportApi {
            print("[WeChatSDK] ensureReady warn: isWXAppSupport=false（仍尝试 send）")
        }
        return true
        #endif
    }

    /// 压缩到不超过 `maxBytes`（微信小程序预览图限制 128KB）
    private static func compressedImageData(raw: Data?, image: UIImage?, maxBytes: Int) -> Data? {
        var data = raw
        if data == nil, let image {
            data = image.jpegData(compressionQuality: 0.7)
        }
        guard var data, !data.isEmpty else { return nil }
        if data.count <= maxBytes { return data }

        guard let image = image ?? UIImage(data: data) else {
            print("[WeChatSDK] compress skip: cannot decode image bytes=\(data.count)")
            return nil
        }

        var quality: CGFloat = 0.6
        var current = image.jpegData(compressionQuality: quality)
        while let bytes = current, bytes.count > maxBytes, quality > 0.1 {
            quality -= 0.1
            current = image.jpegData(compressionQuality: quality)
        }
        if let bytes = current, bytes.count > maxBytes {
            let scale = sqrt(CGFloat(maxBytes) / CGFloat(bytes.count))
            let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: size)
            let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
            current = resized.jpegData(compressionQuality: 0.5)
        }
        print("[WeChatSDK] compress image \(data.count) → \(current?.count ?? 0) bytes (max=\(maxBytes))")
        return current
    }

    private static func compressedThumbImage(from image: UIImage?, data: Data?) -> UIImage? {
        if let image { return image }
        if let data { return UIImage(data: data) }
        return nil
    }

    private func finishShare(_ result: Result<Void, WeChatSDKError>) {
        let cb = shareCompletion
        shareCompletion = nil
        switch result {
        case .success:
            print("[WeChatSDK] finishShare ✓")
        case .failure(let error):
            print("[WeChatSDK] finishShare ✗ \(error.localizedDescription)")
        }
        DispatchQueue.main.async { cb?(result) }
    }

    private func finishAuth(_ result: Result<WeChatAuthResult, WeChatSDKError>) {
        let cb = authCompletion
        authCompletion = nil
        pendingAuthState = nil
        DispatchQueue.main.async { cb?(result) }
    }

    private func finishPay(_ result: Result<WeChatPayResult, WeChatSDKError>) {
        let cb = payCompletion
        payCompletion = nil
        DispatchQueue.main.async { cb?(result) }
    }
}

// MARK: - WXApiDelegate

#if canImport(WechatOpenSDK)
extension WeChatSDKManager: WXApiDelegate {

    func onReq(_ req: BaseReq) {
        // 微信主动请求本 App 的能力（暂不处理）
        print("[WeChatSDK] onReq type=\(req.type)")
    }

    func onResp(_ resp: BaseResp) {
        switch resp {
        case let r as SendMessageToWXResp:
            handleShareResp(r)
        case let r as SendAuthResp:
            handleAuthResp(r)
        case let r as PayResp:
            handlePayResp(r)
        default:
            print("[WeChatSDK] onResp unhandled errCode=\(resp.errCode) type=\(resp.type)")
        }
    }

    /// 与 Open SDK `WXErrCode` 对齐，避免不同模块枚举名差异
    private enum RespCode {
        static let success: Int32 = 0
        static let userCancel: Int32 = -2
        static let authDeny: Int32 = -4
    }

    private func handleShareResp(_ resp: SendMessageToWXResp) {
        print("[WeChatSDK] share onResp errCode=\(resp.errCode) errStr=\(resp.errStr)")
        switch resp.errCode {
        case RespCode.success:
            finishShare(.success(()))
        case RespCode.userCancel:
            finishShare(.failure(.userCancelled))
        default:
            let msg = resp.errStr
            finishShare(.failure(.underlying(msg.isEmpty ? "分享失败(\(resp.errCode))" : msg)))
        }
    }

    private func handleAuthResp(_ resp: SendAuthResp) {
        switch resp.errCode {
        case RespCode.success:
            let code = resp.code ?? ""
            let expected = pendingAuthState
            if code.isEmpty {
                finishAuth(.failure(.underlying("授权成功但未返回 code")))
            } else if let expected, resp.state != expected {
                print("[WeChatSDK] auth state mismatch expected=\(expected) got=\(resp.state ?? "nil")")
                finishAuth(.failure(.underlying("微信授权回调校验失败")))
            } else {
                finishAuth(.success(WeChatAuthResult(
                    code: code,
                    state: resp.state,
                    lang: resp.lang,
                    country: resp.country
                )))
            }
        case RespCode.userCancel:
            finishAuth(.failure(.userCancelled))
        case RespCode.authDeny:
            finishAuth(.failure(.authDenied))
        default:
            let msg = resp.errStr
            finishAuth(.failure(.underlying(msg.isEmpty ? "授权失败(\(resp.errCode))" : msg)))
        }
    }

    private func handlePayResp(_ resp: PayResp) {
        switch resp.errCode {
        case RespCode.success:
            finishPay(.success(WeChatPayResult(returnKey: resp.returnKey)))
        case RespCode.userCancel:
            finishPay(.failure(.userCancelled))
        default:
            let msg = resp.errStr
            finishPay(.failure(.payFailed(code: Int(resp.errCode), message: msg)))
        }
    }
}
#endif
