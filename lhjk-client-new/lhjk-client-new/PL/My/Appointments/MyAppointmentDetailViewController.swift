import SnapKit
import UIKit

/// 我的预约里的康养记录详情。字段来自预约列表，没有单独的详情接口。
final class MyAppointmentDetailViewController: BaseViewController {

    private let detail: MyCabinAppointmentDetail?

    init(routeParams: [String: Any]) {
        detail = MyCabinAppointmentDetail(routeParams: routeParams)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func setupUI() {
        title = "预约详情"
        view.backgroundColor = .fdBg
        guard let detail else {
            let empty = FDEmptyStateView(style: .page, message: "未找到该预约")
            view.addSubview(empty)
            empty.snp.makeConstraints { $0.edges.equalToSuperview() }
            return
        }

        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        let content = UIView()
        scroll.addSubview(content)
        scroll.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        content.snp.makeConstraints {
            $0.edges.equalTo(scroll.contentLayoutGuide)
            $0.width.equalTo(scroll.frameLayoutGuide)
        }

        let kind = tag("康养小屋", color: .fdSubtext, background: .fdBg2)
        let status = tag(detail.statusTitle, color: statusColor(detail.status).fg, background: statusColor(detail.status).bg)
        let titleRow = UIStackView(arrangedSubviews: [kind, UIView(), status])
        titleRow.axis = .horizontal
        titleRow.alignment = .center

        let name = UILabel()
        name.text = detail.name.isEmpty ? "预约项目" : detail.name
        name.font = .fdH3
        name.textColor = .fdText
        name.numberOfLines = 0

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.addArrangedSubview(titleRow)
        stack.addArrangedSubview(name)
        if let duration = detail.durationText {
            stack.addArrangedSubview(row("时长", duration))
        }
        if !detail.scheduleText.isEmpty {
            stack.addArrangedSubview(row("时间", detail.scheduleText))
        }
        if !detail.placeText.isEmpty {
            stack.addArrangedSubview(row("地点", detail.placeText))
        }
        if let notice = detail.notice {
            let noticeLabel = UILabel()
            noticeLabel.text = notice
            noticeLabel.font = .fdFont(ofSize: 13, weight: .regular)
            noticeLabel.textColor = .fdWarning
            noticeLabel.numberOfLines = 0
            stack.addArrangedSubview(noticeLabel)
        }
        if detail.canBookAgain {
            let button = UIButton(type: .system)
            button.setTitle("再次预约", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = .fdFont(ofSize: 16, weight: .semibold)
            button.backgroundColor = .fdPrimary
            button.layer.cornerRadius = 22
            button.addTarget(self, action: #selector(bookAgain), for: .touchUpInside)
            stack.addArrangedSubview(button)
            button.snp.makeConstraints { $0.height.equalTo(44) }
        }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        card.addSubview(stack)
        content.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-16)
        }
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
    }

    private func row(_ title: String, _ value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .fdFont(ofSize: 13, weight: .regular)
        titleLabel.textColor = .fdMuted
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .fdFont(ofSize: 15, weight: .regular)
        valueLabel.textColor = .fdText
        valueLabel.numberOfLines = 0
        valueLabel.textAlignment = .right
        let line = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        line.axis = .horizontal
        line.alignment = .top
        line.spacing = 12
        return line
    }

    private func tag(_ text: String, color: UIColor, background: UIColor) -> UILabel {
        let label = PaddingLabel()
        label.text = text
        label.font = .fdFont(ofSize: 12, weight: .semibold)
        label.textColor = color
        label.backgroundColor = background
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.textInsets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
        return label
    }

    private func statusColor(_ status: Int?) -> (fg: UIColor, bg: UIColor) {
        switch status {
        case 3: return (.fdInfo, .fdInfoSoft)
        case 4: return (.fdPrimary, .fdPrimarySoft)
        case 5: return (.fdSuccess, .fdSuccessSoft)
        case 7: return (.fdWarning, .fdWarningSoft)
        default: return (.fdMuted, .fdBg2)
        }
    }

    @objc private func bookAgain() {
        guard let hospitalId = detail?.hospitalId, !hospitalId.isEmpty else { return }
        Router.shared.push("/wellness-cabins/detail", params: ["hospitalId": hospitalId], from: self)
    }
}

private final class PaddingLabel: UILabel {
    var textInsets = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + textInsets.left + textInsets.right,
            height: size.height + textInsets.top + textInsets.bottom
        )
    }
}
