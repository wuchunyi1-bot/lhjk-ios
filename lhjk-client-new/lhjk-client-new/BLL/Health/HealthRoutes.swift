import Foundation

/// 健康模块路由注册
enum HealthRoutes {

    static func register() {
        let r = Router.shared

        // Hub
        r.register(path: "/health") { _ in HealthViewController() }

        // Sub pages
        r.register(path: "/health/record") { _ in PlaceholderViewController(title: "健康档案") }
        r.register(path: "/health/metrics") { _ in PlaceholderViewController(title: "体征监测") }
        r.register(path: "/health/assessment/six-dim") { _ in PlaceholderViewController(title: "六维评测") }
        r.register(path: "/health/assessment/report") { _ in PlaceholderViewController(title: "我的报告") }
        r.register(path: "/health/assessment/risk") { _ in PlaceholderViewController(title: "风险评估") }

        // 已实现的指标详情页（含 DGCharts）
        r.register(path: "/health/metrics/blood-pressure") { _ in BloodPressureViewController() }
        r.register(path: "/health/metrics/blood-sugar")    { _ in BloodSugarViewController() }
        r.register(path: "/health/metrics/weight")         { _ in WeightViewController() }
        r.register(path: "/health/metrics/heart-rate")     { _ in HeartRateViewController() }

        r.register(path: "/health/metrics/sleep") { _ in SleepViewController() }

        r.register(path: "/health/metrics/spo2")   { _ in SpO2ViewController() }
        r.register(path: "/health/metrics/ecg")    { _ in EcgViewController() }
        r.register(path: "/health/metrics/fundus") { _ in FundusViewController() }
        r.register(path: "/health/metrics/exercise") { _ in ExerciseFoodViewController() }
        r.register(path: "/health/metrics/digestive") { _ in DigestiveViewController() }

        r.register(path: "/health/metrics/add") { params in
            let key = params["key"] as? String ?? ""
            return MetricAddViewController(metricKey: key)
        }
    }
}
