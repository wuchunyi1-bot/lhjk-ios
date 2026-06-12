import UIKit
import SnapKit

/// 心电监测
/// 参考 funde-client: EcgView.vue
final class EcgViewController: BaseViewController {

    private let ecgHistory: [(date: String, hr: Int, conclusion: String)] = [
        ("05-17", 76, "正常"), ("05-12", 78, "正常"), ("05-07", 81, "正常"),
        ("05-02", 77, "正常"), ("04-27", 79, "正常"),
    ]

    override func setupUI() {
        title = "心电监测"; view.backgroundColor = .fdBg
        let scroll = UIScrollView(); view.addSubview(scroll); scroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        let c = UIView(); scroll.addSubview(c); c.snp.makeConstraints { $0.edges.width.equalToSuperview() }
        let p: CGFloat = 16

        // Latest result card (dark green bg)
        let resultCard = UIView(); resultCard.backgroundColor = UIColor(hexString: "#1B5E3B"); resultCard.layer.cornerRadius = 24
        let badge = tag("最新报告", bg: UIColor.white.withAlphaComponent(0.2), fg: .white)
        let time = UILabel(); time.text = "本月 12 日"; time.font = .systemFont(ofSize: 12); time.textColor = UIColor.white.withAlphaComponent(0.7)
        let conclusion = UILabel(); conclusion.text = "窦性心律 · 正常心电图"; conclusion.font = .systemFont(ofSize: 20, weight: .bold); conclusion.textColor = .white
        let hr = UILabel(); hr.text = "心率：76 bpm"; hr.font = .systemFont(ofSize: 14); hr.textColor = UIColor.white.withAlphaComponent(0.85)

        // Waveform placeholder
        let waveBox = UIView(); waveBox.backgroundColor = UIColor.white.withAlphaComponent(0.08); waveBox.layer.cornerRadius = 12
        let waveHint = UILabel(); waveHint.text = "📈 ECG 波形图"; waveHint.font = .systemFont(ofSize: 14); waveHint.textColor = UIColor.white.withAlphaComponent(0.5); waveHint.textAlignment = .center
        waveBox.addSubview(waveHint); waveHint.snp.makeConstraints { $0.center.equalToSuperview() }

        resultCard.addSubview(badge); resultCard.addSubview(time); resultCard.addSubview(conclusion); resultCard.addSubview(hr); resultCard.addSubview(waveBox)
        c.addSubview(resultCard)
        resultCard.snp.makeConstraints { $0.top.equalToSuperview().offset(12); $0.leading.trailing.equalToSuperview().inset(p) }
        badge.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(20) }
        time.snp.makeConstraints { $0.centerY.equalTo(badge); $0.trailing.equalToSuperview().offset(-20) }
        conclusion.snp.makeConstraints { $0.top.equalTo(badge.snp.bottom).offset(8); $0.leading.equalToSuperview().inset(20) }
        hr.snp.makeConstraints { $0.top.equalTo(conclusion.snp.bottom).offset(4); $0.leading.equalToSuperview().inset(20) }
        waveBox.snp.makeConstraints { make in make.top.equalTo(hr.snp.bottom).offset(14); make.leading.trailing.equalToSuperview().inset(20); make.height.equalTo(70); make.bottom.equalToSuperview().offset(-20) }

        // Segment
        let seg = makeSeg(["日", "周", "月"]); seg.selectedSegmentIndex = 2; c.addSubview(seg)
        seg.snp.makeConstraints { $0.top.equalTo(resultCard.snp.bottom).offset(14); $0.leading.trailing.equalToSuperview().inset(p); $0.height.equalTo(36) }

