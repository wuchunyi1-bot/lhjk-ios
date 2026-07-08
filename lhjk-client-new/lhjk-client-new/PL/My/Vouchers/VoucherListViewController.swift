import UIKit
import SnapKit
import Combine

/// 我的卡券 / 兑换记录页
final class VoucherListViewController: BaseViewController {

    // MARK: - ViewModel

    private let viewModel = VoucherListViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI

    private lazy var segmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["全部", "未使用", "已激活", "已过期"])
        sc.selectedSegmentIndex = 0
        sc.setTitleTextAttributes([
            .font: UIFont.fdCaptionSemibold, .foregroundColor: UIColor.fdSubtext,
        ], for: .normal)
        sc.setTitleTextAttributes([
            .font: UIFont.fdCaptionSemibold, .foregroundColor: UIColor.white,
        ], for: .selected)
        sc.selectedSegmentTintColor = .fdPrimary
        sc.addTarget(self, action: #selector(tabChanged(_:)), for: .valueChanged)
        return sc
    }()

    private let segmentContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .fdBg
        return v
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.register(VoucherCell.self, forCellReuseIdentifier: VoucherCell.reuseIdentifier)
        tv.dataSource = self
        tv.delegate = self
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        return tv
    }()

    private lazy var emptyView: UIView = {
        let v = UIView()
        let icon = UILabel()
        icon.text = "📭"
        icon.font = .systemFont(ofSize: 42)
        icon.textAlignment = .center
        v.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
        }
        let label = UILabel()
        label.text = "暂无相关卡券"
        label.font = .fdCaption
        label.textColor = .fdMuted
        label.textAlignment = .center
        v.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(icon.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
        return v
    }()

    private lazy var getMoreView: UIView = {
        let container = UIView()
        container.backgroundColor = .fdSurface
        container.layer.cornerRadius = 14
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.fdBorder.cgColor
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 1)
        container.layer.shadowRadius = 6
        container.layer.shadowOpacity = 0.03
        container.isUserInteractionEnabled = true
        container.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(getMoreTapped)))

        let icon = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        icon.image = UIImage(systemName: "plus.circle")?.withConfiguration(config)
        icon.tintColor = .fdPrimary
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = "获取更多三好卡健康服务"
        label.font = .fdCaptionSemibold
        label.textColor = .fdText

        let arrow = UIImageView()
        let arrowConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        arrow.image = UIImage(systemName: "chevron.right")?.withConfiguration(arrowConfig)
        arrow.tintColor = .fdMuted
        arrow.contentMode = .scaleAspectFit

        [icon, label, arrow].forEach(container.addSubview)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16); make.centerY.equalToSuperview(); make.size.equalTo(18)
        }
        label.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(8); make.centerY.equalToSuperview()
        }
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16); make.centerY.equalToSuperview(); make.size.equalTo(14)
        }
        return container
    }()

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.loadData()
    }

    override func setupUI() {
        title = "我的卡券"
        view.backgroundColor = .fdBg

        view.addSubview(segmentContainer)
        segmentContainer.addSubview(segmentControl)
        segmentContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        segmentControl.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(segmentContainer.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(segmentContainer.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.isHidden = true

        let footerContainer = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 60))
        footerContainer.addSubview(getMoreView)
        getMoreView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
        tableView.tableFooterView = footerContainer

        bindViewModel()
    }

    // MARK: - Binding

    override func bindViewModel() {
        viewModel.$isEmpty
            .receive(on: DispatchQueue.main)
            .sink { [weak self] empty in
                self?.tableView.isHidden = empty
                self?.emptyView.isHidden = !empty
            }
            .store(in: &cancellables)

        viewModel.$filteredVouchers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func tabChanged(_ sender: UISegmentedControl) {
        viewModel.selectTab(sender.selectedSegmentIndex)
    }

    @objc private func getMoreTapped() {
        Router.shared.push("/services")
    }

    private func activateVoucher(_ voucher: MVoucher) {
        Router.shared.push("/activate/choose", params: ["card": voucher.cardNo])
    }
}

// MARK: - UITableViewDataSource

extension VoucherListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.filteredVouchers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VoucherCell.reuseIdentifier, for: indexPath) as? VoucherCell else {
            return UITableViewCell()
        }
        let voucher = viewModel.filteredVouchers[indexPath.row]
        cell.configure(voucher: voucher)
        cell.onActivate = { [weak self] in self?.activateVoucher(voucher) }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension VoucherListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        140
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
