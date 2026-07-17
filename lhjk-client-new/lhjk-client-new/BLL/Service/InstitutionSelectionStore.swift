import Foundation

// MARK: - 服务模块机构选中态

/// 持久化当前服务机构（对齐 funde `funde-client:services:selected-institution:v1`）
final class InstitutionSelectionStore {

    static let shared = InstitutionSelectionStore()

    static let didChangeNotification = Notification.Name("lhjk.services.selectedInstitutionDidChange")

    private let storageKey = "lhjk.services.selectedInstitution.v1"
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var selected: SelectedServiceInstitution? {
        get {
            guard let data = defaults.data(forKey: storageKey) else { return nil }
            return try? decoder.decode(SelectedServiceInstitution.self, from: data)
        }
        set {
            if let newValue, let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: storageKey)
            } else {
                defaults.removeObject(forKey: storageKey)
            }
            NotificationCenter.default.post(name: Self.didChangeNotification, object: newValue)
        }
    }

    /// 可作为 API 的 hospitalId
    var selectedHospitalId: String? {
        ServiceCatalogService.validApiHospitalId(selected?.id)
    }

    func select(_ institution: SelectedServiceInstitution) {
        selected = institution
    }

    func clear() {
        selected = nil
    }
}
