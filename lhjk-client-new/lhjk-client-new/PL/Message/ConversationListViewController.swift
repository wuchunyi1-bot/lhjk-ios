import UIKit
import SnapKit

/// 会话列表页 — 参考 funde-im ConvoList.vue + ConvoFilters.vue
final class ConversationListViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    private var allConversations: [Conversation] = []
    private var filteredConversations: [Conversation] = []
    private var selectedTag: ConversationTag?

    private lazy var filterScroll: UIScrollView = {
        let sv = UIScrollView(); sv.showsHorizontalScrollIndicator = false
        sv.backgroundColor = .fdBg
        return sv
    }()

    private var filterChips: [UIButton] = []

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.dataSource = self; tv.delegate = self
        tv.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.reuseIdentifier)
        return tv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel(); l.text = "暂无消息"; l.font = .fdBody; l.textColor = .fdMuted; l.textAlignment = .center; l.isHidden = true
        return l
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = "消息"
        view.backgroundColor = .fdBg
        [filterScroll, tableView, emptyLabel].forEach(view.addSubview)

        filterScroll.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(filterScroll.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        emptyLabel.snp.makeConstraints { $0.center.equalTo(tableView) }

        buildFilterChips()
        loadData()
    }

    private func buildFilterChips() {
        let stack = UIStackView(); stack.spacing = 8; stack.axis = .horizontal
        filterScroll.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)) }

        let allBtn = makeChip("全部", selected: true)
        allBtn.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
        allBtn.tag = -1
        stack.addArrangedSubview(allBtn); filterChips.append(allBtn)

        for (i, tag) in ConversationTag.allCases.enumerated() {
            let btn = makeChip(tag.label, selected: false)
            btn.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            btn.tag = i
            stack.addArrangedSubview(btn); filterChips.append(btn)
        }
    }

    private func makeChip(_ text: String, selected: Bool) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(text, for: .normal); b.titleLabel?.font = .fdCaption
        b.setTitleColor(selected ? .white : .fdSubtext, for: .normal)
        b.backgroundColor = selected ? .fdPrimary : .fdBg2
        b.layer.cornerRadius = 14
        b.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        return b
    }

    @objc private func chipTapped(_ sender: UIButton) {
        for (i, c) in filterChips.enumerated() {
            let sel = c == sender
            c.setTitleColor(sel ? .white : .fdSubtext, for: .normal)
            c.backgroundColor = sel ? .fdPrimary : .fdBg2
        }
        selectedTag = sender.tag >= 0 ? ConversationTag.allCases[sender.tag] : nil
        loadData()
    }

    private func loadData() {
        allConversations = IMService.shared.getConversations(filterBy: selectedTag)
        filteredConversations = allConversations
        emptyLabel.isHidden = !filteredConversations.isEmpty
        tableView.reloadData()
    }

    // MARK: - UITableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filteredConversations.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.reuseIdentifier, for: indexPath) as? ConversationCell else {
            return UITableViewCell()
        }
        cell.configure(filteredConversations[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 88 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let c = filteredConversations[indexPath.row]
        let chatVC = ChatViewController(conversation: c)
        navigationController?.pushViewController(chatVC, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let del = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, done in
            IMService.shared.deleteConversation(self?.filteredConversations[indexPath.row].id ?? "")
            self?.loadData(); done(true)
        }
        let pin = UIContextualAction(style: .normal, title: "置顶") { _, _, done in done(true) }
        pin.backgroundColor = .systemOrange
        return UISwipeActionsConfiguration(actions: [del, pin])
    }
}
