import Combine
import Foundation

/// 体脂秤体重报告（有阻抗）ViewModel
final class WeightScaleResultViewModel: ObservableObject {

    @Published private(set) var isLoading = false
    @Published private(set) var isDeleting = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var record: WeightHomePageDataVO?

    let toastPublisher = PassthroughSubject<String, Never>()
    let dismissPublisher = PassthroughSubject<Void, Never>()

    let monitorId: String
    private let equipmentBindService: EquipmentBindService
    private let scaleSession: ScaleBleSessionService
    private var didRequestDismiss = false

    init(
        monitorId: String,
        preloaded: WeightHomePageDataVO? = nil,
        equipmentBindService: EquipmentBindService = AppContainer.shared.equipmentBindService,
        scaleSession: ScaleBleSessionService = AppContainer.shared.scaleBleSessionService
    ) {
        self.monitorId = monitorId
        self.equipmentBindService = equipmentBindService
        self.scaleSession = scaleSession
        self.record = preloaded
    }

    func load() {
        if record != nil { return }
        guard !monitorId.isEmpty else {
            errorMessage = "缺少测量记录"
            return
        }
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.isLoading = false }
            do {
                let data = try await self.equipmentBindService.fetchWeightHomePageData(monitorId: self.monitorId)
                self.record = data
                if data == nil {
                    self.errorMessage = "暂无测量数据"
                }
            } catch {
                self.errorMessage = error.localizedDescription
                self.toastPublisher.send(error.localizedDescription)
            }
        }
    }

    /// 记录已由锁定上报写入；此处只 pop，不再次保存、不删除。
    func saveTapped() {
        guard !isDeleting, !didRequestDismiss else { return }
        didRequestDismiss = true
        dismissPublisher.send(())
    }

    /// 删除本条监测后再 pop，并解除测量后自动启扫暂停。
    func remeasureTapped() {
        guard !isDeleting, !didRequestDismiss else { return }
        isDeleting = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.equipmentBindService.deleteMonitorData(monitorId: self.monitorId)
                self.scaleSession.clearAutoScanPause()
                self.didRequestDismiss = true
                self.dismissPublisher.send(())
            } catch {
                self.isDeleting = false
                self.toastPublisher.send(error.localizedDescription)
            }
        }
    }

    var formattedWeight: String {
        Self.formatNumber(record?.weight)
    }

    var formattedTime: String {
        guard let ms = record?.recordTime, ms > 0 else { return "--" }
        let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    var formattedBodyAge: String {
        Self.formatNumber(record?.bodyAge)
    }

    var formattedBMI: String {
        Self.formatNumber(record?.bmi)
    }

    var formattedBodyFat: String {
        Self.formatNumber(record?.bodyFat)
    }

    var metricItems: [WeightBodyCompositionItemVO] {
        record?.bodyCompositionResults.filter { item in
            let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return !name.isEmpty
        } ?? []
    }

    static func formatNumber(_ value: Double?) -> String {
        guard let value else { return "--" }
        if value.rounded() == value {
            return String(format: "%.0f", value)
        }
        let tenths = (value * 10).rounded() / 10
        if abs(tenths - value) < 0.001 {
            return String(format: "%.1f", tenths)
        }
        return String(format: "%.2f", value)
    }
}
