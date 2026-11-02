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

    /// WGS-84 → GCJ-02。`CLLocation` 为 WGS-84，H5 `getLocation` 要求返回 GCJ-02。
    /// 境外坐标不偏移。
    static func wgs84ToGcj02(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lat = coordinate.latitude
        let lng = coordinate.longitude
        guard isInChina(latitude: lat, longitude: lng) else { return coordinate }

        let a = 6378245.0
        let ee = 0.00669342162296594323
        var dLat = transformLatitude(lng - 105.0, lat - 35.0)
        var dLng = transformLongitude(lng - 105.0, lat - 35.0)
        let radLat = lat / 180.0 * Double.pi
        var magic = sin(radLat)
        magic = 1 - ee * magic * magic
        let sqrtMagic = sqrt(magic)
        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * Double.pi)
        dLng = (dLng * 180.0) / (a / sqrtMagic * cos(radLat) * Double.pi)
        return CLLocationCoordinate2D(latitude: lat + dLat, longitude: lng + dLng)
    }

    /// 格式化为接口 Query 字符串（保留足够小数位）
    static func queryString(from coordinate: CLLocationCoordinate2D) -> (longitude: String, latitude: String) {
        (
            String(format: "%.6f", coordinate.longitude),
            String(format: "%.6f", coordinate.latitude)
        )
    }

    private static func isInChina(latitude: Double, longitude: Double) -> Bool {
        latitude >= 0.8293 && latitude <= 55.8271 && longitude >= 72.004 && longitude <= 137.8347
    }

    private static func transformLatitude(_ x: Double, _ y: Double) -> Double {
        var result = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
        result += (20.0 * sin(6.0 * x * Double.pi) + 20.0 * sin(2.0 * x * Double.pi)) * 2.0 / 3.0
        result += (20.0 * sin(y * Double.pi) + 40.0 * sin(y / 3.0 * Double.pi)) * 2.0 / 3.0
        result += (160.0 * sin(y / 12.0 * Double.pi) + 320 * sin(y * Double.pi / 30.0)) * 2.0 / 3.0
        return result
    }

    private static func transformLongitude(_ x: Double, _ y: Double) -> Double {
        var result = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
        result += (20.0 * sin(6.0 * x * Double.pi) + 20.0 * sin(2.0 * x * Double.pi)) * 2.0 / 3.0
        result += (20.0 * sin(x * Double.pi) + 40.0 * sin(x / 3.0 * Double.pi)) * 2.0 / 3.0
        result += (150.0 * sin(x / 12.0 * Double.pi) + 300.0 * sin(x / 30.0 * Double.pi)) * 2.0 / 3.0
        return result
    }
}
