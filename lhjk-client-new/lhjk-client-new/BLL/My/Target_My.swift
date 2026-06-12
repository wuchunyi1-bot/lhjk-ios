import UIKit

/// 「我的」模块路由 Target
/// 命名规范：Target_My → Router 通过 lhjk_client.Target_My 反射调用
final class Target_My: NSObject {

    // MARK: - Hub

    @objc func Action_home(_ params: NSDictionary) -> UIViewController? {
        return MyViewController()
    }

    // MARK: - Settings

    @objc func Action_settings(_ params: NSDictionary) -> UIViewController? {
        return SettingsViewController()
    }

    // MARK: - Profile

    @objc func Action_profile(_ params: NSDictionary) -> UIViewController? {
        return ProfileViewController()
    }

    // MARK: - Policy

    @objc func Action_policy(_ params: NSDictionary) -> UIViewController? {
        return PolicyViewController()
    }

    // MARK: - Health Report

    @objc func Action_healthReport(_ params: NSDictionary) -> UIViewController? {
        return HealthReportViewController()
    }

    // MARK: - Appointments

    @objc func Action_appointments(_ params: NSDictionary) -> UIViewController? {
        return AppointmentsViewController()
    }

    // MARK: - Devices

    @objc func Action_devices(_ params: NSDictionary) -> UIViewController? {
        return DevicesViewController()
    }

    // MARK: - Diet Plan

    @objc func Action_dietPlan(_ params: NSDictionary) -> UIViewController? {
        return DietPlanViewController()
    }

    // MARK: - Monitoring Plan

    @objc func Action_monitoringPlan(_ params: NSDictionary) -> UIViewController? {
        return MonitoringPlanViewController()
    }

    // MARK: - Health Evaluations

    @objc func Action_healthEvaluations(_ params: NSDictionary) -> UIViewController? {
        return HealthEvaluationsViewController()
    }
}