        // HR trend bars
        let trendCard = UIView(); trendCard.backgroundColor = .fdSurface; trendCard.layer.cornerRadius = 18; trendCard.addFundeShadow()
        let trendTitle = UILabel(); trendTitle.text = "历次测量心率趋势"; trendTitle.font = .systemFont(ofSize: 13, weight: .semibold); trendTitle.textColor = .fdSubtext
        trendCard.addSubview(trendTitle)
        trendTitle.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(16) }

        var prevBar: UIView = trendTitle
        for (i, item) in ecgHistory.enumerated() {
            let row = UIView()
            let dateLbl = UILabel(); dateLbl.text = item.date; dateLbl.font = .systemFont(ofSize: 12); dateLbl.textColor = .fdSubtext; dateLbl.textAlignment = .right
            let barBg = UIView(); barBg.backgroundColor = .fdBg2; barBg.layer.cornerRadius = 4
            let barFill = UIView(); barFill.backgroundColor = UIColor(hexString: "#52B96A"); barFill.layer.cornerRadius = 4
            barBg.addSubview(barFill)
            let valLbl = UILabel(); valLbl.text = "\(item.hr) bpm"; valLbl.font = .systemFont(ofSize: 13, weight: .semibold); valLbl.textColor = .fdText
            let tagView = tag(item.conclusion, bg: .fdSuccessSoft, fg: .fdSuccess)
            row.addSubview(dateLbl); row.addSubview(barBg); row.addSubview(valLbl); row.addSubview(tagView)
            dateLbl.snp.makeConstraints { $0.leading.equalToSuperview(); $0.centerY.equalToSuperview(); $0.width.equalTo(40) }
            barBg.snp.makeConstraints { make in make.leading.equalTo(dateLbl.snp.trailing).offset(8); make.centerY.equalToSuperview(); make.height.equalTo(12) }
            barFill.snp.makeConstraints { make in make.leading.top.bottom.equalToSuperview(); make.width.equalTo(barBg).multipliedBy(min(Double(item.hr) / 120.0, 1.0)) }
            valLbl.snp.makeConstraints { $0.leading.equalTo(barBg.snp.trailing).offset(8); $0.centerY.equalToSuperview() }
            tagView.snp.makeConstraints { $0.trailing.centerY.equalToSuperview() }
            if i < ecgHistory.count - 1 {
                let d = UIView(); d.backgroundColor = .fdBorder; row.addSubview(d)
                d.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
            }
            trendCard.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                make.top.equalTo(prevBar.snp.bottom).offset(i == 0 ? 12 : 10)
                make.height.equalTo(36)
            }
            prevBar = row
        }
        prevBar.snp.makeConstraints { $0.bottom.equalToSuperview().offset(-16) }
        c.addSubview(trendCard)
        trendCard.snp.makeConstraints { $0.top.equalTo(seg.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(p) }

        // Records
        let mockRecs = [("本月 12 日", "窦性心律·正常", "bluetooth"), ("05-02", "窦性心律·正常", "bluetooth"), ("04-27", "窦性心律·正常", "manual")]
        let recCard = buildRecords(mockRecs); c.addSubview(recCard)
        recCard.snp.makeConstraints { $0.top.equalTo(trendCard.snp.bottom).offset(16); $0.leading.trailing.equalToSuperview().inset(p) }

        let btn = UIButton(type: .system); btn.setTitle("+ 录入数据", for: .normal); btn.styleFundeSoft()
        btn.addTarget(self, action: #selector(addRecord), for: .touchUpInside)
        c.addSubview(btn); btn.snp.makeConstraints { $0.top.equalTo(recCard.snp.bottom).offset(16); $0.leading.trailing.equalToSuperview().inset(p); $0.height.equalTo(44); $0.bottom.equalToSuperview().offset(-20) }
    }

    @objc private func addRecord() { Router.shared.push("/health/metrics/add", params: ["key": "ecg"]) }

    private func makeSeg(_ items: [String]) -> UISegmentedControl {
        let s = UISegmentedControl(items: items); s.selectedSegmentIndex = 2
        s.selectedSegmentTintColor = .fdPrimary; s.backgroundColor = .fdBg2
        s.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13, weight: .semibold)], for: .selected)
        s.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.systemFont(ofSize: 13)], for: .normal); return s
    }
    private func tag(_ text: String, bg: UIColor, fg: UIColor) -> UIView {
        let v = UIView(); v.backgroundColor = bg; v.layer.cornerRadius = 999
        let l = UILabel(); l.text = text; l.font = .systemFont(ofSize: 11); l.textColor = fg
        v.addSubview(l); l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }; return v
    }
    private func buildRecords(_ items: [(String, String, String)]) -> UIView {
        let ctr = UIView()
        let t = UILabel(); t.text = "近期记录"; t.font = .systemFont(ofSize: 14, weight: .semibold); t.textColor = .fdSubtext
        ctr.addSubview(t); t.snp.makeConstraints { $0.top.leading.equalToSuperview() }
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()
        ctr.addSubview(card); card.snp.makeConstraints { $0.top.equalTo(t.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview() }
        var prev: UIView?
        for (i, (time, val, src)) in items.enumerated() {
            let row = UIView(); let tl = UILabel(); tl.text = time; tl.font = .systemFont(ofSize: 13); tl.textColor = .fdText
            let vl = UILabel(); vl.text = val; vl.font = .systemFont(ofSize: 14, weight: .semibold); vl.textColor = .fdText
            let icon = UIImageView(image: UIImage(systemName: src == "bluetooth" ? "bluetooth" : "hand.point.up.fill")); icon.tintColor = .fdMuted
            row.addSubview(tl); row.addSubview(vl); row.addSubview(icon)
            tl.snp.makeConstraints { $0.top.equalToSuperview().offset(12); $0.leading.equalToSuperview() }
            vl.snp.makeConstraints { make in make.top.equalTo(tl.snp.bottom).offset(2); make.leading.equalToSuperview(); make.bottom.equalToSuperview().offset(-12) }
            icon.snp.makeConstraints { $0.trailing.centerY.equalToSuperview(); $0.size.equalTo(16) }
            if i < items.count - 1 { let d = UIView(); d.backgroundColor = .fdBorder; row.addSubview(d); d.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) } }
            card.addSubview(row); row.snp.makeConstraints { make in make.leading.trailing.equalToSuperview().inset(16); if let p = prev { make.top.equalTo(p.snp.bottom) } else { make.top.equalToSuperview().offset(4) } }
            prev = row
        }; prev?.snp.makeConstraints { $0.bottom.equalToSuperview().offset(-4) }; return ctr
    }
}
