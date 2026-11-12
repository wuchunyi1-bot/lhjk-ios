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
    case timeout
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
        let location = try await locateOnce()
        return try await reverseGeocode(location)
    }

    /// 单次定位（不逆地理）。按需请求 WhenInUse 授权。
    /// - Parameter timeout: 等待定位结果的秒数；超时后结束本次请求，迟到回调不再投递。
    @MainActor
    func locateOnce(timeout: TimeInterval? = nil) async throws -> CLLocation {
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

        return try await requestOneShotLocation(manager: manager, timeout: timeout)
    }

    /// 单次定位并将坐标转为腾讯坐标系（供 searchPage 等接口上报）
    @MainActor
    func locateTencentCoordinate() async throws -> CLLocationCoordinate2D {
        let location = try await locateOnce()
        // 国内 CLLocation 按高德同系 GCJ-02 处理
        return MapCoordinateConverter.gaodeToTencent(location.coordinate)
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
        if let locationManager {
            return locationManager.authorizationStatus
        }
        return CLLocationManager().authorizationStatus
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
    private func requestOneShotLocation(
        manager: CLLocationManager,
        timeout: TimeInterval?
    ) async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            manager.requestLocation()
            guard let timeout, timeout > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
                self?.resumeLocation(.failure(LocationServiceError.timeout))
            }
        }
    }

    private func reverseGeocode(_ location: CLLocation) async throws -> ReverseGeocodedAddress {
        try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "zh_CN")) { placemarks, error in
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

    private static func trimmed(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func mapPlacemark(
        _ placemark: CLPlacemark,
        coordinate: CLLocationCoordinate2D
    ) -> ReverseGeocodedAddress {
        let province = Self.trimmed(placemark.administrativeArea)
        var city = Self.trimmed(placemark.locality)
        var area = Self.trimmed(placemark.subLocality)
        let subAdmin = Self.trimmed(placemark.subAdministrativeArea)
        if city.isEmpty, !subAdmin.isEmpty, subAdmin != province {
            city = subAdmin
        }
        if area.isEmpty, !subAdmin.isEmpty, subAdmin != city, subAdmin != province {
            area = subAdmin
        }
        if city.isEmpty {
            city = province
        }

        var detailParts: [String] = []
        if let thoroughfare = placemark.thoroughfare, !thoroughfare.isEmpty {
            detailParts.append(thoroughfare)
        }
        if let subThoroughfare = placemark.subThoroughfare, !subThoroughfare.isEmpty {
            detailParts.append(subThoroughfare)
        }
        var detail = detailParts.joined()
        if let name = placemark.name, !name.isEmpty {
            let regionBlob = [province, city, area].filter { !$0.isEmpty }.joined()
            let missingLevel = city.isEmpty || area.isEmpty
            if missingLevel || detail.isEmpty && (!name.contains(regionBlob) || regionBlob.isEmpty) {
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
        status = manager.authorizationStatus
        
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
