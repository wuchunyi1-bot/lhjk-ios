import UIKit
import SnapKit

/// 通知中心独立页 — 参考 funde-client NotificationsView.vue
final class NotificationsViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    private var notifications: [AppNotification] = []

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.dataSource = self
        tv.delegate = self
        tv.register(NotificationCardCell.self, forCellReuseIdentifier: NotificationCardCell.reuseID)
        return tv
    }()

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        loadData()
    }

    override func setupUI() {
        title = "通知中心"
        view.backgroundColor = .fdBg

        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func loadData() {
        notifications = IMService.shared.getNotifications()
        IMService.shared.markNotificationsRead()
        tableView.reloadData()
    }

    // MARK: - UITableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        notifications.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCardCell.reuseID, for: indexPath) as! NotificationCardCell
        cell.configure(notifications[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}

// MARK: - NotificationCardCell

private final class NotificationCardCell: UITableViewCell {
    static let reuseID = "NotificationCardCell"

    private let iconView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let tagLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 14
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 4
        card.layer.shadowOpacity = 0.03

        iconView.layer.cornerRadius = 12
        iconView.clipsToBounds = true
        iconImageView.contentMode = .scaleAspectFit

        titleLabel.font = .fdFont(ofSize: 14, weight: .bold)
        titleLabel.textColor = .fdText

        bodyLabel.font = .fdFont(ofSize: 12)
        bodyLabel.textColor = .fdSubtext
        bodyLabel.numberOfLines = 2

        tagLabel.font = .fdFont(ofSize: 10)
        tagLabel.textColor = .fdSubtext
        tagLabel.backgroundColor = .fdBg2
        tagLabel.layer.cornerRadius = 4
        tagLabel.clipsToBounds = true

        timeLabel.font = .fdFont(ofSize: 10)
        timeLabel.textColor = .fdMuted
        timeLabel.textAlignment = .right

        contentView.addSubview(card)
        [iconView, titleLabel, bodyLabel, tagLabel, timeLabel].forEach(card.addSubview)
        iconView.addSubview(iconImageView)

        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-4)
        }

        iconView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(14)
            make.size.equalTo(38)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
        }

        timeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-14)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
        }

        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(3)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-14)
        }

        tagLabel.snp.makeConstraints { make in
            make.top.equalTo(bodyLabel.snp.bottom).offset(6)
            make.leading.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-14)
            make.height.equalTo(20)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ noti: AppNotification) {
        iconView.backgroundColor = UIColor(hexString: noti.iconBg)
        iconImageView.image = UIImage(systemName: noti.icon)
        iconImageView.tintColor = UIColor(hexString: noti.iconColor)
        titleLabel.text = noti.title
        bodyLabel.text = noti.body
        tagLabel.text = " \(noti.tag) "
        timeLabel.text = noti.time
    }
}
