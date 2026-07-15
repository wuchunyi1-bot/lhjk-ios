import Foundation

/// 健康模块路由注册
enum HealthRoutes {

    static func register() {
        let r = Router.shared

        // Hub
        r.register(path: "/health") { _ in HealthViewController() }

        // Sub pages
        r.register(path: "/health/record") { _ in HealthRecordViewController() }

        // Health record sub-pages (deferred — placeholder)
        r.register(path: "/health/record/profile") { _ in PlaceholderViewController(title: "基础信息") }
        r.register(path: "/health/record/history") { _ in PlaceholderViewController(title: "健康史") }
        r.register(path: "/health/record/lifestyle") { _ in PlaceholderViewController(title: "生活习惯") }
        r.register(path: "/health/record/condition") { _ in PlaceholderViewController(title: "慢病标签") }
        r.register(path: "/health/metrics") { _ in MetricsViewController() }
        r.register(path: "/health/assessment/six-dim") { _ in PlaceholderViewController(title: "六维评测") }
        r.register(path: "/health/assessment/report") { _ in HealthReportViewController() }
        r.register(path: "/health/assessment/risk") { _ in PlaceholderViewController(title: "风险评估") }

        // 已实现的指标详情页
        // Hub：Funde 风格展示页 + Angel API
        r.register(path: "/health/metrics/blood-pressure") { _ in BloodPressureViewController() }
        r.register(path: "/health/metrics/blood-pressure/manual") { _ in BloodPressureManualViewController() }
        r.register(path: "/health/metrics/blood-pressure/history") { _ in BloodPressureHistoryViewController() }
        r.register(path: "/health/metrics/blood-pressure/service") { _ in BloodPressureServiceViewController() }
        r.register(path: "/health/metrics/blood-pressure/detail") { params in
            let monitorId = params["monitorId"] as? String
            return BloodPressureDetailViewController(monitorId: monitorId)
        }
        r.register(path: "/health/metrics/blood-sugar") { _ in BloodSugarViewController() }
        r.register(path: "/health/metrics/blood-sugar/manual") { _ in BloodSugarManualViewController() }
        r.register(path: "/health/metrics/blood-sugar/history") { _ in BloodSugarHistoryViewController() }
        r.register(path: "/health/metrics/blood-sugar/service") { _ in BloodSugarServiceViewController() }
        r.register(path: "/health/metrics/blood-sugar/detail") { params in
            let monitorId = params["monitorId"] as? String
            let sugarId = params["sugarId"] as? String
            return BloodSugarDetailViewController(monitorId: monitorId, sugarId: sugarId)
        }
        // 体重模块已整体接入 H5，App 不再承载录入/展示/详情原生页
        // 相关原生代码暂保留，仅路由切换至 WebView
        r.register(path: "/health/metrics/weight") { _ in
            WebViewController(urlString: H5Config.weightPageURL.absoluteString, title: "体重")
        }
        r.register(path: "/health/metrics/weight/manual") { _ in
            WebViewController(urlString: H5Config.weightPageURL.absoluteString, title: "体重")
        }
        r.register(path: "/health/metrics/weight/history") { _ in
            WebViewController(urlString: H5Config.weightPageURL.absoluteString, title: "体重")
        }
        r.register(path: "/health/metrics/weight/service") { _ in
            WebViewController(urlString: H5Config.weightPageURL.absoluteString, title: "体重")
        }
        r.register(path: "/health/metrics/weight/detail") { _ in
            WebViewController(urlString: H5Config.weightPageURL.absoluteString, title: "体重")
        }
        r.register(path: "/health/metrics/heart-rate")     { _ in HeartRateViewController() }

        r.register(path: "/health/metrics/sleep") { _ in SleepViewController() }

        r.register(path: "/health/metrics/spo2")   { _ in SpO2ViewController() }
        r.register(path: "/health/metrics/ecg")    { _ in EcgViewController() }
        r.register(path: "/health/metrics/fundus") { _ in FundusViewController() }
        r.register(path: "/health/metrics/exercise") { _ in ExerciseFoodViewController() }
        r.register(path: "/health/metrics/exercise/home") { _ in ExerciseFoodHomeViewController() }
        r.register(path: "/health/metrics/exercise/add-diet") { params in
            let timeType = Self.intParam(params, key: "timeType")
            let date = params["date"] as? String ?? Self.todayDateString()
            return ExerciseFoodAddDietViewController(timeType: timeType, dateString: date)
        }
        r.register(path: "/health/metrics/exercise/add-motion") { params in
            let date = params["date"] as? String ?? Self.todayDateString()
            return ExerciseFoodAddMotionViewController(dateString: date)
        }
        r.register(path: "/health/metrics/exercise/search") { params in
            let type = Self.intParam(params, key: "type") ?? ExerciseFoodConstants.definitionTypeFood
            return ExerciseFoodSearchViewController(type: type)
        }
        r.register(path: "/health/metrics/digestive") { _ in DigestiveViewController() }

        r.register(path: "/health/metrics/add") { params in
            let key = params["key"] as? String ?? ""
            if key == "blood-pressure" {
                return BloodPressureManualViewController()
            }
            if key == "blood-sugar" {
                return BloodSugarManualViewController()
            }
            if key == "weight" {
                return WebViewController(urlString: H5Config.weightPageURL.absoluteString, title: "体重")
            }
            return MetricAddViewController(metricKey: key)
        }
    }

    private static func intParam(_ params: [String: Any], key: String) -> Int? {
        if let value = params[key] as? Int { return value }
        if let value = params[key] as? String { return Int(value) }
        return nil
    }

    private static func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
