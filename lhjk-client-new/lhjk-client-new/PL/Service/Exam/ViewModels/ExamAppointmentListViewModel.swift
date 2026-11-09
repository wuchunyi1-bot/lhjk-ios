import Combine
import Foundation

@MainActor
final class ExamAppointmentListViewModel: ObservableObject {

    @Published private(set) var items: [ServiceItemVO] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = false
    @Published private(set) var errorMessage: String?

    private let pageSize = 20
    private var currentPage = 1
    private var requestID = 0
    private let service: ServiceItemService

    init(service: ServiceItemService = AppContainer.shared.serviceItemService) {
        self.service = service
    }

    func reload() {
        requestID += 1
        let token = requestID
        currentPage = 1
        hasMore = false
        isLoading = true
        let service = service
        let pageSize = pageSize
        Task {
            do {
                let page = try await service.list(
                    businessType: ServiceItemService.examBusinessType,
                    pageNum: 1,
                    pageSize: pageSize
                )
                apply(page, pageNum: 1, append: false, token: token)
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "获取体检套餐失败"
                fail(message, token: token, append: false)
            }
        }
    }

    func loadMore() {
        guard hasMore, !isLoading, !isLoadingMore else { return }
        isLoadingMore = true
        let token = requestID
        let next = currentPage + 1
        let service = service
        let pageSize = pageSize
        Task {
            do {
                let page = try await service.list(
                    businessType: ServiceItemService.examBusinessType,
                    pageNum: next,
                    pageSize: pageSize
                )
                apply(page, pageNum: next, append: true, token: token)
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "获取体检套餐失败"
                fail(message, token: token, append: true)
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func apply(_ page: PaginatedServiceItemData, pageNum: Int, append: Bool, token: Int) {
        guard token == requestID else { return }
        isLoading = false
        isLoadingMore = false
        let rows = (page.records ?? []).filter { !$0.id.isEmpty && !$0.name.isEmpty }
        items = append ? items + rows : rows
        currentPage = pageNum
        let total = page.totalRecords ?? items.count
        hasMore = !rows.isEmpty && items.count < total
    }

    private func fail(_ message: String, token: Int, append: Bool) {
        guard token == requestID else { return }
        isLoading = false
        isLoadingMore = false
        if !append {
            items = []
            hasMore = false
        }
        errorMessage = message
    }
}
