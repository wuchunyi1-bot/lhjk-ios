import Foundation
import Combine

/// 收货地址编辑 ViewModel
final class AddressEditViewModel: ObservableObject {

    // MARK: - Inputs / State

    @Published var name: String = ""
    @Published var mobile: String = ""
    @Published var province: String = ""
    @Published var city: String = ""
    @Published var area: String = ""
    @Published var address: String = ""
    @Published var code: String = ""
    @Published var isDefault: Bool = false

    @Published private(set) var isSaving = false
    @Published private(set) var isLocating = false
    @Published private(set) var isDefaultSwitchEnabled = true

    let saveSucceeded = PassthroughSubject<Void, Never>()
    let toastMessage = PassthroughSubject<String, Never>()

    // MARK: - Dependencies

    private let existingAddress: MAddress?
    private let isFirstAddress: Bool
    private let addressService: AddressService
    private let locationManager: LocationManager

    var isEditMode: Bool { existingAddress != nil }

    var navigationTitle: String {
        isEditMode ? "编辑收货地址" : "添加收货地址"
    }

    /// 所在地区展示文案
    var regionDisplayText: String {
        let parts = [province, city, area]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }

    var hasRegion: Bool {
        !province.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !area.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Init

    init(
        address: MAddress? = nil,
        existingAddressCount: Int = 0,
        addressService: AddressService = AppContainer.shared.addressService,
        locationManager: LocationManager = AppContainer.shared.locationManager
    ) {
        self.existingAddress = address
        self.addressService = addressService
        self.locationManager = locationManager

        if let address {
            name = address.name ?? ""
            mobile = address.mobile ?? ""
            province = address.province ?? ""
            city = address.city ?? ""
            area = address.area ?? ""
            self.address = address.address ?? ""
            code = address.code ?? ""
            isDefault = address.isDefaultAddress
            // 仅有这一条地址时不可取消默认
            isFirstAddress = existingAddressCount <= 1
        } else {
            isFirstAddress = existingAddressCount == 0
            if isFirstAddress {
                isDefault = true
            }
        }

        if isFirstAddress {
            isDefault = true
            isDefaultSwitchEnabled = false
        }
    }

    // MARK: - Locate

    @MainActor
    func locate() async {
        guard !isLocating else { return }
        isLocating = true
        defer { isLocating = false }

        do {
            let result = try await locationManager.locateAndReverseGeocode()
            if !result.province.isEmpty { province = result.province }
            if !result.city.isEmpty { city = result.city }
            if !result.area.isEmpty { area = result.area }
            if !result.detail.isEmpty {
                address = result.detail
            }
            if let postal = result.postalCode, !postal.isEmpty {
                code = postal
            }
            if province.isEmpty && city.isEmpty && area.isEmpty {
                toastMessage.send("定位失败，请手动选择")
            }
        } catch {
            toastMessage.send(error.localizedDescription)
        }
    }

    // MARK: - Save

    @MainActor
    func save() async {
        if let error = validate() {
            toastMessage.send(error)
            return
        }

        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let payload = AddressSavePayload(
            id: existingAddress?.id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            mobile: mobile.trimmingCharacters(in: .whitespacesAndNewlines),
            isDefault: (isFirstAddress || isDefault) ? 1 : 0,
            province: province.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            area: area.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            code: {
                let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }()
        )

        do {
            try await addressService.saveOrUpdateAddress(payload)
            saveSucceeded.send(())
        } catch {
            toastMessage.send(error.localizedDescription.isEmpty ? "保存失败，请稍后重试" : error.localizedDescription)
        }
    }

    // MARK: - Validation

    private func validate() -> String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "请输入收货人姓名"
        }
        let phone = mobile.trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneRegex = try? NSRegularExpression(pattern: "^1[3-9]\\d{9}$")
        let range = NSRange(location: 0, length: (phone as NSString).length)
        if phoneRegex?.firstMatch(in: phone, options: [], range: range) == nil {
            return "请输入正确的手机号码"
        }
        if !hasRegion {
            return "请选择所在地区"
        }
        if address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "请输入详细地址"
        }
        return nil
    }
}
