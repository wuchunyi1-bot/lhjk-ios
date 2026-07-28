import Foundation
import Combine

/// 选择业务经理 ViewModel — 对齐 funde `ManagerSelectView`
@MainActor
final class ManagerSelectViewModel: ObservableObject {

    @Published private(set) var items: [DoctorVo] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var keyword = ""
    @Published private(set) var selectedId: String?

    let hospitalId: String
    let hospitalName: String

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

    // MARK: - Private

    private func reload() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            await self?.performSearch()
        }
    }

    private func performSearch() async {
        guard !hospitalId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            items = []
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // 拉本机构启用医生；关键词（姓名/经理号/职位）本地过滤，贴近原型搜索能力
            let page = try await doctorService.getDoctorPage(
                hospitalId: hospitalId,
                name: nil,
                pageNum: 1,
                pageSize: 50
            )
            var list = page.records ?? []

            let kw = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            if !kw.isEmpty {
                list = list.filter { doctor in
                    [
                        doctor.chineseName,
                        doctor.account,
                        doctor.position,
                        doctor.roleName,
                        doctor.nickName,
                    ]
                    .compactMap { $0 }
                    .contains { $0.localizedCaseInsensitiveContains(kw) }
                }
            }

            items = list
        } catch {
            errorMessage = error.localizedDescription
            items = []
        }
    }
}
