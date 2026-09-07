import Foundation
import RongIMLibCore
import UIKit

/// 通知中心：从融云消息 payload.`body` 解析展示文案与点击路由。
/// 对齐 funde-client notifications.md / MessagesView.vue / NotificationsView.vue
enum NotificationMessageMapper {

    struct Payload {
        var title: String
        var body: String
        var tag: String
        var icon: String
        var iconBg: String
        var iconColor: String
        var route: String?
    }

    static func payload(from rc: RCMessage) -> Payload? {
        payload(
            root: rootDictionary(from: rc),
            fallbackTitle: fallbackTitle(from: rc),
            fallbackBody: fallbackBody(from: rc),
            fallbackRoute: fallbackRoute(from: rc)
        )
    }

    static func payload(from msg: ChatMessage) -> Payload? {
        payload(
            root: rootDictionary(from: msg),
            fallbackTitle: {
                if let t = msg.sysNotifyContent?.title, !t.isEmpty { return t }
                return msg.senderName
            }(),
            fallbackBody: fallbackBody(from: msg),
            fallbackRoute: msg.sysNotifyContent?.urlKey ?? msg.vipContent?.urlKey
        )
    }

    /// `FundeH5:` 一律打开 H5；`FundeApp:` / `/path` 走本地别名后再 push（仅已注册）。
    @MainActor
    static func openRoute(_ raw: String?, from viewController: UIViewController?) {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return }

        if case .h5 = FundePageURL.parse(trimmed) {
            FundePageURL.open(trimmed, from: viewController)
            return
        }

