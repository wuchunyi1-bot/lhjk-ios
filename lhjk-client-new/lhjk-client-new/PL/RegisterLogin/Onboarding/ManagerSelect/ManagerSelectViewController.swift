import UIKit
import SnapKit
import Combine

/// 选择业务经理 — 对齐 funde `ManagerSelectView`
final class ManagerSelectViewController: BaseViewController {

    private let viewModel: ManagerSelectViewModel
    private var cancellables = Set<AnyCancellable>()

    /// 选中后回调
    var onManagerSelected: ((DoctorVo) -> Void)?

    private let institutionLabel = UILabel()
    private let searchField = UITextField()
    private let clearButton = UIButton(type: .system)
    private let hintLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let resultCountLabel = UILabel()

    init(hospitalId: String, hospitalName: String, selectedId: String? = nil) {
        self.viewModel = ManagerSelectViewModel(
            hospitalId: hospitalId,
            hospitalName: hospitalName,
            selectedId: selectedId
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

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

        institutionLabel.font = .fdCaption
        institutionLabel.textColor = .fdSubtext
        institutionLabel.numberOfLines = 2
        if !viewModel.hospitalName.isEmpty {
            let attachment = NSTextAttachment()
            attachment.image = UIImage(systemName: "building.2")?
                .withTintColor(.fdSubtext, renderingMode: .alwaysOriginal)
            attachment.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)
            let attr = NSMutableAttributedString(attachment: attachment)
            attr.append(NSAttributedString(
                string: " \(viewModel.hospitalName)",
                attributes: [
                    .font: UIFont.fdCaption,
                    .foregroundColor: UIColor.fdSubtext,
                ]
            ))
            institutionLabel.attributedText = attr
        }

        let searchShell = UIView()
        searchShell.backgroundColor = .fdSurface
        searchShell.layer.cornerRadius = 12
        searchShell.layer.borderWidth = 1
        searchShell.layer.borderColor = UIColor.fdBorder.cgColor

        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = .fdMuted
        searchIcon.contentMode = .scaleAspectFit

        searchField.placeholder = "搜索姓名、经理号或职位"
        searchField.font = .fdBody
        searchField.textColor = .fdText
        searchField.clearButtonMode = .never
        searchField.returnKeyType = .search
        searchField.addTarget(self, action: #selector(keywordChanged), for: .editingChanged)

        clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        clearButton.tintColor = .fdMuted
        clearButton.isHidden = true
        clearButton.addTarget(self, action: #selector(clearKeyword), for: .touchUpInside)

        searchShell.addSubview(searchIcon)
        searchShell.addSubview(searchField)
        searchShell.addSubview(clearButton)

        hintLabel.text = "请选择一位业务经理，提交后将自动绑定"
        hintLabel.font = .fdCaption
        hintLabel.textColor = .fdSubtext

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 78
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(ManagerSelectCell.self, forCellReuseIdentifier: ManagerSelectCell.reuseID)

        emptyLabel.font = .fdBody
        emptyLabel.textColor = .fdMuted
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true

        resultCountLabel.font = .fdCaption
        resultCountLabel.textColor = .fdSubtext
        resultCountLabel.isHidden = true

        view.addSubview(institutionLabel)
        view.addSubview(searchShell)
        view.addSubview(hintLabel)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        view.addSubview(resultCountLabel)

        institutionLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        searchShell.snp.makeConstraints { make in
            make.top.equalTo(institutionLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }
        clearButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        searchField.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(8)
            make.trailing.equalTo(clearButton.snp.leading).offset(-6)
            make.centerY.equalToSuperview()
        }
        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(searchShell.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(hintLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(40)
        }
        resultCountLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(18)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
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
                self.emptyLabel.isHidden = !empty
                if empty {
                    self.emptyLabel.text = searching
                        ? "未找到匹配人员\n请尝试搜索姓名或经理号"
                        : "暂无业务经理\n请稍后再试或更换机构"
                }
                self.resultCountLabel.isHidden = !(searching && !items.isEmpty)
                if searching, !items.isEmpty {
                    self.resultCountLabel.text = "共找到 \(items.count) 位业务经理"
                }
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading, self?.viewModel.items.isEmpty == true {
                    self?.hintLabel.text = "正在加载业务经理..."
                } else {
                    self?.hintLabel.text = "请选择一位业务经理，提交后将自动绑定"
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
}
