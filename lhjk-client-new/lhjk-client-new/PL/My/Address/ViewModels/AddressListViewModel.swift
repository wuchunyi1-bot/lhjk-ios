import Foundation

/// 收货地址列表 ViewModel — 地址数据、加载/删除、状态管理
final class AddressListViewModel: ObservableObject {

    // MARK: - Published State

    @Published var addresses: [MAddress] = []
    @Published var isLoading = true
    @Published var isEmpty = true

    // MARK: - Dependencies

    private let addressService: AddressService

    // MARK: - Init

    init(addressService: AddressService = .shared) {
        self.addressService = addressService
    }

    // MARK: - Data Loading

    func loadAddresses() async {
        await MainActor.run {
            isLoading = true
            isEmpty = true
        }
        do {
            let data = try await addressService.getAddressList()
            await MainActor.run {
                var list = data.records ?? []
                list.sort { ($0.isDefault == 1) && ($1.isDefault != 1) }
                addresses = list
                isLoading = false
                isEmpty = list.isEmpty
            }
        } catch {
            await MainActor.run {
                isLoading = false
                isEmpty = true
            }
        }
    }

    // MARK: - Delete

    func deleteAddress(id: Int64) async throws {
        try await addressService.deleteAddress(id: id)
        await MainActor.run {
            addresses.removeAll { $0.id == id }
            isEmpty = addresses.isEmpty
        }
    }
}
