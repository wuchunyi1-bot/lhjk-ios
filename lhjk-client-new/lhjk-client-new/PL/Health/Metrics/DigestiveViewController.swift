import UIKit
import SnapKit

/// 消化道健康 — 只读报告 + 时间线
/// 参考 funde-client: DigestiveView.vue
final class DigestiveViewController: BaseViewController {

    private let reports: [(date: String, type: String, conclusion: String, detail: String, source: String, status: String)] = [
        ("2026-03-15", "无痛胃镜", "慢性浅表性胃炎", "胃窦部黏膜充血，未见溃疡及新生物，幽门螺旋杆菌阴性", "上海瑞金医院消化科", "mild"),
        ("2025-09-10", "碳13呼气试验", "HP 阴性", "幽门螺旋杆菌检测阴性，消化道环境正常", "慈铭体检中心", "normal"),
        ("2025-03-08", "无痛胃镜", "慢性浅表性胃炎", "胃窦部黏膜轻度充血，幽门螺旋杆菌阴性", "上海瑞金医院消化科", "mild"),
    ]

    private let tips = [
        "规律三餐，避免暴饮暴食，每餐七分饱",
        "减少辛辣、油腻及过冷过热食物摄入",
        "戒烟限酒，咖啡因摄入适量",
        "保持良好心态，避免长期精神紧张",
        "出现持续腹痛、黑便等症状及时就医",
    ]

    override func setupUI() {
        title = "消化道健康"; view.backgroundColor = .fdBg
        let scroll = UIScrollView(); view.addSubview(scroll); scroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        let c = UIView(); scroll.addSubview(c); c.snp.makeConstraints { $0.edges.width.equalToSuperview() }
        let p: CGFloat = 16

        // Latest result card
        let card = UIView(); card.backgroundColor = UIColor(hexString: "#5C4033"); card.layer.cornerRadius = 24
        let badge = tag("最新检测结果", bg: UIColor.white.withAlphaComponent(0.2), fg: .white)
        let icon = UILabel(); icon.text = "🫁"; icon.font = .fdFont(ofSize: 40); icon.textAlignment = .center
        let type = UILabel(); type.text = reports[0].type; type.font = .fdBody; type.textColor = UIColor.white.withAlphaComponent(0.8); type.textAlignment = .center
        let conclusion = UILabel(); conclusion.text = reports[0].conclusion; conclusion.font = .fdH2; conclusion.textColor = .white; conclusion.textAlignment = .center
        let date = UILabel(); date.text = "\(reports[0].date) · \(reports[0].source)"; date.font = .fdCaption; date.textColor = UIColor.white.withAlphaComponent(0.7); date.textAlignment = .center
        card.addSubview(badge); card.addSubview(icon); card.addSubview(type); card.addSubview(conclusion); card.addSubview(date)
        c.addSubview(card)
        card.snp.makeConstraints { $0.top.equalToSuperview().offset(12); $0.leading.trailing.equalToSuperview().inset(p) }
        badge.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(20) }
        icon.snp.makeConstraints { $0.top.equalTo(badge.snp.bottom).offset(12); $0.centerX.equalToSuperview() }
        type.snp.makeConstraints { $0.top.equalTo(icon.snp.bottom).offset(4); $0.centerX.equalToSuperview() }
        conclusion.snp.makeConstraints { $0.top.equalTo(type.snp.bottom).offset(4); $0.centerX.equalToSuperview() }
        date.snp.makeConstraints { $0.top.equalTo(conclusion.snp.bottom).offset(4); $0.centerX.equalToSuperview(); $0.bottom.equalToSuperview().offset(-20) }

