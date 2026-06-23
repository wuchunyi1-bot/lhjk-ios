import UIKit
import SnapKit

/// 健康评估
/// 参考 funde-client: HealthEvaluationsView.vue
final class HealthEvaluationsViewController: BaseViewController {

    private let scrollView = UIScrollView()

    private let evaluations: [(emoji: String, title: String, initiator: String, due: String, status: String)] = [
        ("😴", "睡眠质量评估", "王顾问发起", "今天 20:00 前", "pending"),
        ("💊", "用药依从性评估", "慢病管理团队发起", "明天 12:00 前", "pending"),
        ("❤️", "心血管风险评估", "系统自动发起", "本周五前", "pending"),
        ("🏃", "运动风险筛查", "系统自动发起", "已完成", "done"),
        ("🥗", "营养摄入评估", "王顾问发起", "已完成", "done"),
        ("🫀", "慢病风险自测", "系统每季度", "已完成", "done"),
        ("🧠", "心理健康评估", "王顾问发起", "已完成", "done"),
    ]

    override func setupUI() {
        title = "健康评估"
        view.backgroundColor = .fdBg

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 20, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        let pendingCount = evaluations.filter { $0.status == "pending" }.count
        if pendingCount > 0 {
            let bar = UIView()
            bar.backgroundColor = .fdPrimarySoft
            bar.layer.cornerRadius = 18

            let label = UILabel()
            label.text = "📋 还有 \(pendingCount) 项评估待完成"
            label.font = .fdBody
            label.textColor = .fdPrimary
            bar.addSubview(label)
            label.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)) }
            stack.addArrangedSubview(bar)
        }

        for eval in evaluations {
            stack.addArrangedSubview(buildEvalCard(eval))
        }
    }

    private func buildEvalCard(_ eval: (emoji: String, title: String, initiator: String, due: String, status: String)) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        card.alpha = eval.status == "done" ? 0.7 : 1.0

        // Icon circle
        let iconView = UIView()
        iconView.layer.cornerRadius = 22
        iconView.backgroundColor = eval.status == "pending" ? .fdPrimarySoft : .fdSuccessSoft

        let iconLbl = UILabel()
        iconLbl.text = eval.emoji
        iconLbl.font = .fdH2
        iconView.addSubview(iconLbl)
        iconLbl.snp.makeConstraints { $0.center.equalToSuperview() }

        // Main info
        let titleLbl = UILabel()
        titleLbl.text = eval.title
        titleLbl.font = .fdBodyBold
        titleLbl.textColor = .fdText

        let metaLbl = UILabel()
        metaLbl.text = "\(eval.initiator) · \(eval.due)"
        metaLbl.font = .fdCaption
        metaLbl.textColor = .fdSubtext

        // Right side
        let tagBg = eval.status == "pending" ? UIColor.fdPrimarySoft : UIColor.fdSuccessSoft
        let tagFg = eval.status == "pending" ? UIColor.fdPrimary : UIColor.fdSuccess
        let tag = buildTag(eval.status == "pending" ? "待评估" : "已完成", bg: tagBg, fg: tagFg)

        let rightCol = UIStackView()
        rightCol.axis = .vertical
        rightCol.alignment = .trailing
        rightCol.spacing = 6
        rightCol.addArrangedSubview(tag)

        if eval.status == "pending" {
            let startLbl = UILabel()
            startLbl.text = "开始 ›"
            startLbl.font = .fdCaptionSemibold
            startLbl.textColor = .fdPrimary
            rightCol.addArrangedSubview(startLbl)
        }

        card.addSubview(iconView)
        card.addSubview(titleLbl)
        card.addSubview(metaLbl)
        card.addSubview(rightCol)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        titleLbl.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
        }
        metaLbl.snp.makeConstraints { make in
            make.top.equalTo(titleLbl.snp.bottom).offset(4)
            make.leading.equalTo(titleLbl)
            make.bottom.equalToSuperview().offset(-14)
        }
        rightCol.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }

        return card
    }

    private func buildTag(_ text: String, bg: UIColor, fg: UIColor) -> UIView {
        let v = UIView()
        v.backgroundColor = bg
        v.layer.cornerRadius = 999
        let l = UILabel()
        l.text = text
        l.font = .fdMicroSemibold
        l.textColor = fg
        v.addSubview(l)
        l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        return v
    }
}
