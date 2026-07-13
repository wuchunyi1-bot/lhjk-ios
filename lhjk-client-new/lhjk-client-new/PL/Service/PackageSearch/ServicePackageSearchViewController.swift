import UIKit
import SnapKit
import Combine

/// 搜索套餐页 — `GET /v1/hospitalPackage/getEnabledHospitalPackagePage?name=关键字`
final class ServicePackageSearchViewController: BaseViewController {

    private let viewModel: ServicePackageSearchViewModel
    private var cancellables = Set<AnyCancellable>()

    private let searchField: UITextField = {
        let field = UITextField()
        field.placeholder = "搜索套餐名称"
        field.font = .fdBody
        field.textColor = .fdText
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .search
        field.autocorrectionType = .no
        return field
    }()

    private let searchContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .fdSurface
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.fdBorder.cgColor
        return view
    }()

    private let searchIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iv.tintColor = .fdMuted
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.keyboardDismissMode = .onDrag
        tv.register(HealthPackageCardCell.self, forCellReuseIdentifier: HealthPackageCardCell.reuseID)
        tv.dataSource = self
        tv.delegate = self
        return tv
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.font = .fdCaption
        label.textColor = .fdMuted
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    init(hospitalId: String? = nil) {
        self.viewModel = ServicePackageSearchViewModel(hospitalId: hospitalId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func setupUI() {
        title = "搜索套餐"
        view.backgroundColor = .fdBg

        searchContainer.addSubview(searchIcon)
        searchContainer.addSubview(searchField)
        view.addSubview(searchContainer)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        view.addSubview(activityIndicator)

        searchIcon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(18)
        }
        searchField.snp.makeConstraints {
            $0.leading.equalTo(searchIcon.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().offset(-12)
            $0.top.bottom.equalToSuperview().inset(10)
        }
        searchContainer.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.greaterThanOrEqualTo(44)
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(searchContainer.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        emptyLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-40)
            $0.leading.trailing.equalToSuperview().inset(32)
        }
        activityIndicator.snp.makeConstraints { $0.center.equalTo(emptyLabel) }

        searchField.delegate = self
        searchField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }

    override func bindViewModel() {
        viewModel.$packages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
                self?.updateEmptyState()
            }
            .store(in: &cancellables)

        viewModel.$hasSearched
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateEmptyState() }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateEmptyState() }
            .store(in: &cancellables)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchField.becomeFirstResponder()
    }

    @objc private func textDidChange() {
        viewModel.keyword = searchField.text ?? ""
    }

    private func updateEmptyState() {
        guard viewModel.hasSearched, !viewModel.isLoading else {
            emptyLabel.isHidden = true
            return
        }

        if let error = viewModel.errorMessage, !error.isEmpty {
            emptyLabel.text = error
            emptyLabel.isHidden = false
            return
        }

        if viewModel.packages.isEmpty {
            emptyLabel.text = "未找到相关套餐"
            emptyLabel.isHidden = false
            return
        }

        emptyLabel.isHidden = true
    }
}

// MARK: - UITableViewDataSource / Delegate

extension ServicePackageSearchViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.packages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: HealthPackageCardCell.reuseID,
            for: indexPath
        ) as! HealthPackageCardCell
        let pkg = viewModel.packages[indexPath.row]
        cell.configure(pkg)
        cell.onDetailTap = { Router.shared.push("/services/detail", params: ["id": pkg.id]) }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}

// MARK: - UITextFieldDelegate

extension ServicePackageSearchViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        viewModel.keyword = textField.text ?? ""
        viewModel.search()
        textField.resignFirstResponder()
        return true
    }
}
