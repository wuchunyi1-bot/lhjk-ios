import Foundation
import Combine

/// 选择业务经理 ViewModel — 对齐 funde `ManagerSelectView`
@MainActor
final class ManagerSelectViewModel: ObservableObject {

    @Published private(set) var items: [DoctorVo] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = true
    @Published private(set) var errorMessage: String?
    @Published var keyword = ""
    @Published private(set) var selectedId: String?

    let hospitalId: String
    let hospitalName: String

    private let pageSize = 20
    private var currentPage = 1
    private var requestID = 0

    private let doctorService: DoctorService
    private var searchTask: Task<Void, Never>?
    private var keywordCancellable: AnyCancellable?

    init(
        hospitalId: String,
        hospitalName: String,
        selectedId: String? = nil,
        doctorService: DoctorService = AppContainer.shared.doctorService
    ) {
        self.hospitalId = hospitalId
        self.hospitalName = hospitalName
        self.selectedId = selectedId
        self.doctorService = doctorService

        keywordCancellable = $keyword
            .dropFirst()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.reload()
            }
    }

    deinit {
        searchTask?.cancel()
    }

    func onAppear() {
        reload()
    }

    func select(_ item: DoctorVo) {
        selectedId = item.id
    }

    func loadMore() {
        guard hasMore, !isLoadingMore, !isLoading else { return }
        isLoadingMore = true
        let id = requestID
        let next = currentPage + 1
        Task { [weak self] in
            await self?.performSearch(page: next, append: true, requestID: id)
        }
    }

    // MARK: - Private

    private func reload() {
        currentPage = 1
        hasMore = true
        requestID += 1
        let id = requestID
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            await self?.performSearch(page: 1, append: false, requestID: id)
        }
    }

    private func performSearch(page: Int, append: Bool, requestID: Int) async {
        guard !hospitalId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            items = []
            hasMore = false
            return
        }

        if append {
            isLoadingMore = true
        } else {
            isLoading = true
        }
        errorMessage = nil
        defer {
            isLoading = false
            isLoadingMore = false
        }

        do {
            let kw = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            let data = try await doctorService.getDoctorPage(
                hospitalId: hospitalId,
                name: kw.isEmpty ? nil : kw,
                pageNum: page,
                pageSize: pageSize
            )
            guard !Task.isCancelled, requestID == self.requestID else { return }
            let records = data.records ?? []
            if append {
                let existing = Set(items.map(\.id))
                items.append(contentsOf: records.filter { !existing.contains($0.id) })
            } else {
                items = records
            }
            currentPage = page
            hasMore = Self.stillHasMore(page: page, pageSize: pageSize, data: data, records: records)
        } catch {
            guard !Task.isCancelled, requestID == self.requestID else { return }
            if !append {
                items = []
            }
            errorMessage = error.localizedDescription
            hasMore = false
        }
    }

    private static func stillHasMore(
        page: Int,
        pageSize: Int,
        data: PaginatedDoctorData,
        records: [DoctorVo]
    ) -> Bool {
        if let total = data.totalPages, total > 0 {
            return page < total
        }
        if let totalRecords = data.totalRecords, totalRecords > 0 {
            return page * pageSize < totalRecords
        }
        return records.count >= pageSize
    }
}
