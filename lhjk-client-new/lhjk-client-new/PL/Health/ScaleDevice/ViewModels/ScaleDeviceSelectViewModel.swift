import Combine
import Foundation

/// 设备选择 / 我的设备 — 绑定列表 + 可绑定型号
final class ScaleDeviceSelectViewModel: ObservableObject {

    enum Mode: Equatable {
        case select
        case mine
    }

    @Published private(set) var mode: Mode = .select
    @Published private(set) var boundDevices: [ScaleDeviceCardItem] = []
    @Published private(set) var moreDevices: [ScaleDeviceCardItem] = []
    @Published private(set) var isExpanded = false
    @Published private(set) var isLoading = false
    @Published private(set) var isUnbinding = false

    let toastPublisher = PassthroughSubject<String, Never>()

    var navigationTitle: String {
        mode == .mine ? "我的设备" : "选择设备"
    }

    var showsAddButton: Bool { mode == .mine }

    var addButtonTitle: String {
        isExpanded ? "收起设备列表" : "添加设备"
    }

    var isAddButtonExpanded: Bool { isExpanded }

    var showsMoreSection: Bool { mode == .mine && isExpanded }

    var isEmpty: Bool {
        if isLoading { return false }
        switch mode {
        case .select:
            return moreDevices.isEmpty
        case .mine:
            return boundDevices.isEmpty
        }
    }

    private let equipmentBindService: EquipmentBindService
    private let userManager: UserManager

    init(
        equipmentBindService: EquipmentBindService = AppContainer.shared.equipmentBindService,
        userManager: UserManager = AppContainer.shared.userManager
    ) {
        self.equipmentBindService = equipmentBindService
        self.userManager = userManager
    }

    func load() {
        Task { @MainActor in
            await fetch()
        }
    }

    func toggleAddDevices() {
        guard mode == .mine else { return }
        isExpanded.toggle()
    }

    func unbind(_ item: ScaleDeviceCardItem) {
        guard item.kind == .bound else { return }
        guard let equipmentUserId = item.equipmentUserId, equipmentUserId > 0 else {
            toastPublisher.send("无法解绑该设备")
            return
        }
        Task { @MainActor in
            isUnbinding = true
            defer { isUnbinding = false }
            do {
                try await equipmentBindService.unbindEquipment(equipmentUserId: equipmentUserId)
                toastPublisher.send("已解除绑定")
                await fetch()
            } catch {
                toastPublisher.send(error.localizedDescription)
            }
        }
    }

    // MARK: - Private

    @MainActor
    private func fetch() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let userId = userManager.resolvedUserId.flatMap { Int64($0) }
            async let boundTask = equipmentBindService.fetchBoundDevices(category: .weight)
            async let catalogTask = equipmentBindService.fetchEquipmentCatalog(
                category: .weight,
                userId: userId
            )
            let boundPage = try await boundTask
            let catalogPage = try await catalogTask

            let boundItems = (boundPage.records ?? []).compactMap(ScaleDeviceCardItem.bound(from:))
            let catalogItems = (catalogPage.records ?? [])
                .filter(\.isBindable)
                .map(ScaleDeviceCardItem.catalog(from:))

            if boundItems.isEmpty {
                mode = .select
                boundDevices = []
                moreDevices = catalogItems
                isExpanded = false
            } else {
                mode = .mine
                boundDevices = boundItems
                let boundTypeIds = Set(boundItems.compactMap(\.equipmentTypeId))
                moreDevices = catalogItems.filter { item in
                    guard let typeId = item.equipmentTypeId else { return true }
                    return !boundTypeIds.contains(typeId)
                }
            }
        } catch {
            toastPublisher.send(error.localizedDescription)
            print("[ScaleDevice] load failed — \(error.localizedDescription)")
        }
    }
}
