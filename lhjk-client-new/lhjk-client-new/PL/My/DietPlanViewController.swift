import UIKit
import SnapKit

/// 饮食方案
/// 参考 funde-client: DietPlanView.vue
final class DietPlanViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let generated = true

    private let macros = [
        ("碳水化合物", 50, UIColor(hexString: "#FF9F50")),
        ("蛋白质", 25, UIColor(hexString: "#52B96A")),
        ("脂肪", 25, UIColor(hexString: "#6B9FE4")),
    ]
    private let meals = [
        ("07:30", "燕麦牛奶 + 水煮蛋", 410, "早"),
        ("12:00", "杂粮饭 + 清蒸鱼 + 时蔬", 620, "午"),
        ("18:00", "番茄豆腐汤 + 鸡胸肉沙拉", 520, "晚"),
    ]

    override func setupUI() {
        title = "饮食方案"
        view.backgroundColor = .fdBg

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 20, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        // Summary
        stack.addArrangedSubview(buildSummary())

        // Macros
        stack.addArrangedSubview(buildMacrosCard())

        // Meals
        for meal in meals {
            stack.addArrangedSubview(buildMealCard(meal))
        }
    }

    private func buildSummary() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdPrimarySoft
        card.layer.cornerRadius = 24

        let label = UILabel()
        label.text = "推荐热量"
        label.font = .fdCaption
        label.textColor = .fdSubtext

        let value = UILabel()
        value.text = "1550 kcal / 日"
        value.font = .fdH2
        value.textColor = .fdText

        let btn = UIButton(type: .system)
        btn.setTitle("生成方案", for: .normal)
        btn.titleLabel?.font = .fdBodyBold
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .fdPrimary
        btn.layer.cornerRadius = 12
        btn.snp.makeConstraints { $0.width.equalTo(90) }

        card.addSubview(label)
        card.addSubview(value)
        card.addSubview(btn)

        label.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(18)
        }
        value.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(6)
            make.leading.bottom.equalToSuperview().inset(18)
        }
        btn.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-18)
            make.height.equalTo(38)
        }

        return card
    }

    private func buildMacrosCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03

        let title = UILabel()
        title.text = "营养占比"
        title.font = .fdBodyBold
        title.textColor = .fdText
        card.addSubview(title)
        title.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(15)
        }

        var prevLabel: UIView = title
        for (label, pct, color) in macros {
            let row = buildMacroRow(label: label, pct: pct, color: color)
            card.addSubview(row)
            row.snp.makeConstraints { make in
                make.top.equalTo(prevLabel.snp.bottom).offset(8)
                make.leading.trailing.equalToSuperview().inset(15)
            }
            prevLabel = row
            if label == macros.last?.0 {
                row.snp.makeConstraints { make in
                    make.bottom.equalToSuperview().offset(-15)
                }
            }
        }

        return card
    }

    private func buildMacroRow(label: String, pct: Int, color: UIColor) -> UIView {
        let row = UIView()

        let nameLbl = UILabel()
        nameLbl.text = label
        nameLbl.font = .fdBody
        nameLbl.textColor = .fdText2

        let barBg = UIView()
        barBg.backgroundColor = .fdBorder
        barBg.layer.cornerRadius = 4

        let barFill = UIView()
        barFill.backgroundColor = color
        barFill.layer.cornerRadius = 4
        barBg.addSubview(barFill)

        let pctLbl = UILabel()
        pctLbl.text = "\(pct)%"
        pctLbl.font = .fdBodyBold
        pctLbl.textColor = .fdText
        pctLbl.textAlignment = .right

        row.addSubview(nameLbl)
        row.addSubview(barBg)
        row.addSubview(pctLbl)

        nameLbl.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.equalTo(72)
        }
        barBg.snp.makeConstraints { make in
            make.leading.equalTo(nameLbl.snp.trailing).offset(10)
            make.trailing.equalTo(pctLbl.snp.leading).offset(-10)
            make.centerY.equalToSuperview()
            make.height.equalTo(8)
        }
        pctLbl.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.equalTo(36)
        }
        barFill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(CGFloat(pct) / 100.0)
        }
        row.snp.makeConstraints { make in make.height.equalTo(20) }

        return row
    }

    private func buildMealCard(_ meal: (String, String, Int, String)) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03

        let imgBg = UIView()
        imgBg.backgroundColor = UIColor(hexString: "#F6FBF8")
        imgBg.layer.cornerRadius = 14
        let imgLbl = UILabel()
        imgLbl.text = meal.3
        imgLbl.font = .fdBodyBold
        imgLbl.textColor = UIColor(hexString: "#1F9A6B")
        imgBg.addSubview(imgLbl)
        imgLbl.snp.makeConstraints { $0.center.equalToSuperview() }

        let timeLbl = UILabel()
        timeLbl.text = meal.0
        timeLbl.font = .fdCaption
        timeLbl.textColor = .fdSubtext

        let nameLbl = UILabel()
        nameLbl.text = meal.1
        nameLbl.font = .fdBodyBold
        nameLbl.textColor = .fdText

        let kcalLbl = UILabel()
        kcalLbl.text = "\(meal.2) kcal"
        kcalLbl.font = .fdCaptionSemibold
        kcalLbl.textColor = .fdPrimary

        card.addSubview(imgBg)
        card.addSubview(timeLbl)
        card.addSubview(nameLbl)
        card.addSubview(kcalLbl)

        imgBg.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
            make.size.equalTo(52)
        }
        timeLbl.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.leading.equalTo(imgBg.snp.trailing).offset(12)
        }
        nameLbl.snp.makeConstraints { make in
            make.top.equalTo(timeLbl.snp.bottom).offset(4)
            make.leading.equalTo(timeLbl)
            make.bottom.equalToSuperview().offset(-15)
        }
        kcalLbl.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-15)
            make.centerY.equalToSuperview()
        }

        return card
    }
}
