import Foundation
import UIKit

/// 健康模块路由注册
enum HealthRoutes {

    /// 兼容历史深链的子路径；映射为 H5 子页面（见 `H5Config` / OpenSpec）
    private static let metricSubPaths: [String: [String]] = [
        "blood-pressure": ["add", "manual", "history", "service", "detail"],
        "blood-sugar": ["add", "manual", "history", "service", "detail"],
        "weight": ["add", "manual", "history", "service", "detail"],
        "heart-rate": ["add", "manual"],
        "temperature": ["add"],
        "spo2": ["add"],
        "exercise": ["home", "add-diet", "add-motion", "search"],
    ]

    static func register() {
        let r = Router.shared

        // Hub
        r.register(path: "/health") { _ in HealthViewController() }

        // 健康档案 → H5 `#/health/record`（宿主接入文档）
        r.register(path: "/health/record") { _ in
            WebViewController(
                urlString: H5Config.healthRecordPageURL.absoluteString,
                title: "健康档案"
            )
        }

        // 用药 / 营养补剂 / 血氧短链 → H5（与文档 hash 对齐）
        r.register(path: "/medication") { _ in
            WebViewController(
                urlString: H5Config.medicationPageURL.absoluteString,
                title: "用药"
            )
        }
        r.register(path: "/supplement") { _ in
            WebViewController(
                urlString: H5Config.supplementPageURL.absoluteString,
                title: "营养补剂"
            )
        }
        r.register(path: "/spo2") { _ in
            WebViewController(
                urlString: H5Config.spo2PageURL.absoluteString,
                title: "血氧"
            )
        }

        // 原生子页路由保留（深链兼容）；主入口已迁 H5
        r.register(path: "/health/record/profile") { _ in PlaceholderViewController(title: "基础信息") }
        r.register(path: "/health/record/history") { _ in PlaceholderViewController(title: "健康史") }
        r.register(path: "/health/record/lifestyle") { _ in PlaceholderViewController(title: "生活习惯") }
        r.register(path: "/health/record/condition") { _ in PlaceholderViewController(title: "慢病标签") }
        // 编辑卡片（替换旧体征监测网格页）
        r.register(path: "/health/metrics/edit") { _ in MetricCardEditViewController() }
        r.register(path: "/health/metrics") { _ in MetricCardEditViewController() }
        r.register(path: "/health/assessment/six-dim") { _ in PlaceholderViewController(title: "六维评测") }
        r.register(path: "/health/assessment/report") { _ in HealthReportViewController() }
        r.register(path: "/health/assessment/risk") { _ in PlaceholderViewController(title: "风险评估") }

        // OKOK 广播体脂秤原生测量（不连 GATT）
        r.register(path: "/health/scale/measure") { _ in ScaleBroadcastMeasureViewController() }
        r.register(path: "/health/scale/devices") { _ in ScaleDeviceSelectViewController() }
        r.register(path: "/health/scale/bind") { params in
            ScaleDeviceBindViewController(
                equipmentTypeId: stringParam(params["equipmentType"]) ?? "",
                bluetoothName: stringParam(params["bluetoothName"]) ?? "OKOK",
                displayName: stringParam(params["equipmentName"]) ?? "OKOK 体脂秤"
            )
        }
        r.register(path: "/health/metrics/weight/scale/result") { params in
            WeightScaleResultViewController(monitorId: stringParam(params["monitorId"]) ?? "")
        }

        registerAllMetricH5Routes(r)
    }

    // MARK: - 体征监测 H5

    private static func registerAllMetricH5Routes(_ r: Router) {
        for (key, title) in H5Config.metricKeys {
            registerMetricH5(r, key: key, title: title)
            for suffix in metricSubPaths[key] ?? [] {
                registerMetricH5(r, key: key, title: title, pathSuffix: suffix)
            }
        }

        r.register(path: "/health/metrics/add") { params in
            let key = stringParam(params["key"]) ?? ""
            return metricWebView(for: key, routeParams: params)
        }
    }

    private static func registerMetricH5(
        _ r: Router,
        key: String,
        title: String,
        pathSuffix: String? = nil
    ) {
        let path: String
        if let pathSuffix, !pathSuffix.isEmpty {
            path = "/health/metrics/\(key)/\(pathSuffix)"
        } else {
            path = "/health/metrics/\(key)"
        }
        r.register(path: path) { params in
            metricWebView(
                for: key,
                title: title,
                nativeSuffix: pathSuffix,
                routeParams: params
            )
        }
    }

    private static func metricWebView(
        for key: String,
        title: String? = nil,
        nativeSuffix: String? = nil,
        routeParams: [String: Any] = [:]
    ) -> UIViewController {
        let url = H5Config.authenticatedMetricURL(
            metricKey: key,
            nativeSuffix: nativeSuffix,
            routeParams: routeParams
        )
        let resolvedTitle = title ?? H5Config.metricTitle(for: key)
        let enablesWeightBle: Bool
        if key == "weight" {
            if let nativeSuffix, !nativeSuffix.isEmpty {
                enablesWeightBle = FundePageURL.shouldEnableWeightBle(forH5Path: "weight/\(nativeSuffix)")
            } else {
                enablesWeightBle = true
            }
        } else {
            enablesWeightBle = false
        }
        return WebViewController(
            urlString: url.absoluteString,
            title: resolvedTitle,
            enablesWeightBle: enablesWeightBle
        )
    }

    private static func stringParam(_ value: Any?) -> String? {
        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return nil
    }
}
