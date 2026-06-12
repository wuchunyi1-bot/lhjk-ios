import UIKit
import SnapKit

/// 饮食运动 — 综合页（简化版：热量环 + 营养 + 日常记录）
/// 参考 funde-client: ExerciseFoodView.vue
final class ExerciseFoodViewController: BaseViewController {

    override func setupUI() {
        title = "饮食运动"; view.backgroundColor = .fdBg
        let scroll = UIScrollView(); view.addSubview(scroll); scroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        let c = UIView(); scroll.addSubview(c); c.snp.makeConstraints { $0.edges.width.equalToSuperview() }
        let pad: CGFloat = 16

        // Calorie summary card
        let calCard = UIView(); calCard.backgroundColor = UIColor(hexString: "#FF7A50"); calCard.layer.cornerRadius = 24
        let calTitle = UILabel(); calTitle.text = "今日热量"; calTitle.font = .systemFont(ofSize: 13); calTitle.textColor = UIColor.white.withAlphaComponent(0.8)
        let calVal = UILabel(); calVal.text = "1,530"; calVal.font = .systemFont(ofSize: 42, weight: .bold); calVal.textColor = .white
        let calUnit = UILabel(); calUnit.text = "/ 2,130 kcal"; calUnit.font = .systemFont(ofSize: 15); calUnit.textColor = UIColor.white.withAlphaComponent(0.7)
        let remain = UILabel(); remain.text = "还可摄入 600 kcal"; remain.font = .systemFont(ofSize: 13); remain.textColor = UIColor.white.withAlphaComponent(0.85)
        calCard.addSubview(calTitle); calCard.addSubview(calVal); calCard.addSubview(calUnit); calCard.addSubview(remain)
        c.addSubview(calCard)
        calCard.snp.makeConstraints { $0.top.equalToSuperview().offset(12); $0.leading.trailing.equalToSuperview().inset(pad) }
        calTitle.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(20) }
        calVal.snp.makeConstraints { $0.top.equalTo(calTitle.snp.bottom).offset(4); $0.leading.equalToSuperview().inset(20) }
        calUnit.snp.makeConstraints { $0.lastBaseline.equalTo(calVal).offset(-6); $0.leading.equalTo(calVal.snp.trailing).offset(4) }
        remain.snp.makeConstraints { $0.top.equalTo(calVal.snp.bottom).offset(4); $0.leading.equalToSuperview().inset(20); $0.bottom.equalToSuperview().offset(-20) }

        // Nutrition card
        let nutCard = UIView(); nutCard.backgroundColor = .fdSurface; nutCard.layer.cornerRadius = 18; nutCard.addFundeShadow()
        let nutTitle = UILabel(); nutTitle.text = "营养摄入"; nutTitle.font = .systemFont(ofSize: 14, weight: .semibold); nutTitle.textColor = .fdText
        nutCard.addSubview(nutTitle); nutTitle.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }

        let nutrients: [(String, Int, Int, UIColor)] = [
            ("碳水化合物", 180, 306, UIColor(hexString: "#FF9F50")),
            ("脂肪", 90, 133, UIColor(hexString: "#52B96A")),
            ("蛋白质", 35, 41, UIColor(hexString: "#6B9FE4")),
        ]
        var prevNut: UIView = nutTitle
        for (label, cur, tgt, color) in nutrients {
            let row = UIView()
            let l = UILabel(); l.text = label; l.font = .systemFont(ofSize: 13); l.textColor = .fdSubtext; l.snp.makeConstraints { $0.width.equalTo(72) }
            let barBg = UIView(); barBg.backgroundColor = .fdBorder; barBg.layer.cornerRadius = 3
            let barFill = UIView(); barFill.backgroundColor = color; barFill.layer.cornerRadius = 3
            barBg.addSubview(barFill)
            let pct = UILabel(); pct.text = "\(cur) / \(tgt) g"; pct.font = .systemFont(ofSize: 12); pct.textColor = .fdMuted; pct.textAlignment = .right; pct.snp.makeConstraints { $0.width.equalTo(80) }
            row.addSubview(l); row.addSubview(barBg); row.addSubview(pct)
            barBg.snp.makeConstraints { $0.centerY.equalToSuperview(); $0.height.equalTo(6) }
            barFill.snp.makeConstraints { $0.leading.top.bottom.equalToSuperview(); $0.width.equalTo(barBg).multipliedBy(min(CGFloat(cur) / CGFloat(tgt), 1.0)) }
            nutCard.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                make.top.equalTo(prevNut.snp.bottom).offset(12)
                make.height.equalTo(20)
                if label == "蛋白质" { make.bottom.equalToSuperview().offset(-16) }
            }
            row.layoutIfNeeded()
            l.snp.makeConstraints { $0.leading.centerY.equalToSuperview() }
            pct.snp.makeConstraints { $0.trailing.centerY.equalToSuperview() }
            barBg.snp.makeConstraints { make in make.leading.equalTo(l.snp.trailing).offset(8); make.trailing.equalTo(pct.snp.leading).offset(-8); make.centerY.equalToSuperview(); make.height.equalTo(6) }
            prevNut = row
        }
        c.addSubview(nutCard)
        nutCard.snp.makeConstraints { $0.top.equalTo(calCard.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(pad) }

        // Exercise card
        let exCard = UIView(); exCard.backgroundColor = .fdSurface; exCard.layer.cornerRadius = 18; exCard.addFundeShadow()
        let exTitle = UILabel(); exTitle.text = "今日运动"; exTitle.font = .systemFont(ofSize: 14, weight: .semibold); exTitle.textColor = .fdText
        let stepsLbl = UILabel(); stepsLbl.text = "6,230 步"; stepsLbl.font = .systemFont(ofSize: 28, weight: .bold); stepsLbl.textColor = .fdText
        let stepsHint = UILabel(); stepsHint.text = "消耗约 280 kcal · 目标 8,000 步"; stepsHint.font = .systemFont(ofSize: 13); stepsHint.textColor = .fdSubtext
        exCard.addSubview(exTitle); exCard.addSubview(stepsLbl); exCard.addSubview(stepsHint)
        c.addSubview(exCard)
        exCard.snp.makeConstraints { $0.top.equalTo(nutCard.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(pad) }
        exTitle.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }
        stepsLbl.snp.makeConstraints { $0.top.equalTo(exTitle.snp.bottom).offset(8); $0.leading.equalToSuperview().inset(16) }
        stepsHint.snp.makeConstraints { $0.top.equalTo(stepsLbl.snp.bottom).offset(4); $0.leading.equalToSuperview().inset(16); $0.bottom.equalToSuperview().offset(-16) }

        // AI food button
        let aiBtn = UIButton(type: .system)
        aiBtn.setTitle("📸 AI 拍照识别食物", for: .normal)
        aiBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold); aiBtn.setTitleColor(.fdPrimary, for: .normal)
        aiBtn.backgroundColor = .fdPrimarySoft; aiBtn.layer.cornerRadius = 14
        c.addSubview(aiBtn); aiBtn.snp.makeConstraints { $0.top.equalTo(exCard.snp.bottom).offset(16); $0.leading.trailing.equalToSuperview().inset(pad); $0.height.equalTo(50); $0.bottom.equalToSuperview().offset(-20) }
    }
}
