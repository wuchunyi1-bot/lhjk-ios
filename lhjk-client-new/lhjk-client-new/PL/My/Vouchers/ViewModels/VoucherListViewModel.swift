import Foundation

/// 我的卡券 ViewModel — 卡券数据、Tab 筛选、过滤逻辑
final class VoucherListViewModel: ObservableObject {

    // MARK: - Published State

    @Published var filteredVouchers: [MVoucher] = []
    @Published var isEmpty = true
    @Published var activeTab: Int = 0

    // MARK: - Dependencies

    private let voucherService: VoucherService
    private var allVouchers: [MVoucher] = []

    // MARK: - Init

    init(voucherService: VoucherService = AppContainer.shared.voucherService) {
        self.voucherService = voucherService
    }

    // MARK: - Data Loading

    func loadData() {
        allVouchers = voucherService.getVouchers()
        filterVouchers()
    }

    // MARK: - Tab / Filter

    func selectTab(_ index: Int) {
        activeTab = index
        filterVouchers()
    }

    private func filterVouchers() {
        switch activeTab {
        case 1:  filteredVouchers = allVouchers.filter { $0.status == .unused }
        case 2:  filteredVouchers = allVouchers.filter { $0.status == .activated }
        case 3:  filteredVouchers = allVouchers.filter { $0.status == .expired }
        default: filteredVouchers = allVouchers
        }
        isEmpty = filteredVouchers.isEmpty
    }

    // MARK: - Actions

    func activateVoucher(_ voucher: MVoucher) -> String {
        voucher.cardNo
    }
}
