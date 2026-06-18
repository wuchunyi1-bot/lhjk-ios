import UIKit
import SnapKit

/// 鹰瞳眼底 — 只读报告时间线
/// 参考 funde-client: FundusView.vue
final class FundusViewController: BaseViewController {

    private let reports: [(date: String, conclusion: String, detail: String, source: String, status: String)] = [
        ("2026-03-15", "双眼底无异常", "视盘边界清晰，黄斑中心凹反光正常，视网膜血管正常", "慈铭体检中心", "normal"),
        ("2025-09-20", "轻度玻璃膜疣", "双眼黄斑区可见少量玻璃膜疣，建议定期复查", "鹰瞳 AI 眼底筛查", "mild"),
        ("2025-03-10", "双眼底无异常", "视盘边界清晰，视网膜血管走向正常，无出血渗出", "慈铭体检中心", "normal"),
    ]

    override func setupUI() {
        title = "鹰瞳眼底"; view.backgroundColor = .fdBg
        let scroll = UIScrollView(); view.addSubview(scroll); scroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        let c = UIView(); scroll.addSubview(c); c.snp.makeConstraints { $0.edges.width.equalToSuperview() }
        let p: CGFloat = 16

        // Latest card
        let card = UIView(); card.backgroundColor = UIColor(hexString: "#1A3A5C"); card.layer.cornerRadius = 24
        let badge = tag("最新检测结果", bg: UIColor.white.withAlphaComponent(0.2), fg: .white)
        let icon = UILabel(); icon.text = "👁️"; icon.font = .fdFont(ofSize: 40); icon.textAlignment = .center
        let conclusion = UILabel(); conclusion.text = reports[0].conclusion; conclusion.font = .fdH2; conclusion.textColor = .white; conclusion.textAlignment = .center
        let date = UILabel(); date.text = "\(reports[0].date) · \(reports[0].source)"; date.font = .fdCaption; date.textColor = UIColor.white.withAlphaComponent(0.7); date.textAlignment = .center
        card.addSubview(badge); card.addSubview(icon); card.addSubview(conclusion); card.addSubview(date)
        c.addSubview(card)
        card.snp.makeConstraints { $0.top.equalToSuperview().offset(12); $0.leading.trailing.equalToSuperview().inset(p) }
        badge.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(20) }
        icon.snp.makeConstraints { $0.top.equalTo(badge.snp.bottom).offset(12); $0.centerX.equalToSuperview() }
        conclusion.snp.makeConstraints { $0.top.equalTo(icon.snp.bottom).offset(8); $0.centerX.equalToSuperview() }
        date.snp.makeConstraints { $0.top.equalTo(conclusion.snp.bottom).offset(4); $0.centerX.equalToSuperview(); $0.bottom.equalToSuperview().offset(-20) }

        // Info note
        let note = UIView(); note.backgroundColor = .fdInfoSoft; note.layer.cornerRadius = 12
        let noteLbl = UILabel(); noteLbl.text = "ℹ️ 眼底检测需要专业设备，无法通过手机摄像头完成。如需安排检测，请联系您的健管师。"
        noteLbl.font = .fdCaption; noteLbl.textColor = .fdInfo; noteLbl.numberOfLines = 0
        note.addSubview(noteLbl); noteLbl.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
        c.addSubview(note); note.snp.makeConstraints { $0.top.equalTo(card.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(p) }

        // History timeline
        let section = sectionTitle("历次报告"); c.addSubview(section)
        section.snp.makeConstraints { $0.top.equalTo(note.snp.bottom).offset(20); $0.leading.trailing.equalToSuperview().inset(p) }

        var prevBar: UIView = section
        for (i, r) in reports.enumerated() {
            let item = buildTimelineItem(r, isFirst: i == 0, isLast: i == reports.count - 1)
            c.addSubview(item)
            item.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(p + 16)
                make.top.equalTo(prevBar.snp.bottom)
            }
            prevBar = item
        }

        // CTA button
        let btn = UIButton(type: .system); btn.setTitle("联系健管师安排下次检测", for: .normal)
        btn.titleLabel?.font = .fdBodyBold; btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .fdPrimary; btn.layer.cornerRadius = 14
        c.addSubview(btn); btn.snp.makeConstraints { $0.top.equalTo(prevBar.snp.bottom).offset(16); $0.leading.trailing.equalToSuperview().inset(p); $0.height.equalTo(50); $0.bottom.equalToSuperview().offset(-28) }
    }

    private func buildTimelineItem(_ r: (date: String, conclusion: String, detail: String, source: String, status: String), isFirst: Bool, isLast: Bool) -> UIView {
        let item = UIView()
        let dot = UIView(); dot.backgroundColor = r.status == "normal" ? .fdSuccess : .fdWarning; dot.layer.cornerRadius = 5
        let line = UIView(); line.backgroundColor = .fdBorder
        item.addSubview(dot); item.addSubview(line)

        let content = UIView()
        let dateLbl = UILabel(); dateLbl.text = r.date; dateLbl.font = .fdCaptionSemibold; dateLbl.textColor = .fdText
        let conclusionLbl = UILabel(); conclusionLbl.text = r.conclusion; conclusionLbl.font = .fdBodyBold; conclusionLbl.textColor = .fdText
        let detailLbl = UILabel(); detailLbl.text = r.detail; detailLbl.font = .fdCaption; detailLbl.textColor = .fdSubtext; detailLbl.numberOfLines = 0
        let sourceLbl = UILabel(); sourceLbl.text = "📍 \(r.source)"; sourceLbl.font = .fdCaption; sourceLbl.textColor = .fdMuted
        content.addSubview(dateLbl); content.addSubview(conclusionLbl); content.addSubview(detailLbl); content.addSubview(sourceLbl)
        dateLbl.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        conclusionLbl.snp.makeConstraints { $0.top.equalTo(dateLbl.snp.bottom).offset(4); $0.leading.trailing.equalToSuperview() }
        detailLbl.snp.makeConstraints { $0.top.equalTo(conclusionLbl.snp.bottom).offset(6); $0.leading.trailing.equalToSuperview() }
        sourceLbl.snp.makeConstraints { $0.top.equalTo(detailLbl.snp.bottom).offset(6); $0.leading.trailing.equalToSuperview(); $0.bottom.equalToSuperview() }
        item.addSubview(content)

        dot.snp.makeConstraints { $0.top.equalToSuperview(); $0.leading.equalToSuperview(); $0.size.equalTo(10) }
        line.snp.makeConstraints { make in make.top.equalTo(dot.snp.bottom); make.centerX.equalTo(dot); make.width.equalTo(1); if isLast { make.bottom.equalToSuperview().offset(-8) } }
        content.snp.makeConstraints { make in make.top.equalToSuperview(); make.leading.equalTo(dot.snp.trailing).offset(12); make.trailing.equalToSuperview(); make.bottom.equalToSuperview().offset(-20) }
        if isFirst { dot.snp.makeConstraints { $0.top.equalToSuperview().offset(4) } }
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
