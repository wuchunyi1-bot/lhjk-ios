import SnapKit
import UIKit

/// 康养小屋列表。门店数据待接口，当前只展示空态，不进入心电监测。
final class WellnessCabinViewController: BaseViewController {

    private let searchField: UITextField = {
        let field = UITextField()
        field.placeholder = "搜索门店"
        field.font = .fdBody
        field.textColor = .fdText
        field.backgroundColor = .fdSurface
        field.layer.cornerRadius = 8
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.leftViewMode = .always
        field.clearButtonMode = .whileEditing
        return field
    }()

    private let recordsButton = UIButton(type: .system)
    private let emptyView = FDEmptyStateView(style: .page, message: "暂无康养小屋", subtitle: "门店列表待接口接入")

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = "康养小屋"
        view.backgroundColor = .fdBg

        recordsButton.setTitle("预约记录", for: .normal)
        recordsButton.setTitleColor(.fdPrimary, for: .normal)
        recordsButton.titleLabel?.font = .fdBody
        recordsButton.addTarget(self, action: #selector(openRecords), for: .touchUpInside)

        view.addSubview(searchField)
        view.addSubview(recordsButton)
        view.addSubview(emptyView)

        searchField.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalTo(recordsButton.snp.leading).offset(-8)
            $0.height.equalTo(40)
        }
        recordsButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(searchField)
        }
        emptyView.snp.makeConstraints {
            $0.top.equalTo(searchField.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    @objc private func openRecords() {
        Router.shared.push("/wellness-cabins/appointments", from: self)
    }
}

/// 门店详情。无门店数据时只展示空态。
final class WellnessCabinDetailViewController: BaseViewController {

    override func setupUI() {
        title = "门店详情"
        view.backgroundColor = .fdBg
        let empty = FDEmptyStateView(style: .page, message: "暂无门店信息")
        view.addSubview(empty)
        empty.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

/// 项目预约。日期、时段和费用待接口。
final class WellnessCabinServiceBookViewController: BaseViewController {

    override func setupUI() {
        title = "项目预约"
        view.backgroundColor = .fdBg
        let empty = FDEmptyStateView(style: .page, message: "暂无可预约时段")
        view.addSubview(empty)
        empty.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

/// 活动详情。
final class WellnessCabinActivityBookViewController: BaseViewController {

    override func setupUI() {
        title = "活动详情"
        view.backgroundColor = .fdBg
        let empty = FDEmptyStateView(style: .page, message: "暂无活动信息")
        view.addSubview(empty)
        empty.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

/// 预约记录。
final class WellnessCabinAppointmentListViewController: BaseViewController {

    override func setupUI() {
        title = "预约记录"
        view.backgroundColor = .fdBg
        let empty = FDEmptyStateView(style: .page, message: "暂无预约记录")
        view.addSubview(empty)
        empty.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

/// 预约详情。
final class WellnessCabinAppointmentDetailViewController: BaseViewController {

    override func setupUI() {
        title = "预约详情"
        view.backgroundColor = .fdBg
        let empty = FDEmptyStateView(style: .page, message: "暂无预约详情")
        view.addSubview(empty)
        empty.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}