        // Info note
        let note = UIView(); note.backgroundColor = .fdInfoSoft; note.layer.cornerRadius = 12
        let noteLbl = UILabel(); noteLbl.text = "ℹ️ 消化道检查需要专业医疗机构进行，无法自行录入。如需安排胃肠镜或呼气试验，请联系您的健管师协助预约。"
        noteLbl.font = .fdCaption; noteLbl.textColor = .fdInfo; noteLbl.numberOfLines = 0
        note.addSubview(noteLbl); noteLbl.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
        c.addSubview(note); note.snp.makeConstraints { $0.top.equalTo(card.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(p) }

        // Health tips
        let tipsSection = sectionTitle("消化道健康建议"); c.addSubview(tipsSection)
        tipsSection.snp.makeConstraints { $0.top.equalTo(note.snp.bottom).offset(20); $0.leading.trailing.equalToSuperview().inset(p) }

        let tipsCard = UIView(); tipsCard.backgroundColor = .fdSurface; tipsCard.layer.cornerRadius = 18; tipsCard.addFundeShadow()
        c.addSubview(tipsCard)
        tipsCard.snp.makeConstraints { $0.top.equalTo(tipsSection.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(p) }
        var prevTip: UIView?
        for (i, tip) in tips.enumerated() {
            let row = UIStackView(); row.axis = .horizontal; row.spacing = 8; row.alignment = .top
            let check = UILabel(); check.text = "✓"; check.font = .fdBodyBold; check.textColor = .fdSuccess
            let lbl = UILabel(); lbl.text = tip; lbl.font = .fdBody; lbl.textColor = .fdText2; lbl.numberOfLines = 0
            row.addArrangedSubview(check); row.addArrangedSubview(lbl)
            tipsCard.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                if let prev = prevTip { make.top.equalTo(prev.snp.bottom).offset(10) } else { make.top.equalToSuperview().inset(14) }
            }
            prevTip = row
        }
        prevTip?.snp.makeConstraints { $0.bottom.equalToSuperview().offset(-14) }

        // History timeline
        let histSection = sectionTitle("历次报告"); c.addSubview(histSection)
        histSection.snp.makeConstraints { $0.top.equalTo(tipsCard.snp.bottom).offset(20); $0.leading.trailing.equalToSuperview().inset(p) }

        let timelineContainer = UIView(); c.addSubview(timelineContainer)
        timelineContainer.snp.makeConstraints { $0.top.equalTo(histSection.snp.bottom); $0.leading.trailing.equalToSuperview().inset(p + 16); $0.bottom.equalToSuperview().offset(-20) }
        var prevBar: UIView?
        for (i, r) in reports.enumerated() {
            let item = buildTimelineItem(r, isFirst: i == 0, isLast: i == reports.count - 1)
            timelineContainer.addSubview(item)
            item.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                if let prev = prevBar { make.top.equalTo(prev.snp.bottom) } else { make.top.equalToSuperview() }
            }
            prevBar = item
        }
        prevBar?.snp.makeConstraints { $0.bottom.equalToSuperview() }
    }

    private func buildTimelineItem(_ r: (date: String, type: String, conclusion: String, detail: String, source: String, status: String), isFirst: Bool, isLast: Bool) -> UIView {
        let item = UIView()
        let dot = UIView(); dot.backgroundColor = r.status == "normal" ? .fdSuccess : .fdWarning; dot.layer.cornerRadius = 5
        let line = UIView(); line.backgroundColor = .fdBorder
        item.addSubview(dot); item.addSubview(line)

        let content = UIView()
        let dateLbl = UILabel(); dateLbl.text = "\(r.date) · \(r.type)"; dateLbl.font = .fdCaptionSemibold; dateLbl.textColor = .fdText
        let conclusionLbl = UILabel(); conclusionLbl.text = r.conclusion; conclusionLbl.font = .fdBodyBold; conclusionLbl.textColor = .fdText
        let detailLbl = UILabel(); detailLbl.text = r.detail; detailLbl.font = .fdCaption; detailLbl.textColor = .fdSubtext; detailLbl.numberOfLines = 0
        let sourceLbl = UILabel(); sourceLbl.text = "📍 \(r.source)"; sourceLbl.font = .fdCaption; sourceLbl.textColor = .fdMuted
        content.addSubview(dateLbl); content.addSubview(conclusionLbl); content.addSubview(detailLbl); content.addSubview(sourceLbl)
        dateLbl.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        conclusionLbl.snp.makeConstraints { $0.top.equalTo(dateLbl.snp.bottom).offset(4); $0.leading.trailing.equalToSuperview() }
        detailLbl.snp.makeConstraints { $0.top.equalTo(conclusionLbl.snp.bottom).offset(6); $0.leading.trailing.equalToSuperview() }
        sourceLbl.snp.makeConstraints { $0.top.equalTo(detailLbl.snp.bottom).offset(6); $0.leading.trailing.equalToSuperview(); $0.bottom.equalToSuperview() }
        item.addSubview(content)

        dot.snp.makeConstraints { $0.top.equalToSuperview().offset(isFirst ? 4 : 0); $0.leading.equalToSuperview(); $0.size.equalTo(10) }
        line.snp.makeConstraints { $0.top.equalTo(dot.snp.bottom); $0.centerX.equalTo(dot); $0.width.equalTo(1) }
        if !isLast { line.snp.makeConstraints { $0.bottom.equalTo(content) } }
        content.snp.makeConstraints { make in make.top.equalToSuperview(); make.leading.equalTo(dot.snp.trailing).offset(12); make.trailing.equalToSuperview(); make.bottom.equalToSuperview().offset(-20) }
        return item
    }

    private func sectionTitle(_ text: String) -> UIView {
        let v = UIView()
        let l = UILabel(); l.text = text; l.font = .fdBodySemibold; l.textColor = .fdSubtext
        v.addSubview(l); l.snp.makeConstraints { $0.top.leading.bottom.equalToSuperview(); $0.height.equalTo(28) }; return v
    }
    private func tag(_ text: String, bg: UIColor, fg: UIColor) -> UIView {
        let v = UIView(); v.backgroundColor = bg; v.layer.cornerRadius = 999
        let l = UILabel(); l.text = text; l.font = .fdMicro; l.textColor = fg
        v.addSubview(l); l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }; return v
    }
}
