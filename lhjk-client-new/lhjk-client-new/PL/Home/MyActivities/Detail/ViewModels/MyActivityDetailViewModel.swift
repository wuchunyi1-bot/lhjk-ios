import Combine
import UIKit

struct MyActivityDetailContent: Equatable {
    let theme: String
    let timeText: String
    let owner: String
    let devices: [MyActivityDeviceEntry]
}

final class MyActivityDetailViewModel: ObservableObject {

    let activityId: String

    @Published private(set) var content: MyActivityDetailContent?
    @Published private(set) var isLoading = false
    @Published private(set) var isMissing = false
    @Published private(set) var errorMessage: String?

    private let service: MemberActivityService
    private var loadTask: Task<Void, Never>?

    init(
        activityId: String,
        service: MemberActivityService = AppContainer.shared.memberActivityService
    ) {
        self.activityId = activityId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.service = service
    }

    func load() {
        guard !activityId.isEmpty else {
            content = nil
            isMissing = true
            isLoading = false
            return
        }
        loadTask?.cancel()
        isLoading = content == nil
        errorMessage = nil
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let detail = try await service.getDetail(activityId: activityId)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.content = Self.content(from: detail)
                    self.isMissing = false
                    self.isLoading = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.content = nil
                    self.isMissing = true
                    self.isLoading = false
                    self.errorMessage = (error as? LocalizedError)?.errorDescription ?? "未找到该活动"
                }
            }
        }
    }

    func claimWelfare() {
        guard !activityId.isEmpty else { return }
        let path = WeChatConfig.memberActivityDetailPath(activityId: activityId)
        WeChatSDKManager.shared.launchMiniProgram(
            path: path,
            miniProgramType: WeChatConfig.knowledgeShareMiniProgramType
        ) { result in
            if case .failure(let error) = result, error != .userCancelled {
                FDToast.show(error.localizedDescription, duration: 1.5)
            }
        }
    }

    @MainActor
    func openDevice(_ entry: MyActivityDeviceEntry, from viewController: UIViewController) {
        let pageUrl = MemberActivityDisplay.pageURL(entry.pageUrl, activityId: activityId)
        if FundePageURL.open(pageUrl, title: entry.name, from: viewController) { return }
        if let route = entry.fallbackRoute {
            Router.shared.push(route, params: ["activityId": activityId], from: viewController)
        }
    }

    private static func content(from detail: MemberActivityDetailVO) -> MyActivityDetailContent {
        MyActivityDetailContent(
            theme: detail.theme.isEmpty ? "—" : detail.theme,
            timeText: MemberActivityDisplay.timeText(startTime: detail.startTime, endTime: detail.endTime),
            owner: detail.ourLeaderName.isEmpty ? "—" : detail.ourLeaderName,
            devices: MemberActivityDisplay.deviceEntries(from: detail.clientDetectionItems)
        )
    }
}
