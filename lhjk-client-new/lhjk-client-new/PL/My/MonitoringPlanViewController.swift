import UIKit
import SnapKit

/// 监测方案
/// 参考 funde-client: MonitoringPlanView.vue
final class MonitoringPlanViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private var mode = 0 // 0: current, 1: AI, 2: template

    private let items = [
        ("血压监测", "每日早晚各 1 次", "目标：130/80mmHg 以下"),
        ("空腹血糖", "每周一、三、五早晨", "目标：4.4-7.0mmol/L"),
        ("体重腰围", "每周日固定时间", "目标：每月下降 0.5-1kg"),
    ]

    override func setupUI() {
        title = "监测方案"
        view.backgroundColor = .fdBg

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 20, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        // Hero
        let hero = buildHero()
        stack.addArrangedSubview(hero)

        // Tab buttons
        let btnRow = UIStackView()
        btnRow.axis = .horizontal
        btnRow.spacing = 10
        btnRow.distribution = .fillEqually

        let aiBtn = buildTabBtn("AI 智能生成", tag: 1, isActive: mode == 1)
        let tplBtn = buildTabBtn("从模板库选择", tag: 2, isActive: mode == 2)
        btnRow.addArrangedSubview(aiBtn)
        btnRow.addArrangedSubview(tplBtn)
        stack.addArrangedSubview(btnRow)

        // Tip
        if mode != 0 {
            let tip = UIView()
            tip.backgroundColor = UIColor(hexString: "#F6FBF8")
            tip.layer.cornerRadius = 12
            let tipLbl = UILabel()
            tipLbl.text = mode == 1
                ? "已根据健康档案、近期指标和服务目标生成新版方案草稿。"
                : "已选择「高血压合并血糖异常」模板，可提交给健管师确认。"
            tipLbl.font = .systemFont(ofSize: 13)
            tipLbl.textColor = UIColor(hexString: "#1F9A6B")
            tipLbl.numberOfLines = 0
            tip.addSubview(tipLbl)
            tipLbl.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
            stack.addArrangedSubview(tip)
        }

        // Plan cards
        for item in items {
            stack.addArrangedSubview(buildPlanCard(item))
        }
    }

    private func buildHero() -> UIView {
        let v = UIView()
        v.backgroundColor = .fdPrimary
        v.layer.cornerRadius = 24

        let label = UILabel()
        label.text = "当前生效方案"
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.white.withAlphaComponent(0.85)

        let title = UILabel()
        title.text = "慢病逆转 12 周监测方案"
        title.font = .systemFont(ofSize: 20, weight: .bold)
        title.textColor = .white

        let desc = UILabel()
        desc.text = "第 5 周 / 共 12 周 · 健管师王顾问已确认"
        desc.font = .systemFont(ofSize: 13)
        desc.textColor = UIColor.white.withAlphaComponent(0.9)

        v.addSubview(label)
        v.addSubview(title)
        v.addSubview(desc)

        label.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(18)
        }
        title.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        desc.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(18)
            make.bottom.equalToSuperview().offset(-18)
        }
        return v
    }

    private func buildTabBtn(_ title: String, tag: Int, isActive: Bool) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        btn.setTitleColor(isActive ? .fdPrimary : .fdPrimary, for: .normal)
        btn.backgroundColor = isActive ? .fdPrimarySoft : .white
        btn.layer.cornerRadius = 12
        btn.layer.borderWidth = 1
        btn.layer.borderColor = isActive ? UIColor.fdPrimary.cgColor : UIColor(hexString: "#FFE0D2").cgColor
        btn.tag = tag
        btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        btn.snp.makeConstraints { $0.height.equalTo(42) }
        return btn
    }

    @objc private func tabTapped(_ sender: UIButton) {
        mode = sender.tag
        // Re-render
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        setupUI()
    }

    private func buildPlanCard(_ item: (String, String, String)) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03

        let name = UILabel()
        name.text = item.0
        name.font = .systemFont(ofSize: 16, weight: .bold)
        name.textColor = .fdText

        let freq = UILabel()
        freq.text = item.1
        freq.font = .systemFont(ofSize: 14)
        freq.textColor = .fdText2

        let target = UILabel()
        target.text = item.2
        target.font = .systemFont(ofSize: 13)
        target.textColor = .fdSubtext

        card.addSubview(name)
        card.addSubview(freq)
        card.addSubview(target)

        name.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(15)
        }
        freq.snp.makeConstraints { make in
            make.top.equalTo(name.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(15)
        }
        target.snp.makeConstraints { make in
            make.top.equalTo(freq.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().offset(-15)
        }

        return card
    }
}
