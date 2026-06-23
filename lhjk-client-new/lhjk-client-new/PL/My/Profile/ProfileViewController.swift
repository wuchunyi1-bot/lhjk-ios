import UIKit
import SnapKit
import Kingfisher

/// 个人信息页
/// 参考 funde-client: ProfileView.vue
final class ProfileViewController: BaseViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var items: [(label: String, value: String, isLink: Bool)] = []
    private var user: SUsers?

    private let emptyItems: [(label: String, value: String, isLink: Bool)] = [
        ("姓名", "加载中…", true),
        ("手机号", "加载中…", true),
        ("昵称", "加载中…", true),
        ("性别", "加载中…", true),
        ("生日", "加载中…", true),
    ]

    override func setupUI() {
        title = "个人信息"
        view.backgroundColor = .fdBg

        // Avatar header
        let headerView = UIView()
        let avatarView: UIImageView = {
            let v = UIImageView()
            v.backgroundColor = .fdPrimary
            v.layer.cornerRadius = 24
            v.clipsToBounds = true
            v.contentMode = .scaleAspectFill
            v.tag = 200
            return v
        }()
        let avatarLabel: UILabel = {
            let l = UILabel()
            l.text = "我"
            l.font = .fdFont(ofSize: 34, weight: .bold)
            l.textColor = .white
            l.textAlignment = .center
            l.tag = 201
            return l
        }()
        avatarView.addSubview(avatarLabel)
        avatarLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        let hint = UILabel()
        hint.text = "点击更换头像"
        hint.font = .fdCaption
        hint.textColor = .fdSubtext
        hint.textAlignment = .center

        headerView.addSubview(avatarView)
        headerView.addSubview(hint)
        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
            make.size.equalTo(80)
        }
        hint.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
        }
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 156)

        tableView.tableHeaderView = headerView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Load data
        items = emptyItems
        loadUserProfile()
    }

    // MARK: - Data Loading

    private func loadUserProfile() {
        let mobile = UserDefaults.standard.string(forKey: "current_user_mobile") ?? ""
        Task {
            do {
                let user = try await UserService.shared.getUserByParam(mobile: mobile)
                await MainActor.run {
                    self.user = user
                    if let user = user {
                        self.items = self.buildItems(from: user)
                        self.updateAvatar(with: user)
                    } else {
                        self.items = [
                            ("提示", "未找到用户信息", false)
                        ]
                    }
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.items = [
                        ("加载失败", error.localizedDescription, false)
                    ]
                    self.tableView.reloadData()
                }
            }
        }
    }

    private func buildItems(from user: SUsers) -> [(label: String, value: String, isLink: Bool)] {
        [
            ("姓名", user.chineseName ?? user.surname ?? "未设置", true),
            ("手机号", maskPhone(user.mobile), true),
            ("昵称", user.nickname ?? "未设置", true),
            ("性别", sexLabel(user.sex), true),
            ("生日", user.birthday ?? "未设置", true),
            ("邮箱", user.email ?? "未设置", true),
            ("地址", user.address ?? user.addressCity ?? "未设置", true),
        ]
    }

    private func updateAvatar(with user: SUsers) {
        let name = user.chineseName ?? user.surname ?? user.nickname ?? ""
        let char = String(name.prefix(1))
        if let avatar = tableView.tableHeaderView {
            if let imageView = avatar.viewWithTag(200) as? UIImageView,
               let label = avatar.viewWithTag(201) as? UILabel {
                if let urlStr = user.imageUrl, let url = URL(string: urlStr) {
                    label.isHidden = true
                    imageView.kf.setImage(with: url)
                } else {
                    label.isHidden = false
                    label.text = char
                }
            }
        }
    }

    private func maskPhone(_ phone: String?) -> String {
        guard let phone = phone, phone.count == 11 else { return phone ?? "未设置" }
        let start = phone.prefix(3)
        let end = phone.suffix(2)
        return "\(start)******\(end)"
    }

    private func sexLabel(_ sex: String?) -> String {
        switch sex {
        case "1": return "男"
        case "2": return "女"
        default: return "未设置"
        }
    }
}

extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = items[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = item.label
        config.secondaryText = item.value
        config.textProperties.color = .fdText
        config.secondaryTextProperties.color = .fdSubtext
        cell.contentConfiguration = config
        cell.accessoryType = item.isLink ? .disclosureIndicator : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
