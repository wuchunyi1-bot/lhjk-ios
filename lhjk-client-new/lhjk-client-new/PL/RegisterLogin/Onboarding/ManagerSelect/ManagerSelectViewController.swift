import UIKit
import SnapKit
import Combine

/// 选择业务经理 — 对齐 Figma `5346:16150`
final class ManagerSelectViewController: BaseViewController {

    private let viewModel: ManagerSelectViewModel
    private var cancellables = Set<AnyCancellable>()

    /// 选中后回调
    var onManagerSelected: ((DoctorVo) -> Void)?

    private let hospitalIcon = UIImageView(image: UIImage(named: "onboarding_hospital_icon_small"))
    private let institutionLabel = UILabel()
    private let searchField = UITextField()
    private let clearButton = UIButton(type: .system)
    private let sheetView = UIView()
    private let hintLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = FDEmptyStateView(style: .compact, message: "暂无业务经理\n请稍后再试或更换机构")

    init(hospitalId: String, hospitalName: String, selectedId: String? = nil) {
        self.viewModel = ManagerSelectViewModel(
            hospitalId: hospitalId,
            hospitalName: hospitalName,
            selectedId: selectedId
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        title = "选择业务经理"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: .fdNavBack,
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .fdText

        hospitalIcon.contentMode = .scaleAspectFit

        institutionLabel.font = .fdFont(ofSize: 14, weight: .regular)
        institutionLabel.textColor = .fdSubtext
        institutionLabel.numberOfLines = 1
        institutionLabel.text = viewModel.hospitalName

        let hospitalRow = UIStackView(arrangedSubviews: [hospitalIcon, institutionLabel])
        hospitalRow.axis = .horizontal
        hospitalRow.alignment = .center
        hospitalRow.spacing = 4
        hospitalRow.isHidden = viewModel.hospitalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        let searchShell = UIView()
        searchShell.backgroundColor = .fdSurface
        searchShell.layer.cornerRadius = 12

        let searchIcon = UIImageView(image: .fdNavSearch)
        searchIcon.tintColor = .fdTabInactive
        searchIcon.contentMode = .scaleAspectFit

        searchField.font = .fdFont(ofSize: 16, weight: .regular)
        searchField.textColor = .fdText
        searchField.clearButtonMode = .never
        searchField.returnKeyType = .search
        searchField.addTarget(self, action: #selector(keywordChanged), for: .editingChanged)
        searchField.attributedPlaceholder = NSAttributedString(
            string: "搜索姓名 / 经理号 / 职位",
            attributes: [
                .font: UIFont.fdFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor.fdTabInactive,
            ]
        )

        clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        clearButton.tintColor = .fdMuted
        clearButton.isHidden = true
        clearButton.addTarget(self, action: #selector(clearKeyword), for: .touchUpInside)

        searchShell.addSubview(searchIcon)
        searchShell.addSubview(searchField)
        searchShell.addSubview(clearButton)

        sheetView.backgroundColor = .fdSurface
        sheetView.layer.cornerRadius = 16
        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetView.clipsToBounds = true

        let bell = UIImageView(image: UIImage(named: "change_phone_hint_bell"))
        bell.contentMode = .scaleAspectFit

        hintLabel.text = "请选择一位业务经理，提交后将自动绑定"
        hintLabel.font = .fdFont(ofSize: 14, weight: .regular)
        hintLabel.textColor = .fdSubtext

        let hintRow = UIStackView(arrangedSubviews: [bell, hintLabel])
        hintRow.axis = .horizontal
        hintRow.alignment = .center
        hintRow.spacing = 4
        hintRow.setContentHuggingPriority(.required, for: .vertical)
        hintRow.setContentCompressionResistancePriority(.required, for: .vertical)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 76
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.alwaysBounceVertical = true
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.register(ManagerSelectCell.self, forCellReuseIdentifier: ManagerSelectCell.reuseID)

        emptyView.isHidden = true

        view.addSubview(hospitalRow)
        view.addSubview(searchShell)
        view.addSubview(sheetView)
        sheetView.addSubview(hintRow)
        sheetView.addSubview(tableView)
        sheetView.addSubview(emptyView)

        hospitalIcon.snp.makeConstraints { $0.size.equalTo(14) }
        hospitalRow.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        searchShell.snp.makeConstraints { make in
            if hospitalRow.isHidden {
                make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            } else {
                make.top.equalTo(hospitalRow.snp.bottom).offset(12)
            }
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(47)
        }
        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        clearButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        searchField.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(6)
            make.trailing.equalTo(clearButton.snp.leading).offset(-6)
            make.centerY.equalToSuperview()
        }
        sheetView.snp.makeConstraints { make in
            make.top.equalTo(searchShell.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
        bell.snp.makeConstraints { $0.size.equalTo(14) }
        hintRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(hintRow.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.snp.makeConstraints { make in
            make.center.equalTo(tableView)
            make.leading.trailing.equalTo(tableView).inset(24)
        }
    }

    override func bindViewModel() {
        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self else { return }
                self.tableView.reloadData()
                let searching = !self.viewModel.keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let empty = items.isEmpty && !self.viewModel.isLoading
                self.emptyView.isHidden = !empty
                if empty {
                    self.emptyView.configure(
                        message: searching
                            ? "未找到匹配人员\n请尝试搜索姓名或经理号"
                            : "暂无业务经理\n请稍后再试或更换机构"
                    )
                }
            }
            .store(in: &cancellables)

        viewModel.$selectedId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)

        viewModel.onAppear()
    }

    @objc private func backTapped() {
        view.endEditing(true)
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func keywordChanged() {
        viewModel.keyword = searchField.text ?? ""
        clearButton.isHidden = (searchField.text ?? "").isEmpty
    }

    @objc private func clearKeyword() {
        searchField.text = ""
        keywordChanged()
    }
}

// MARK: - UITableView

extension ManagerSelectViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ManagerSelectCell.reuseID, for: indexPath) as! ManagerSelectCell
        let item = viewModel.items[indexPath.row]
        cell.configure(item: item, isSelected: item.id == viewModel.selectedId)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = viewModel.items[indexPath.row]
        viewModel.select(item)
        onManagerSelected?(item)
        navigationController?.popViewController(animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard viewModel.hasMore, !viewModel.isLoadingMore, !viewModel.isLoading else { return }
        let threshold: CGFloat = 100
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        let offset = scrollView.contentOffset.y
        guard contentHeight > 0, offset + frameHeight >= contentHeight - threshold else { return }
        viewModel.loadMore()
    }
}
