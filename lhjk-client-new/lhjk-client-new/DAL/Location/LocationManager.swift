import CoreLocation
import Foundation

// MARK: - Models

/// 逆地理编码结果 — 映射到收货地址省市区字段
struct ReverseGeocodedAddress {
    let province: String
    let city: String
    let area: String
    /// 街道门牌等，可写入详细地址
    let detail: String
    let postalCode: String?
    let coordinate: CLLocationCoordinate2D
}

/// App 侧定位授权状态（与系统枚举解耦）
enum AppLocationAuthorizationStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
}

enum LocationServiceError: Error, LocalizedError {
    case denied
    case restricted
    case servicesDisabled
    case locationFailed(Error?)
    case geocodeFailed(Error?)
    case emptyPlacemark

    var errorDescription: String? {
        "定位失败，请手动选择"
    }
}

// MARK: - LocationManager (DAL)

/// 定位与逆地理编码管理器 — 封装 CoreLocation + CLGeocoder
///
/// - 授权：**仅**在调用 `locateAndReverseGeocode()` 且状态为 `notDetermined` 时弹出系统授权框
/// - 定位：单次 `requestLocation()`，不持续追踪
/// - 逆地理：`CLGeocoder.reverseGeocodeLocation`
final class LocationManager: NSObject {

    static let shared = LocationManager()

    private var locationManager: CLLocationManager?
    private let geocoder = CLGeocoder()

    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Error>?

    private override init() {
        super.init()
    }

    // MARK: - Public

    /// 当前授权状态（只读，不触发系统弹框）
    func authorizationStatus() -> AppLocationAuthorizationStatus {
        mapStatus(systemAuthorizationStatus())
    }

    /// 单次定位 + 逆地理编码。按需请求 WhenInUse 授权。
    @MainActor
    func locateAndReverseGeocode() async throws -> ReverseGeocodedAddress {
        guard CLLocationManager.locationServicesEnabled() else {
            throw LocationServiceError.servicesDisabled
        }

        let manager = ensureManager()
        let status = systemAuthorizationStatus()

        switch status {
        case .denied:
            throw LocationServiceError.denied
        case .restricted:
            throw LocationServiceError.restricted
        case .notDetermined:
            let updated = try await requestWhenInUseAuthorization(manager: manager)
            switch mapStatus(updated) {
            case .authorized:
                break
            case .denied:
                throw LocationServiceError.denied
            case .restricted:
                throw LocationServiceError.restricted
            case .notDetermined:
                throw LocationServiceError.denied
            }
        case .authorizedAlways, .authorizedWhenInUse:
            break
        @unknown default:
            throw LocationServiceError.denied
        }

        let location = try await requestOneShotLocation(manager: manager)
        return try await reverseGeocode(location)
    }

    // MARK: - Private helpers

    private func ensureManager() -> CLLocationManager {
        if let locationManager { return locationManager }
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager = manager
        return manager
    }

    private func systemAuthorizationStatus() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            if let locationManager {
                return locationManager.authorizationStatus
            }
            return CLLocationManager().authorizationStatus
        }
        return CLLocationManager.authorizationStatus()
    }

    private func mapStatus(_ status: CLAuthorizationStatus) -> AppLocationAuthorizationStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorizedAlways, .authorizedWhenInUse: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .denied
        }
    }

    @MainActor
    private func requestWhenInUseAuthorization(manager: CLLocationManager) async throws -> CLAuthorizationStatus {
        try await withCheckedThrowingContinuation { continuation in
            self.authorizationContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    @MainActor
    private func requestOneShotLocation(manager: CLLocationManager) async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            manager.requestLocation()
        }
    }

    private func reverseGeocode(_ location: CLLocation) async throws -> ReverseGeocodedAddress {
        try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error {
                    continuation.resume(throwing: LocationServiceError.geocodeFailed(error))
                    return
                }
                guard let placemark = placemarks?.first else {
                    continuation.resume(throwing: LocationServiceError.emptyPlacemark)
                    return
                }
                continuation.resume(returning: Self.mapPlacemark(placemark, coordinate: location.coordinate))
            }
        }
    }

    private static func mapPlacemark(
        _ placemark: CLPlacemark,
        coordinate: CLLocationCoordinate2D
    ) -> ReverseGeocodedAddress {
        let province = placemark.administrativeArea?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var city = placemark.locality?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if city.isEmpty {
            city = province
        }
        let area = placemark.subLocality?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? placemark.subAdministrativeArea?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""

        var detailParts: [String] = []
        if let thoroughfare = placemark.thoroughfare, !thoroughfare.isEmpty {
            detailParts.append(thoroughfare)
        }
        if let subThoroughfare = placemark.subThoroughfare, !subThoroughfare.isEmpty {
            detailParts.append(subThoroughfare)
        }
        var detail = detailParts.joined()
        if detail.isEmpty, let name = placemark.name, !name.isEmpty {
            // 避免把「省市区」整段重复塞进详址
            let regionBlob = [province, city, area].filter { !$0.isEmpty }.joined()
            if !name.contains(regionBlob) || regionBlob.isEmpty {
                detail = name
            }
        }

        return ReverseGeocodedAddress(
            province: province,
            city: city,
            area: area,
            detail: detail,
            postalCode: placemark.postalCode,
            coordinate: coordinate
        )
    }

    private func resumeAuthorization(_ status: CLAuthorizationStatus) {
        guard let continuation = authorizationContinuation else { return }
        authorizationContinuation = nil
        continuation.resume(returning: status)
    }

    private func resumeLocation(_ result: Result<CLLocation, Error>) {
        guard let continuation = locationContinuation else { return }
        locationContinuation = nil
        continuation.resume(with: result)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = manager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        // 仅在等待授权 continuation 时结束；忽略后续无关回调
        if authorizationContinuation != nil, status != .notDetermined {
            resumeAuthorization(status)
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if authorizationContinuation != nil, status != .notDetermined {
            resumeAuthorization(status)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            resumeLocation(.failure(LocationServiceError.locationFailed(nil)))
            return
        }
        resumeLocation(.success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resumeLocation(.failure(LocationServiceError.locationFailed(error)))
    }
}
