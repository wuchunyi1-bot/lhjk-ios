import UIKit
import SnapKit
import Combine

/// 选择服务机构 — 对齐 funde `InstitutionSelectView`
final class InstitutionSelectViewController: BaseViewController {

    private let viewModel: InstitutionSelectViewModel
    private var cancellables = Set<AnyCancellable>()

    private let locationBar = UIView()
    private let locationValueLabel = UILabel()
    private let relocateButton = UIButton(type: .system)
    private let searchField = UITextField()
    private let clearButton = UIButton(type: .system)
    private let hintLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let resultCountLabel = UILabel()

    init(selectedId: String? = nil) {
        self.viewModel = InstitutionSelectViewModel(selectedId: selectedId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func setupUI() {
        view.backgroundColor = .fdBg
        title = "选择服务机构"
        setupLocationBar()
        setupSearch()
        setupTable()
        setupEmpty()
    }

    override func bindViewModel() {
        viewModel.$locationLabel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in self?.locationValueLabel.text = text }
            .store(in: &cancellables)

        viewModel.$isLocating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] locating in
                self?.relocateButton.isEnabled = !locating
                self?.hintLabel.text = locating ? "正在加载服务机构数据..." : "以下为可选择的服务机构"
            }
            .store(in: &cancellables)

        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self else { return }
                self.tableView.reloadData()
                let searching = !(self.viewModel.keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                self.emptyLabel.isHidden = !items.isEmpty || self.viewModel.isLoadingList
                self.resultCountLabel.isHidden = !(searching && !items.isEmpty)
                if searching, !items.isEmpty {
                    self.resultCountLabel.text = "共找到 \(items.count) 家机构"
                }
            }
            .store(in: &cancellables)

        viewModel.$isLoadingList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                guard let self else { return }
                if loading, self.viewModel.items.isEmpty {
                    self.hintLabel.text = "正在加载服务机构数据..."
                }
            }
            .store(in: &cancellables)

        viewModel.$selectedId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)

        viewModel.onAppear()
    }

    // MARK: - UI pieces

    private func setupLocationBar() {
        locationBar.backgroundColor = .fdPrimarySoft
        locationBar.layer.cornerRadius = 14
        locationBar.layer.borderWidth = 1
        locationBar.layer.borderColor = UIColor.fdPrimaryEdge.cgColor

        let icon = UIImageView(image: UIImage(systemName: "location.fill"))
        icon.tintColor = .fdPrimary
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = "当前定位"
        title.font = .fdCaption
        title.textColor = .fdSubtext

        locationValueLabel.font = .fdBodySemibold
        locationValueLabel.textColor = .fdText
        locationValueLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [title, locationValueLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        relocateButton.setTitle("重新定位", for: .normal)
        relocateButton.titleLabel?.font = .fdCaptionSemibold
        relocateButton.setTitleColor(.fdPrimary, for: .normal)
        relocateButton.addTarget(self, action: #selector(relocateTapped), for: .touchUpInside)

        locationBar.addSubview(icon)
        locationBar.addSubview(textStack)
        locationBar.addSubview(relocateButton)
        view.addSubview(locationBar)

        locationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        icon.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(14)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }
        textStack.snp.makeConstraints {
            $0.leading.equalTo(icon.snp.trailing).offset(10)
            $0.top.bottom.equalToSuperview().inset(12)
            $0.trailing.lessThanOrEqualTo(relocateButton.snp.leading).offset(-8)
        }
        relocateButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(44)
        }
    }

    private func setupSearch() {
        let searchBox = UIView()
        searchBox.backgroundColor = .fdSurface
        searchBox.layer.cornerRadius = 12
        searchBox.layer.borderWidth = 1
        searchBox.layer.borderColor = UIColor.fdBorder.cgColor

        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = .fdMuted
        searchIcon.contentMode = .scaleAspectFit

        searchField.placeholder = "搜索机构名称或地址"
        searchField.font = .fdBody
        searchField.textColor = .fdText
        searchField.clearButtonMode = .never
        searchField.returnKeyType = .search
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        searchField.delegate = self

        clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        clearButton.tintColor = .fdMuted
        clearButton.isHidden = true
        clearButton.addTarget(self, action: #selector(clearSearch), for: .touchUpInside)

        searchBox.addSubview(searchIcon)
        searchBox.addSubview(searchField)
        searchBox.addSubview(clearButton)
        view.addSubview(searchBox)

        hintLabel.font = .fdCaption
        hintLabel.textColor = .fdSubtext
        hintLabel.text = "以下为可选择的服务机构"
        view.addSubview(hintLabel)

        searchBox.snp.makeConstraints {
            $0.top.equalTo(locationBar.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
        searchIcon.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(18)
        }
        clearButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(8)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(28)
        }
        searchField.snp.makeConstraints {
            $0.leading.equalTo(searchIcon.snp.trailing).offset(8)
            $0.trailing.equalTo(clearButton.snp.leading).offset(-4)
            $0.top.bottom.equalToSuperview()
        }
        hintLabel.snp.makeConstraints {
            $0.top.equalTo(searchBox.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }

    private func setupTable() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(InstitutionSelectCell.self, forCellReuseIdentifier: InstitutionSelectCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        view.addSubview(tableView)

        resultCountLabel.font = .fdCaption
        resultCountLabel.textColor = .fdSubtext
        resultCountLabel.textAlignment = .center
        resultCountLabel.isHidden = true
        view.addSubview(resultCountLabel)

        tableView.snp.makeConstraints {
            $0.top.equalTo(hintLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(resultCountLabel.snp.top).offset(-4)
        }
        resultCountLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
            $0.height.equalTo(20)
        }
    }

    private func setupEmpty() {
        emptyLabel.text = "未找到匹配机构\n请尝试搜索机构名称或详细地址"
        emptyLabel.font = .fdBody
        emptyLabel.textColor = .fdSubtext
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(tableView)
            $0.leading.trailing.equalToSuperview().inset(32)
        }
    }

    @objc private func relocateTapped() {
        viewModel.refreshLocation()
    }

    @objc private func searchChanged() {
        let text = searchField.text ?? ""
        clearButton.isHidden = text.isEmpty
        viewModel.keyword = text
    }

    @objc private func clearSearch() {
        searchField.text = ""
        clearButton.isHidden = true
        viewModel.keyword = ""
    }
}

extension InstitutionSelectViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: InstitutionSelectCell.reuseID,
            for: indexPath
        ) as! InstitutionSelectCell
        let item = viewModel.items[indexPath.row]
        cell.configure(item: item, isSelected: item.id == viewModel.selectedId)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = viewModel.items[indexPath.row]
        viewModel.select(item)
        navigationController?.popViewController(animated: true)
    }
}

extension InstitutionSelectViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
