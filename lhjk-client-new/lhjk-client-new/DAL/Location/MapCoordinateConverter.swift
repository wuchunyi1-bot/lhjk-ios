import CoreLocation
import Foundation

// MARK: - MapCoordinateConverter

/// 高德地图坐标系 ⇄ 腾讯地图坐标系互转
///
/// - Important: `GET /v1/hospital/searchPage` 等接口文档标注「高德 GCJ-02」，
///   但后端实际按**腾讯地图坐标系**存取。设备 `CLLocation`（国内多为 GCJ-02 / 高德同系）
///   上报前须 `gaodeToTencent`；接口返回坐标若需与本地定位对齐则 `tencentToGaode`。
///
/// 算法：对 GCJ-02 同系坐标做非线性微调（不含百度 BD-09 的 +0.0065/+0.006 偏移）。
enum MapCoordinateConverter {

    private static let xPi = Double.pi * 3000.0 / 180.0

    /// 高德（GCJ-02 同系）→ 腾讯
    static func gaodeToTencent(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lng = coordinate.longitude
        let lat = coordinate.latitude
        let z = sqrt(lng * lng + lat * lat) + 0.00002 * sin(lat * xPi)
        let theta = atan2(lat, lng) + 0.000003 * cos(lng * xPi)
        return CLLocationCoordinate2D(
            latitude: z * sin(theta),
            longitude: z * cos(theta)
        )
    }

    /// 腾讯 → 高德（GCJ-02 同系）
    static func tencentToGaode(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lng = coordinate.longitude
        let lat = coordinate.latitude
        let z = sqrt(lng * lng + lat * lat) - 0.00002 * sin(lat * xPi)
        let theta = atan2(lat, lng) - 0.000003 * cos(lng * xPi)
        return CLLocationCoordinate2D(
            latitude: z * sin(theta),
            longitude: z * cos(theta)
        )
    }

    /// 格式化为接口 Query 字符串（保留足够小数位）
    static func queryString(from coordinate: CLLocationCoordinate2D) -> (longitude: String, latitude: String) {
        (
            String(format: "%.6f", coordinate.longitude),
            String(format: "%.6f", coordinate.latitude)
        )
    }
}
