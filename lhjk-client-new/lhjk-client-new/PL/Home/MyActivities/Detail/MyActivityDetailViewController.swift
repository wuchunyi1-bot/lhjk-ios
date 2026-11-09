import Combine
import SnapKit
import UIKit

final class MyActivityDetailViewController: BaseViewController {

    private let viewModel: MyActivityDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.backgroundColor = .fdBg
        scroll.alwaysBounceVertical = true
        return scroll
    }()

    private let bodyView = MyActivityDetailBodyView()
    private let emptyView = FDEmptyStateView(style: .page, message: "未找到该活动")
    private let spinner = UIActivityIndicatorView(style: .medium)

    init(activityId: String) {
        self.viewModel = MyActivityDetailViewModel(activityId: activityId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupUI() {
        title = "我的活动"
        view.backgroundColor = .fdBg
        view.addSubview(scrollView)
        scrollView.addSubview(bodyView)
        view.addSubview(emptyView)
        view.addSubview(spinner)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        bodyView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }
        spinner.snp.makeConstraints { $0.center.equalToSuperview() }
        emptyView.isHidden = true
        bodyView.isHidden = true

        bodyView.onClaim = { [weak self] in
            self?.viewModel.claimWelfare()
        }
        bodyView.onDevice = { [weak self] entry in
            guard let self else { return }
            self.viewModel.openDevice(entry, from: self)
        }
    }

    override func bindViewModel() {
        viewModel.$content
            .receive(on: DispatchQueue.main)
            .sink { [weak self] content in
                guard let self else { return }
                if let content {
                    self.bodyView.configure(content)
                    self.bodyView.isHidden = false
                    self.scrollView.isHidden = false
                } else {
                    self.bodyView.isHidden = true
                    self.scrollView.isHidden = true
                }
                self.updateEmpty()
            }
            .store(in: &cancellables)
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading {
                    self?.spinner.startAnimating()
                } else {
                    self?.spinner.stopAnimating()
                }
                self?.updateEmpty()
            }
            .store(in: &cancellables)
        viewModel.$isMissing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateEmpty() }
            .store(in: &cancellables)
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { message in
                guard let message, !message.isEmpty else { return }
                FDToast.show(message, duration: 1.5)
            }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.load()
    }

    private func updateEmpty() {
        emptyView.isHidden = viewModel.isLoading || viewModel.content != nil || !viewModel.isMissing
    }
}
