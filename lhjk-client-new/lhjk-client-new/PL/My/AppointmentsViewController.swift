import UIKit
import SnapKit

/// 我的预约
/// 参考 funde-client: AppointmentsView.vue
final class AppointmentsViewController: BaseViewController {

    private var activeTab = 0
    private let scrollView = UIScrollView()

    private let upcoming: [(title: String, type: String, time: String, place: String, status: String, daysLeft: Int)] = [
        ("慈铭高端体检", "线下体检", "2026-05-28 08:30", "上海陆家嘴中心", "待到店", 2),
        ("营养师线上复诊", "视频问诊", "2026-06-02 19:00", "视频咨询", "已确认", 7),
        ("王顾问健管随访", "电话随访", "2026-06-10 14:30", "电话", "待确认", 15),
    ]

    private let history: [(title: String, type: String, time: String, place: String, status: String, rating: String)] = [
        ("首次健康评估", "线下评估", "2026-03-05 09:00", "上海徐汇服务中心", "已完成", "满意"),
        ("体检报告解读", "视频咨询", "2026-04-18 16:00", "视频咨询", "已完成", "非常满意"),
    ]

    override func setupUI() {
        title = "我的预约"
        view.backgroundColor = .fdBg

        let seg = UISegmentedControl(items: ["即将到来", "历史记录"])
        seg.selectedSegmentIndex = 0
        seg.selectedSegmentTintColor = .fdPrimary
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13, weight: .semibold)], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.systemFont(ofSize: 13)], for: .normal)
        seg.backgroundColor = .fdBg2
        seg.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        view.addSubview(seg)
        seg.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(seg.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }

        renderContent()
    }

    @objc private func segmentChanged(_ seg: UISegmentedControl) {
        activeTab = seg.selectedSegmentIndex
        renderContent()
    }

    private func renderContent() {
        scrollView.subviews.forEach { $0.removeFromSuperview() }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 20, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        if activeTab == 0 {
            for item in upcoming {
                stack.addArrangedSubview(buildUpcomingCard(item))
            }
        } else {
            for item in history {
                stack.addArrangedSubview(buildHistoryCard(item))
            }
        }
    }

    private func buildUpcomingCard(_ item: (title: String, type: String, time: String, place: String, status: String, daysLeft: Int)) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03

        // Time row
        let timeRow = UIStackView()
        timeRow.axis = .horizontal
        timeRow.alignment = .center
        timeRow.distribution = .equalSpacing

        let daysLabel = UILabel()
        daysLabel.text = "距今还有 \(item.daysLeft) 天"
        daysLabel.font = .systemFont(ofSize: 13, weight: .bold)
        daysLabel.textColor = .fdPrimary

        let timeLabel = UILabel()
        timeLabel.text = item.time
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = .fdSubtext

        timeRow.addArrangedSubview(daysLabel)
        timeRow.addArrangedSubview(timeLabel)

        // Title
        let titleLbl = UILabel()
        titleLbl.text = item.title
        titleLbl.font = .systemFont(ofSize: 18, weight: .bold)
        titleLbl.textColor = .fdText

        // Type + place
        let metaLbl = UILabel()
        metaLbl.text = "\(item.type) · \(item.place)"
        metaLbl.font = .systemFont(ofSize: 13)
        metaLbl.textColor = .fdSubtext

        // Footer
        let footer = UIStackView()
        footer.axis = .horizontal
        footer.alignment = .center
        footer.distribution = .equalSpacing

        let tagBg = item.status == "待到店" ? UIColor.fdPrimarySoft :
                     item.status == "已确认" ? UIColor.fdSuccessSoft : UIColor(hexString: "#F5F5F5")
        let tagFg = item.status == "待到店" ? UIColor.fdPrimary :
                     item.status == "已确认" ? UIColor.fdSuccess : UIColor(hexString: "#999999")
        footer.addArrangedSubview(buildTag(item.status, bg: tagBg, fg: tagFg))

        let actions = UIStackView()
        actions.axis = .horizontal
        actions.spacing = 8

        let rescheduleBtn = buildActionBtn("改期", color: .fdPrimary)
        let cancelBtn = buildActionBtn("取消", color: .fdDanger)
        actions.addArrangedSubview(rescheduleBtn)
        actions.addArrangedSubview(cancelBtn)
        footer.addArrangedSubview(actions)

        card.addSubview(timeRow)
        card.addSubview(titleLbl)
        card.addSubview(metaLbl)
        card.addSubview(footer)

        timeRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        titleLbl.snp.makeConstraints { make in
            make.top.equalTo(timeRow.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        metaLbl.snp.makeConstraints { make in
            make.top.equalTo(titleLbl.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        footer.snp.makeConstraints { make in
            make.top.equalTo(metaLbl.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }

        return card
    }

    private func buildHistoryCard(_ item: (title: String, type: String, time: String, place: String, status: String, rating: String)) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        card.alpha = 0.85

        let titleLbl = UILabel()
        titleLbl.text = item.title
        titleLbl.font = .systemFont(ofSize: 16, weight: .bold)
        titleLbl.textColor = .fdText

        let metaLbl = UILabel()
        metaLbl.text = "\(item.type) · \(item.time)"
        metaLbl.font = .systemFont(ofSize: 13)
        metaLbl.textColor = .fdSubtext

        let placeLbl = UILabel()
        placeLbl.text = item.place
        placeLbl.font = .systemFont(ofSize: 13)
        placeLbl.textColor = .fdSubtext

        let footer = UIStackView()
        footer.axis = .horizontal
        footer.spacing = 8
        footer.addArrangedSubview(buildTag(item.status, bg: .fdSuccessSoft, fg: .fdSuccess))
        footer.addArrangedSubview(buildTag(item.rating, bg: .fdSuccessSoft, fg: .fdSuccess))
        footer.addArrangedSubview(UIView())

        card.addSubview(titleLbl)
        card.addSubview(metaLbl)
        card.addSubview(placeLbl)
        card.addSubview(footer)

        titleLbl.snp.makeConstraints { make in make.top.leading.trailing.equalToSuperview().inset(16) }
        metaLbl.snp.makeConstraints { make in
            make.top.equalTo(titleLbl.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        placeLbl.snp.makeConstraints { make in
            make.top.equalTo(metaLbl.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        footer.snp.makeConstraints { make in
            make.top.equalTo(placeLbl.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }

        return card
    }

    private func buildTag(_ text: String, bg: UIColor, fg: UIColor) -> UIView {
        let v = UIView()
        v.backgroundColor = bg
        v.layer.cornerRadius = 999
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 10, weight: .semibold)
        l.textColor = fg
        v.addSubview(l)
        l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        return v
    }

    private func buildActionBtn(_ title: String, color: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        btn.setTitleColor(color, for: .normal)
        btn.layer.borderColor = color.cgColor
        btn.layer.borderWidth = 1
        btn.layer.cornerRadius = 8
        btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        return btn
    }
}