        let parsed = normalizeRoute(trimmed)
        print("[通知中心-DAL] openRoute raw=\(trimmed) path=\(parsed.path) params=\(parsed.params)")
        guard !parsed.path.isEmpty, Router.shared.contains(parsed.path) else {
            print("[通知中心-DAL] skip unrecognized route raw=\(trimmed) path=\(parsed.path)")
            return
        }
        Router.shared.push(parsed.path, params: parsed.params, from: viewController)
    }

    /// 将 `businessData` 中的 `orderId` / `id` 拼入 `FundeApp:` 或 `/path` 路由，供 IM 卡片跳转与通知中心共用
    static func enrichedPageUrl(_ route: String, businessData: [String: Any]?) -> String {
        let trimmed = route.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let businessData else { return trimmed }
        return withBusinessId(trimmed, source: businessData) ?? trimmed
    }

    // MARK: - Parse

    private static func payload(
        root: [String: Any]?,
        fallbackTitle: String?,
        fallbackBody: String?,
        fallbackRoute: String?
    ) -> Payload? {
        let bodyValue = root?["body"]
        let bodyObject = IMCardJSON.parseObject(bodyValue)
        let bodyTextFromField = IMCardJSON.stringValue(bodyValue)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        print("[通知中心-DAL] payload keys=\(root?.keys.sorted().joined(separator: ",") ?? "nil") bodyType=\(bodyValue == nil ? "missing" : (bodyObject != nil ? "object" : "string")) body=\(bodyTextFromField ?? String(describing: bodyValue))")

        let source: [String: Any]
        if let bodyObject {
            source = bodyObject.merging(root ?? [:]) { current, _ in current }
        } else {
            source = root ?? [:]
        }

        let title = firstNonEmpty(
            IMCardJSON.stringValue(source["title"]),
            fallbackTitle
        ) ?? "系统通知"

        let body: String
        if let bodyObject {
            body = firstNonEmpty(
                IMCardJSON.stringValue(bodyObject["body"]),
                IMCardJSON.stringValue(bodyObject["content"]),
                fallbackBody
            ) ?? ""
        } else if let bodyTextFromField, !bodyTextFromField.isEmpty {
            body = bodyTextFromField
        } else {
            body = firstNonEmpty(
                IMCardJSON.stringValue(source["content"]),
                fallbackBody
            ) ?? ""
        }

        guard !body.isEmpty || bodyObject != nil || bodyTextFromField != nil else {
            let fallback = fallbackBody?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !fallback.isEmpty else { return nil }
            return styled(
                title: title,
                body: fallback,
                tag: firstNonEmpty(IMCardJSON.stringValue(source["tag"]), "系统通知") ?? "系统通知",
                icon: IMCardJSON.stringValue(source["icon"]),
                iconBg: IMCardJSON.stringValue(source["iconBg"]),
                iconColor: IMCardJSON.stringValue(source["iconColor"]),
                route: withBusinessId(
                    firstNonEmpty(
                        IMCardJSON.stringValue(source["route"]),
                        IMCardJSON.stringValue(source["url"]),
                        IMCardJSON.stringValue(source["urlKey"]),
                        IMCardJSON.stringValue(source["pageUrl"]),
                        fallbackRoute
                    ),
                    source: source
                )
            )
        }

        let displayBody = body.isEmpty ? (fallbackBody ?? "") : body
        guard !displayBody.isEmpty else { return nil }

        let route = withBusinessId(
            firstNonEmpty(
                IMCardJSON.stringValue(source["route"]),
                IMCardJSON.stringValue(source["url"]),
                IMCardJSON.stringValue(source["urlKey"]),
                IMCardJSON.stringValue(source["pageUrl"]),
                fallbackRoute
            ),
            source: source
        )

        let tag = firstNonEmpty(
            IMCardJSON.stringValue(source["tag"]),
            IMCardJSON.dataSourceTag(from: source),
            mappedTag(from: IMCardJSON.stringValue(source["type"])),
            "系统通知"
        ) ?? "系统通知"

        return styled(
            title: title,
            body: displayBody,
            tag: tag,
            icon: IMCardJSON.stringValue(source["icon"]),
            iconBg: IMCardJSON.stringValue(source["iconBg"]),
            iconColor: IMCardJSON.stringValue(source["iconColor"]),
            route: route
        )
    }

    private static func styled(
        title: String,
        body: String,
        tag: String,
        icon: String?,
        iconBg: String?,
        iconColor: String?,
        route: String?
    ) -> Payload {
        let style = style(for: tag)
        return Payload(
            title: title,
            body: body,
            tag: tag,
            icon: firstNonEmpty(sfSymbol(from: icon), style.icon) ?? "bell.fill",
            iconBg: firstNonEmpty(iconBg, style.bg) ?? "#EEF6FF",
            iconColor: firstNonEmpty(iconColor, style.color) ?? "#3D6FB8",
            route: route
        )
    }

    // MARK: - Root dict

    private static func rootDictionary(from rc: RCMessage) -> [String: Any]? {
        var merged: [String: Any] = [:]
        if let data = rc.content?.encode(),
           let obj = IMCardJSON.parseObject(data) {
            merged.merge(obj) { _, new in new }
        }
        if let extra = IMCardJSON.parseObject(rc.content?.extra) {
            merged.merge(extra) { current, _ in current }
        }
        if let text = rc.content as? RCTextMessage,
           let obj = IMCardJSON.parseObject(text.content) {
            merged.merge(obj) { current, _ in current }
        }
        flattenNestedJSON(into: &merged)
        return merged.isEmpty ? nil : merged
    }

    private static func rootDictionary(from msg: ChatMessage) -> [String: Any]? {
        var merged: [String: Any] = [:]
        if let extra = IMCardJSON.parseObject(msg.extra) {
            merged.merge(extra) { _, new in new }
        }
        if let notify = msg.sysNotifyContent {
            if let title = notify.title { merged["title"] = title }
            if let content = notify.content { merged["content"] = content }
            if let urlKey = notify.urlKey { merged["urlKey"] = urlKey }
            if let extra = IMCardJSON.parseObject(notify.extra) {
                merged.merge(extra) { current, _ in current }
            }
            if let biz = IMCardJSON.parseObject(notify.businessData) {
                merged.merge(biz) { current, _ in current }
            }
            if let contentObj = IMCardJSON.parseObject(notify.content) {
                merged.merge(contentObj) { current, _ in current }
            }
        }
        if let text = msg.text, let obj = IMCardJSON.parseObject(text) {
            merged.merge(obj) { current, _ in current }
        }
        flattenNestedJSON(into: &merged)
        return merged.isEmpty ? nil : merged
    }

    private static func flattenNestedJSON(into merged: inout [String: Any]) {
        if let extra = IMCardJSON.parseObject(merged["extra"]) {
            merged.merge(extra) { current, _ in current }
        }
        if let biz = IMCardJSON.parseObject(merged["businessData"]) {
            merged.merge(biz) { current, _ in current }
        }
    }

    private static func fallbackTitle(from rc: RCMessage) -> String? {
        if let notify = rc.content as? SysNotifyMessage { return notify.title }
        if let vip = rc.content as? VipMessage { return vip.title }
        return rc.content?.senderUserInfo?.name
    }

    private static func fallbackBody(from rc: RCMessage) -> String? {
        Conversation.lastMessageText(from: rc.content)
    }

    private static func fallbackBody(from msg: ChatMessage) -> String? {
        if let notify = msg.sysNotifyContent {
            return firstNonEmpty(notify.content, notify.conversationDigest())
        }
        return firstNonEmpty(msg.text, msg.vipContent?.conversationDigest())
    }

    private static func fallbackRoute(from rc: RCMessage) -> String? {
        if let notify = rc.content as? SysNotifyMessage { return notify.urlKey }
        if let vip = rc.content as? VipMessage { return vip.urlKey }
        return nil
    }

    // MARK: - Route

    static func normalizeRoute(_ raw: String) -> (path: String, params: [String: Any]) {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix(FundePageURL.appPrefix) {
            value = String(value.dropFirst(FundePageURL.appPrefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let parts = splitPathAndQuery(value)
        var path = aliasAppPath(parts.path)
        var params: [String: Any] = parts.query

        let reserved = Set(["detail", "confirm", "shipment-records"])
        if path.hasPrefix("/orders/") {
            let rest = String(path.dropFirst("/orders/".count))
            if !rest.isEmpty, !rest.contains("/"), !reserved.contains(rest) {
                path = "/orders/detail"
                if params["id"] == nil { params["id"] = rest }
            }
        }
        return (path, params)
    }

    /// 后端常见单数 path → App 已注册的复数 path
    private static func aliasAppPath(_ path: String) -> String {
        if path == "/order" { return "/orders" }
        if path.hasPrefix("/order/") {
            return "/orders/" + String(path.dropFirst("/order/".count))
        }
        return path
    }

    /// `urlKey` 常只有 path，订单 id 在 businessData
    private static func withBusinessId(_ route: String?, source: [String: Any]) -> String? {
        guard var route, !route.isEmpty else { return route }
        let id = firstNonEmpty(
            IMCardJSON.stringValue(source["orderId"]),
            IMCardJSON.stringValue(source["id"])
        )
        guard let id, !id.isEmpty else { return route }
        let lower = route.lowercased()
        if lower.contains("orderid=") || (lower.contains("?") && lower.contains("id=")) {
            return route
        }
        let sep = route.contains("?") ? "&" : "?"
        return route + "\(sep)orderId=\(id)&id=\(id)"
    }

    private static func splitPathAndQuery(_ raw: String) -> (path: String, query: [String: Any]) {
        guard let qIndex = raw.firstIndex(of: "?") else {
            return (raw, [:])
        }
        let path = String(raw[..<qIndex])
        let queryString = String(raw[raw.index(after: qIndex)...])
        var query: [String: Any] = [:]
        for pair in queryString.split(separator: "&") where !pair.isEmpty {
            let kv = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            let key = kv.first.map(String.init)?.removingPercentEncoding ?? kv.first.map(String.init) ?? ""
            guard !key.isEmpty else { continue }
            let value: String
            if kv.count > 1 {
                let rawValue = String(kv[1])
                value = rawValue.removingPercentEncoding ?? rawValue
            } else {
                value = ""
            }
            query[key] = value
        }
        return (path, query)
    }

    // MARK: - Style

    private static func style(for tag: String) -> (icon: String, bg: String, color: String) {
        switch tag {
        case "预约提醒":
            return ("calendar", "#EAF3FF", "#3D6FB8")
        case "保单":
            return ("checkmark.shield", "#FFF3DC", "#B47300")
        case "设备", "设备/指标", "指标":
            return ("heart.fill", "#FFE9DF", "#FF7A50")
        case "报告":
            return ("doc.text", "#E6F7EF", "#1F9A6B")
        case "订单消息":
            return ("creditcard", "#E7F8F0", "#4aa65f")
        case "退款售后":
            return ("arrow.uturn.left", "#fff2e7", "#e09c1d")
        case "监测任务", "药养监测":
            return ("waveform.path.ecg", "#FFE9DF", "#FF7A50")
        default:
            return ("bell.fill", "#EEF6FF", "#3D6FB8")
        }
    }

    private static func mappedTag(from type: String?) -> String? {
        switch type?.lowercased() {
        case "order": return "订单消息"
        case "realtime": return "监测任务"
        case "appointment": return "预约提醒"
        case "policy": return "保单"
        case "device", "monitor": return "设备"
        case "report": return "报告"
        default: return nil
        }
    }

    private static func sfSymbol(from icon: String?) -> String? {
        guard let icon, !icon.isEmpty else { return nil }
        if !icon.contains(":") && !icon.contains("-") { return icon }
        let map: [String: String] = [
            "mingcute:calendar-2-line": "calendar",
            "mingcute:shield-check-line": "checkmark.shield",
            "mingcute:heartbeat-line": "heart.fill",
            "mingcute:document-2-line": "doc.text",
            "payment-success": "creditcard",
            "shipped": "shippingbox",
            "service-expiring": "clock",
            "device-overdue": "exclamationmark.triangle",
            "return-pending": "arrow.uturn.left",
            "refund-rejected": "xmark.circle",
        ]
        return map[icon]
    }

    private static func firstNonEmpty(_ values: String?...) -> String? {
        for value in values {
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }
}
