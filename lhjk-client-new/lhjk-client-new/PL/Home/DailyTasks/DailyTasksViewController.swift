import Combine
import SnapKit
import UIKit

/// 今日健康任务详情 — 对齐 Figma 4903:17030 / DailyTasksView.vue
final class DailyTasksViewController: BaseViewController {

    private let viewModel: DailyTasksViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let heroView = DailyTasksHeroView()
    private let listPanel = UIView()
    private let listStack = UIStackView()

    init(viewModel: DailyTasksViewModel = DailyTasksViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.load(forceRefresh: true)
    }

    override func setupUI() {
        title = "今日健康任务"
        view.backgroundColor = .fdBg

        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }

        contentStack.axis = .vertical
        contentStack.spacing = 0
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        listPanel.backgroundColor = .white
        listPanel.layer.cornerRadius = 16
        listPanel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        listPanel.clipsToBounds = true

        listStack.axis = .vertical
        listStack.spacing = 12
        listPanel.addSubview(listStack)
        listStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-28)
        }

        rebuildContent()
    }

    override func bindViewModel() {
        viewModel.$tasks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.rebuildContent() }
            .store(in: &cancellables)

        Publishers.CombineLatest(viewModel.$doneCount, viewModel.$totalCount)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] done, total in
                self?.heroView.configure(doneCount: done, totalCount: total)
            }
            .store(in: &cancellables)
    }

    // MARK: - Build

    private func rebuildContent() {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        listStack.arrangedSubviews.forEach {
            listStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        contentStack.addArrangedSubview(wrap(heroView, insets: UIEdgeInsets(top: 16, left: 16, bottom: 14, right: 16)))
        heroView.configure(doneCount: viewModel.doneCount, totalCount: viewModel.totalCount)

        if viewModel.tasks.isEmpty {
            listStack.addArrangedSubview(buildEmpty())
        } else {
            listStack.addArrangedSubview(buildSectionHeader(title: "任务列表", more: "共 \(viewModel.totalCount) 项"))
            for task in viewModel.tasks {
                listStack.addArrangedSubview(buildTaskCard(task))
            }
        }

        listStack.addArrangedSubview(buildTipCard())
        contentStack.addArrangedSubview(listPanel)
        view.setNeedsLayout()
    }

    private func wrap(_ child: UIView, insets: UIEdgeInsets) -> UIView {
        let box = UIView()
        box.addSubview(child)
        child.snp.makeConstraints { $0.edges.equalToSuperview().inset(insets) }
        return box
    }

    private func buildSectionHeader(title: String, more: String) -> UIView {
        let row = UIView()
        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .fdFont(ofSize: 18, weight: .medium)
        titleLbl.textColor = .fdText
        let moreLbl = UILabel()
        moreLbl.text = more
        moreLbl.font = .fdFont(ofSize: 16, weight: .regular)
        moreLbl.textColor = .fdSubtext
        moreLbl.textAlignment = .right
        row.addSubview(titleLbl)
        row.addSubview(moreLbl)
        titleLbl.snp.makeConstraints { $0.leading.centerY.equalToSuperview() }
        moreLbl.snp.makeConstraints { $0.trailing.centerY.equalToSuperview() }
        row.snp.makeConstraints { $0.height.equalTo(24) }
        return row
    }

    private func buildEmpty() -> UIView {
        let lbl = UILabel()
        lbl.text = "暂无今日健康任务"
        lbl.font = .fdBody
        lbl.textColor = .fdSubtext
        lbl.textAlignment = .center
        lbl.snp.makeConstraints { $0.height.equalTo(120) }
        return lbl
    }

    private func buildTaskCard(_ task: DailyHealthTask) -> DailyTaskCardView {
        let card = DailyTaskCardView()
        card.configure(with: task)
        card.onAction = { task.pushMonitorTaskRoute(source: "DailyTasksDetail") }
        return card
    }

    private func buildTipCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 0.5
        card.layer.borderColor = UIColor(hexString: "#EEEEEE").cgColor

        let title = UILabel()
        title.text = "温馨提示"
        title.font = .fdFont(ofSize: 16, weight: .medium)
        title.textColor = .fdText

        let body = UILabel()
        body.text = viewModel.tipText
        body.font = .fdFont(ofSize: 14, weight: .regular)
        body.textColor = UIColor(hexString: "#A6ACB8")
        body.numberOfLines = 0

        card.addSubview(title)
        card.addSubview(body)
        title.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        body.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
        }
        return card
    }
}
