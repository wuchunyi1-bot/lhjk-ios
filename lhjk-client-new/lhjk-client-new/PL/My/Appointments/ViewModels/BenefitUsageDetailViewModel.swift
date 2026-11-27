import Combine
import Foundation

/// 体检、就医协助的预约使用详情。数据来自 `GET /v1/cabin/reservationDetail`。
@MainActor
final class BenefitUsageDetailViewModel: ObservableObject {

    let reservationId: String

    @Published private(set) var detail: CabinReservationDetailVO?
    @Published private(set) var isLoading = false
    @Published private(set) var isSubmitting = false
    @Published var errorMessage: String?

    private let cabinService: CabinService

    init(
        reservationId: String,
        preloaded: CabinReservationDetailVO? = nil,
        cabinService: CabinService = .shared
    ) {
        self.reservationId = reservationId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.cabinService = cabinService
        if let preloaded {
            detail = preloaded
        }
    }

    /// 详情里的 `businessType`：3 为就医协助。
    var isAssist: Bool { detail?.businessType == ServiceItemService.assistBusinessType }

    var pageTitle: String {
        switch detail?.status {
        case 2: return "待确认详情"
        case 3: return "待服务详情"
        case 4: return "服务中详情"
        case 5: return "已完成详情"
        case 6: return "已取消详情"
        case 7: return "已过期详情"
        default: return "预约详情"
        }
    }

    var hintText: String? {
        switch detail?.status {
        case 2: return "请核对以下服务安排，确认后将进入「待服务」"
        case 3: return "服务已确认，请按以下安排到院/到场。"
        case 4: return "服务正在进行中，请按以下信息配合现场安排。"
        case 5: return "本次服务已完成，以下为服务记录信息。"
        case 6: return "本次服务已取消，以下为取消前的安排信息；本次服务权益已消耗。"
        case 7: return "本次预约已过期，以下为过期前的安排信息；如需使用请重新预约。"
        default: return nil
        }
    }

    var showsConsumeWarning: Bool { detail?.status == 3 }

    var showsConfirmButton: Bool { detail?.status == 2 }

    var showsCancelButton: Bool { detail?.status == 3 }

    var institutionTitle: String { isAssist ? "服务医院" : "服务机构" }

    var addressTitle: String { isAssist ? "医院地址" : "机构地址" }

    var navigationTitle: String { isAssist ? "导航到医院" : "导航到机构" }

    var missingAddressText: String { isAssist ? "暂无医院地址" : "暂无机构地址" }

    var scheduleText: String {
        let parts = [detail?.reserveDate ?? "", detail?.timeText ?? ""].filter { !$0.isEmpty }
        return parts.isEmpty ? "—" : parts.joined(separator: " ")
    }

    func load() {
        guard detail == nil else { return }
        guard !reservationId.isEmpty else {
            errorMessage = "未找到该预约"
            return
        }
        guard !isLoading else { return }
        isLoading = true
        let service = cabinService
        let id = reservationId
        Task {
            do {
                let detail = try await service.reservationDetail(id: id)
                self.detail = detail
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.errorMessage = (error as? LocalizedError)?.errorDescription ?? "未找到该预约"
            }
        }
    }

    func confirm() async throws {
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        try await cabinService.confirmReservation(id: reservationId)
    }

    func cancel() async throws {
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        try await cabinService.cancelReservation(id: reservationId)
    }

    func clearError() {
        errorMessage = nil
    }
}
