import Combine
import Foundation

/// 体脂秤广播测量页 ViewModel — 用户主动启停扫描，展示实时/锁定体重
final class ScaleBroadcastMeasureViewModel: ObservableObject {

    enum Phase: Equatable {
        case idle
        case measuring
        case locked
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var weightText: String = "--.-"
    @Published private(set) var statusText: String = "点击下方按钮开始测量"
    @Published private(set) var detailText: String = ""
    @Published private(set) var buttonTitle: String = "开始测量"

    let toastPublisher = PassthroughSubject<String, Never>()

    private let session: ScaleBleSessionService
    private var cancellables = Set<AnyCancellable>()

    init(session: ScaleBleSessionService = AppContainer.shared.scaleBleSessionService) {
        self.session = session
        bindSession()
    }

    func toggleMeasuring() {
        switch phase {
        case .measuring:
            stopMeasuring()
        case .idle, .locked:
            startMeasuring()
        }
    }

    func startMeasuring() {
        weightText = "--.-"
        detailText = ""
        phase = .measuring
        buttonTitle = "停止"
        statusText = "测量中，请上秤…"
        session.startSession(context: .measurePage)
    }

    func stopMeasuring(resetUI: Bool = true) {
        session.stopSession()
        guard resetUI else { return }
        if phase != .locked {
            phase = .idle
            buttonTitle = "开始测量"
            statusText = "已停止"
        }
    }

    /// 离开页面时必须停扫
    func onLeave() {
        session.stopSession()
    }

    // MARK: - Private

    private func bindSession() {
        session.realtimePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] packet in
                guard let self, self.phase == .measuring else { return }
                self.weightText = Self.formatWeight(packet.weightKg)
                self.statusText = "测量中…"
                if let discovery = self.session.lastDiscovery {
                    self.detailText = discovery.identityLogLine
                } else {
                    self.detailText = "MAC \(packet.macString)"
                }
            }
            .store(in: &cancellables)

        session.lockedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] packet in
                guard let self else { return }
                self.weightText = Self.formatWeight(packet.weightKg)
                self.phase = .locked
                self.buttonTitle = "再测一次"
                self.statusText = "测量完成"
                if let discovery = self.session.lastDiscovery {
                    self.detailText = discovery.identityLogLine
                } else {
                    self.detailText = "已锁定 · \(packet.macString)"
                }
                self.session.stopSession()
            }
            .store(in: &cancellables)

        session.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payload in
                guard let self else { return }
                let message = (payload["message"] as? String) ?? "蓝牙异常"
                self.toastPublisher.send(message)
                if self.phase == .measuring {
                    self.phase = .idle
                    self.buttonTitle = "开始测量"
                    self.statusText = message
                    self.session.stopSession()
                }
            }
            .store(in: &cancellables)
    }

    private static func formatWeight(_ kg: Double) -> String {
        String(format: "%.1f", kg)
    }
}
