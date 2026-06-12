import UIKit
import SnapKit

/// 首页 Hub — 参考 funde-client: HomeView.vue
final class HomeViewController: BaseViewController {

    // MARK: - Mock

    private let mock = (
        name: "李秀英", advisor: "王顾问", daysLeft: 45,
        riskScore: 62, riskLevel: "中风险",
        riskHint: "血压持续偏高，建议本周完成晨起测量 3 次",
        metrics: [
            ("血压", "138/88", "mmHg", "偏高", "warning"),
            ("血糖", "5.8", "mmol/L", "正常", "success"),
            ("体重", "68.5", "kg", "正常", "success"),
            ("心率", "76", "bpm", "正常", "success"),
        ],
        quickActions: [
            ("bubble.left.and.bubble.right", "咨询健管师", UIColor(hexString: "#FFF3EE"), UIColor.fdPrimary, "/messages"),
            ("calendar.badge.clock", "预约体检", UIColor(hexString: "#EAF3FF"), UIColor(hexString: "#3D6FB8"), "/appointments/exams"),
            ("heart", "录入体征", UIColor(hexString: "#E6F7EF"), UIColor(hexString: "#1F9A6B"), "/health/metrics"),
            ("gift", "查看权益", UIColor(hexString: "#FFF3DC"), UIColor(hexString: "#B47300"), "/me/membership"),
        ],
        team: [
            ("doctor", "张", "张建国", "内科主任医师", "高血压·心脑血管", "在线", "success"),
            ("nutrition", "陈", "陈梅", "国家注册营养师", "慢病饮食干预", "今日值班", "primary"),
            ("manager", "王", "王顾问", "健康管理专家", "随访·行为干预", "您的专属", "warning"),
        ],
        tasks: [
            ("晨起血压测量", "建议 6:30–8:00 静坐 5 分钟后测量", 5, false, false),
            ("目标步数 8000 步", "今日已走 8,432 步 · 棒极了", 10, true, false),
            ("完善健康档案", "完整度 72% · 缺心电图、家族史", 20, false, true),
        ],
        articles: [
            ("高血压", "warning", "为什么医生说「早晨的第一杯水」不能省?", "张建国 主任医师", "2.3k 阅读"),
            ("膳食干预", "success", "低钠≠无味——3 个让餐桌更香的代盐技巧", "陈梅 注册营养师", "1.8k 阅读"),
            ("运动", "primary", "每天 30 分钟快走，血压能下降多少?", "王顾问 健康管理师", "3.1k 阅读"),
            ("睡眠", "info", "睡眠不足 1 小时，血压可能上升 10 个百分点", "张建国 主任医师", "2.8k 阅读"),
            ("体重管理", "warning", "减重 5%，血糖能有多大改变?", "陈梅 注册营养师", "1.5k 阅读"),
        ]
    )

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        view.addSubview(scrollView); scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }
        let pad: CGFloat = 16

        // 1. Hero
        let hero = buildHero()
        contentView.addSubview(hero); hero.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }

        // 2. Quick Actions (overlap hero -6pt)
        let quickActions = buildQuickActions()
        contentView.addSubview(quickActions); quickActions.snp.makeConstraints { $0.top.equalTo(hero.snp.bottom).offset(-6); $0.leading.trailing.equalToSuperview().inset(pad) }

        // 3. Team
        let team = buildTeamSection(); contentView.addSubview(team)
        team.snp.makeConstraints { $0.top.equalTo(quickActions.snp.bottom).offset(20); $0.leading.trailing.equalToSuperview().inset(pad) }

        // 4. Tasks
        let tasks = buildTasksSection(); contentView.addSubview(tasks)
        tasks.snp.makeConstraints { $0.top.equalTo(team.snp.bottom).offset(20); $0.leading.trailing.equalToSuperview().inset(pad) }

        // 5. Service banner
        let banner = buildServiceBanner(); contentView.addSubview(banner)
        banner.snp.makeConstraints { $0.top.equalTo(tasks.snp.bottom).offset(20); $0.leading.trailing.equalToSuperview().inset(pad) }

        // 6. Articles
        let articles = buildArticlesSection(); contentView.addSubview(articles)
        articles.snp.makeConstraints { $0.top.equalTo(banner.snp.bottom).offset(20); $0.leading.trailing.equalToSuperview().inset(pad); $0.bottom.equalToSuperview().offset(-20) }
    }

    // MARK: - Hero

    private func buildHero() -> UIView {
        let hero = UIView(); hero.backgroundColor = .fdPrimary
        hero.clipsToBounds = true

        // Decorative blobs
        let blob1 = UIView(); blob1.backgroundColor = UIColor.white.withAlphaComponent(0.12); blob1.layer.cornerRadius = 90
        let blob2 = UIView(); blob2.backgroundColor = UIColor.white.withAlphaComponent(0.08); blob2.layer.cornerRadius = 40
        hero.addSubview(blob1); hero.addSubview(blob2)
        blob1.snp.makeConstraints { $0.top.equalToSuperview().offset(-40); $0.trailing.equalToSuperview().offset(30); $0.size.equalTo(180) }
        blob2.snp.makeConstraints { $0.top.equalToSuperview().offset(60); $0.trailing.equalToSuperview().offset(-40); $0.size.equalTo(80) }

        // Topbar
        let nameLbl = UILabel(); nameLbl.text = "你好，\(mock.name)"; nameLbl.font = .systemFont(ofSize: 22, weight: .semibold); nameLbl.textColor = .white
        let subLbl = UILabel()
        let subAttr = NSMutableAttributedString(string: "健管师 · \(mock.advisor)  |  服务剩 ", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.white.withAlphaComponent(0.85)])
        subAttr.append(NSAttributedString(string: "\(mock.daysLeft)", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold), .foregroundColor: UIColor.white]))
        subAttr.append(NSAttributedString(string: " 天", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.white.withAlphaComponent(0.85)]))
        subLbl.attributedText = subAttr

        let brandPill = UIView(); brandPill.backgroundColor = UIColor.white.withAlphaComponent(0.2); brandPill.layer.cornerRadius = 16; brandPill.layer.borderWidth = 1; brandPill.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        let brandIcon = UIView(); brandIcon.backgroundColor = .white; brandIcon.layer.cornerRadius = 8
        let brandLbl = UILabel(); brandLbl.text = "富德健康"; brandLbl.font = .systemFont(ofSize: 15, weight: .bold); brandLbl.textColor = .white
        brandPill.addSubview(brandIcon); brandPill.addSubview(brandLbl)
        brandIcon.snp.makeConstraints { $0.leading.equalToSuperview().offset(12); $0.centerY.equalToSuperview(); $0.size.equalTo(16) }
        brandLbl.snp.makeConstraints { $0.leading.equalTo(brandIcon.snp.trailing).offset(6); $0.trailing.equalToSuperview().offset(-12); $0.centerY.equalToSuperview() }

        hero.addSubview(nameLbl); hero.addSubview(subLbl); hero.addSubview(brandPill)
        nameLbl.snp.makeConstraints { $0.top.equalToSuperview().offset(52); $0.leading.equalToSuperview().offset(18) }
        subLbl.snp.makeConstraints { $0.top.equalTo(nameLbl.snp.bottom).offset(4); $0.leading.equalToSuperview().offset(18) }
        brandPill.snp.makeConstraints { $0.centerY.equalTo(nameLbl); $0.trailing.equalToSuperview().offset(-18); $0.height.equalTo(32) }

        // Score ring
        let ring = UIView(); ring.backgroundColor = UIColor.white.withAlphaComponent(0.08); ring.layer.cornerRadius = 43; ring.layer.borderWidth = 2; ring.layer.borderColor = UIColor.white.withAlphaComponent(0.45).cgColor
        let scoreNum = UILabel(); scoreNum.text = "\(mock.riskScore)"; scoreNum.font = .systemFont(ofSize: 38, weight: .bold); scoreNum.textColor = .white
        let scoreLabel = UILabel(); scoreLabel.text = "SCORE"; scoreLabel.font = .systemFont(ofSize: 9); scoreLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        ring.addSubview(scoreNum); ring.addSubview(scoreLabel)
        scoreNum.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.centerY.equalToSuperview().offset(-6) }
        scoreLabel.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.top.equalTo(scoreNum.snp.bottom).offset(2) }

        let riskBadge = UIView(); riskBadge.backgroundColor = UIColor(hexString: "#FFF5E0"); riskBadge.layer.cornerRadius = 999
        let dot = UIView(); dot.backgroundColor = UIColor(hexString: "#B47300"); dot.layer.cornerRadius = 3
        let riskLbl = UILabel(); riskLbl.text = mock.riskLevel; riskLbl.font = .systemFont(ofSize: 11, weight: .semibold); riskLbl.textColor = UIColor(hexString: "#7A3F00")
        riskBadge.addSubview(dot); riskBadge.addSubview(riskLbl)
        dot.snp.makeConstraints { $0.leading.equalToSuperview().offset(8); $0.centerY.equalToSuperview(); $0.size.equalTo(6) }
        riskLbl.snp.makeConstraints { $0.leading.equalTo(dot.snp.trailing).offset(5); $0.trailing.equalToSuperview().offset(-8); $0.top.bottom.equalToSuperview().inset(3) }

        let hintLbl = UILabel(); hintLbl.text = mock.riskHint; hintLbl.font = .systemFont(ofSize: 14, weight: .medium); hintLbl.textColor = .white; hintLbl.numberOfLines = 0

        hero.addSubview(ring); hero.addSubview(riskBadge); hero.addSubview(hintLbl)
        ring.snp.makeConstraints { $0.top.equalTo(subLbl.snp.bottom).offset(16); $0.leading.equalToSuperview().offset(18); $0.size.equalTo(86) }
        riskBadge.snp.makeConstraints { $0.top.equalTo(ring).offset(12); $0.leading.equalTo(ring.snp.trailing).offset(14) }
        hintLbl.snp.makeConstraints { $0.top.equalTo(riskBadge.snp.bottom).offset(8); $0.leading.equalTo(ring.snp.trailing).offset(14); $0.trailing.equalToSuperview().offset(-16) }

        // Metric chips
        let chipsRow = UIStackView(); chipsRow.distribution = .fillEqually; chipsRow.spacing = 8
        for m in mock.metrics {
            let chip = UIView(); chip.backgroundColor = UIColor.white.withAlphaComponent(m.4 == "warning" ? 0.22 : 0.18); chip.layer.cornerRadius = 14; chip.layer.borderWidth = 1; chip.layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor
            let topRow = UIStackView(); topRow.axis = .horizontal; topRow.distribution = .equalSpacing
            let l = UILabel(); l.text = m.0; l.font = .systemFont(ofSize: 11); l.textColor = UIColor.white.withAlphaComponent(0.78)
            let tag = UIView(); tag.backgroundColor = m.4 == "warning" ? UIColor(hexString: "#FFF5E0") : UIColor.white.withAlphaComponent(0.3); tag.layer.cornerRadius = 4
            let t = UILabel(); t.text = m.3; t.font = .systemFont(ofSize: 9, weight: .semibold); t.textColor = m.4 == "warning" ? UIColor(hexString: "#7A3F00") : .white; t.textAlignment = .center
            tag.addSubview(t); t.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 1, left: 5, bottom: 1, right: 5)) }
            topRow.addArrangedSubview(l); topRow.addArrangedSubview(tag)

            let valRow = UIStackView(); valRow.axis = .horizontal; valRow.alignment = .lastBaseline; valRow.spacing = 2
            let v = UILabel(); v.text = m.1; v.font = .systemFont(ofSize: 18, weight: .semibold); v.textColor = .white
            let u = UILabel(); u.text = m.2; u.font = .systemFont(ofSize: 9); u.textColor = UIColor.white.withAlphaComponent(0.7)
            valRow.addArrangedSubview(v); valRow.addArrangedSubview(u)

            chip.addSubview(topRow); chip.addSubview(valRow)
            topRow.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(8) }
            valRow.snp.makeConstraints { $0.top.equalTo(topRow.snp.bottom).offset(5); $0.leading.equalToSuperview().inset(8); $0.bottom.equalToSuperview().offset(-8) }
            chipsRow.addArrangedSubview(chip)
        }
        hero.addSubview(chipsRow)
        chipsRow.snp.makeConstraints { $0.top.equalTo(ring.snp.bottom).offset(16); $0.leading.trailing.equalToSuperview().inset(16); $0.bottom.equalToSuperview().offset(-20) }

        return hero
    }

    // MARK: - Quick Actions

    private func buildQuickActions() -> UIView {
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()
        let row = UIStackView(); row.distribution = .fillEqually
        card.addSubview(row); row.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 18, left: 8, bottom: 18, right: 8)) }

        for act in mock.quickActions {
            let item = UIView()
            let iconBg = UIView(); iconBg.backgroundColor = act.2; iconBg.layer.cornerRadius = 16
            let icon = UIImageView(image: UIImage(systemName: act.0)); icon.tintColor = act.3; icon.contentMode = .scaleAspectFit
            iconBg.addSubview(icon); icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(24) }
            let lbl = UILabel(); lbl.text = act.1; lbl.font = .systemFont(ofSize: 12, weight: .medium); lbl.textColor = .fdText2; lbl.textAlignment = .center
            item.addSubview(iconBg); item.addSubview(lbl)
            iconBg.snp.makeConstraints { $0.top.centerX.equalToSuperview(); $0.size.equalTo(48) }
            lbl.snp.makeConstraints { $0.top.equalTo(iconBg.snp.bottom).offset(7); $0.centerX.equalToSuperview(); $0.bottom.equalToSuperview() }

            let tap = UITapGestureRecognizer(target: self, action: #selector(quickActionTapped(_:)))
            item.addGestureRecognizer(tap); item.accessibilityIdentifier = act.4
            row.addArrangedSubview(item)
        }
        return card
    }

    @objc private func quickActionTapped(_ gesture: UITapGestureRecognizer) {
        guard let route = gesture.view?.accessibilityIdentifier else { return }
        Router.shared.push(route)
    }

    // MARK: - Team

    private let roleColors: [String: (bg: UIColor, fg: UIColor)] = [
        "doctor":    (UIColor(hexString: "#EAF3FF"), UIColor(hexString: "#3D6FB8")),
        "nutrition": (UIColor(hexString: "#E6F7EF"), UIColor(hexString: "#1F9A6B")),
        "manager":   (UIColor(hexString: "#FFEFE6"), UIColor(hexString: "#D6602B")),
    ]

    private func buildTeamSection() -> UIView {
        let section = UIView()
        let titleRow = SectionTitleView(title: "我的富德健康管家团队", more: "服务剩余 \(mock.daysLeft) 天 ›")
        section.addSubview(titleRow); titleRow.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }

        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()
        section.addSubview(card); card.snp.makeConstraints { $0.top.equalTo(titleRow.snp.bottom).offset(12); $0.leading.trailing.bottom.equalToSuperview() }

        var prev: UIView?
        for (i, member) in mock.team.enumerated() {
            let row = buildTeamRow(member, isLast: i == mock.team.count - 1)
            card.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(14)
                if let p = prev { make.top.equalTo(p.snp.bottom) } else { make.top.equalToSuperview().offset(4) }
            }
            prev = row
        }
        prev?.snp.makeConstraints { $0.bottom.equalToSuperview().offset(-4) }

        return section
    }

    private func buildTeamRow(_ m: (String, String, String, String, String, String, String), isLast: Bool) -> UIView {
        let row = UIView()
        let avatar = UIView(); avatar.backgroundColor = roleColors[m.0]?.bg ?? .fdBg2; avatar.layer.cornerRadius = 23
        let avLbl = UILabel(); avLbl.text = m.1; avLbl.font = .systemFont(ofSize: 17, weight: .semibold); avLbl.textColor = roleColors[m.0]?.fg ?? .fdSubtext
        avatar.addSubview(avLbl); avLbl.snp.makeConstraints { $0.center.equalToSuperview() }

        let onlineDot = UIView(); onlineDot.backgroundColor = .fdSuccess; onlineDot.layer.cornerRadius = 5.5; onlineDot.layer.borderWidth = 2; onlineDot.layer.borderColor = UIColor.white.cgColor

        let nameLbl = UILabel(); nameLbl.text = m.2; nameLbl.font = .systemFont(ofSize: 15, weight: .semibold); nameLbl.textColor = .fdText
        let titleLbl = UILabel(); titleLbl.text = m.3; titleLbl.font = .systemFont(ofSize: 11); titleLbl.textColor = .fdSubtext

        let tag = UILabel(); tag.text = m.4; tag.font = .systemFont(ofSize: 11); tag.textColor = .fdText2; tag.backgroundColor = .fdBg2; tag.layer.cornerRadius = 6; tag.clipsToBounds = true
        tag.textAlignment = .center

        let statusColors: [String: (bg: UIColor, fg: UIColor)] = ["success": (.fdSuccessSoft, .fdSuccess), "primary": (.fdPrimarySoft, .fdPrimary), "warning": (.fdWarningSoft, UIColor(hexString: "#B47300"))]
        let sc = statusColors[m.5] ?? (.fdSuccessSoft, .fdSuccess)
        let status = UIView(); status.backgroundColor = sc.bg; status.layer.cornerRadius = 6
        let statusLbl = UILabel(); statusLbl.text = "● \(m.5)"; statusLbl.font = .systemFont(ofSize: 11, weight: .semibold); statusLbl.textColor = sc.fg
        status.addSubview(statusLbl); statusLbl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 7, bottom: 2, right: 7)) }

        let msgBtn = UIButton(type: .system); msgBtn.setTitle("发消息", for: .normal); msgBtn.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        msgBtn.setTitleColor(.fdPrimary, for: .normal); msgBtn.backgroundColor = .fdPrimarySoft; msgBtn.layer.cornerRadius = 999
        msgBtn.contentEdgeInsets = UIEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)

        row.addSubview(avatar); row.addSubview(onlineDot)
        row.addSubview(nameLbl); row.addSubview(titleLbl); row.addSubview(tag); row.addSubview(status); row.addSubview(msgBtn)

        avatar.snp.makeConstraints { $0.top.equalToSuperview().offset(14); $0.leading.equalToSuperview(); $0.size.equalTo(46) }
        onlineDot.snp.makeConstraints { $0.bottom.equalTo(avatar).offset(1); $0.trailing.equalTo(avatar).offset(1); $0.size.equalTo(11) }
        nameLbl.snp.makeConstraints { $0.top.equalTo(avatar); $0.leading.equalTo(avatar.snp.trailing).offset(12) }
        titleLbl.snp.makeConstraints { $0.centerY.equalTo(nameLbl); $0.leading.equalTo(nameLbl.snp.trailing).offset(6) }
        tag.snp.makeConstraints { $0.top.equalTo(nameLbl.snp.bottom).offset(4); $0.leading.equalTo(nameLbl) }
        status.snp.makeConstraints { $0.centerY.equalTo(tag); $0.leading.equalTo(tag.snp.trailing).offset(6) }
        msgBtn.snp.makeConstraints { $0.centerY.equalToSuperview(); $0.trailing.equalToSuperview() }

        if !isLast {
            let divider = UIView(); divider.backgroundColor = .fdBorder; row.addSubview(divider)
            divider.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
            row.snp.makeConstraints { $0.bottom.equalTo(divider.snp.top) }
        } else {
            row.snp.makeConstraints { $0.height.equalTo(74) }
        }
        return row
    }

    // MARK: - Tasks

    private func buildTasksSection() -> UIView {
        let section = UIView()
        let doneCount = mock.tasks.filter(\.3).count
        let titleRow = SectionTitleView(title: "今日健康任务", more: "已完成 \(doneCount) / 3 · +10 分 ›")
        section.addSubview(titleRow); titleRow.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }

        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()
        section.addSubview(card); card.snp.makeConstraints { $0.top.equalTo(titleRow.snp.bottom).offset(12); $0.leading.trailing.bottom.equalToSuperview() }

        var prev: UIView?
        for (i, task) in mock.tasks.enumerated() {
            let row = buildTaskRow(task, isLast: i == mock.tasks.count - 1)
            card.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                if let p = prev { make.top.equalTo(p.snp.bottom) } else { make.top.equalToSuperview().offset(4) }
            }
            prev = row
        }
        prev?.snp.makeConstraints { $0.bottom.equalToSuperview().offset(-4) }
        return section
    }

    private func buildTaskRow(_ t: (String, String, Int, Bool, Bool), isLast: Bool) -> UIView {
        let row = UIView()
        let check = UIView(); check.layer.cornerRadius = 13; check.layer.borderWidth = 1.6
        if t.3 {
            check.backgroundColor = .fdSuccess; check.layer.borderColor = UIColor.fdSuccess.cgColor
            let chk = UIImageView(image: UIImage(systemName: "checkmark")); chk.tintColor = .white
            check.addSubview(chk); chk.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(14) }
        } else {
            check.backgroundColor = .clear; check.layer.borderColor = UIColor.fdBorderStrong.cgColor
        }

        let titleLbl = UILabel(); titleLbl.text = t.0; titleLbl.font = .systemFont(ofSize: 14, weight: .semibold); titleLbl.textColor = t.3 ? .fdMuted : .fdText
        if t.3 { titleLbl.attributedText = NSAttributedString(string: t.0, attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue, .foregroundColor: UIColor.fdMuted]) }

        let descLbl = UILabel(); descLbl.text = t.1; descLbl.font = .systemFont(ofSize: 11); descLbl.textColor = .fdSubtext

        let ptsBg = UIView(); ptsBg.layer.cornerRadius = 999
        let ptsLbl = UILabel(); ptsLbl.text = "+\(t.2)"; ptsLbl.font = .systemFont(ofSize: 12, weight: .bold)
        if t.3 { ptsBg.backgroundColor = .fdSuccessSoft; ptsLbl.textColor = .fdSuccess }
        else if t.4 { ptsBg.backgroundColor = .fdPrimary; ptsLbl.textColor = .white }
        else { ptsBg.backgroundColor = .fdPrimarySoft; ptsLbl.textColor = .fdPrimary }
        ptsBg.addSubview(ptsLbl); ptsLbl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)) }

        row.addSubview(check); row.addSubview(titleLbl); row.addSubview(descLbl); row.addSubview(ptsBg)
        check.snp.makeConstraints { $0.top.equalToSuperview().offset(14); $0.leading.equalToSuperview(); $0.size.equalTo(26) }
        titleLbl.snp.makeConstraints { $0.top.equalTo(check); $0.leading.equalTo(check.snp.trailing).offset(12) }
        descLbl.snp.makeConstraints { $0.top.equalTo(titleLbl.snp.bottom).offset(2); $0.leading.equalTo(titleLbl); $0.bottom.equalToSuperview().offset(-14) }
        ptsBg.snp.makeConstraints { $0.centerY.equalToSuperview(); $0.trailing.equalToSuperview() }

        if !isLast {
            let div = UIView(); div.backgroundColor = .fdBorder; row.addSubview(div)
            div.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
        }
        return row
    }

    // MARK: - Service Banner

    private func buildServiceBanner() -> UIView {
        let banner = UIView(); banner.backgroundColor = UIColor(hexString: "#FFE7D9"); banner.layer.cornerRadius = 18; banner.clipsToBounds = true

        let blob = UIView(); blob.backgroundColor = UIColor.white.withAlphaComponent(0.45); blob.layer.cornerRadius = 65
        banner.addSubview(blob); blob.snp.makeConstraints { $0.top.trailing.equalToSuperview().inset(-30); $0.size.equalTo(130) }

        let tag = UILabel(); tag.text = "进行中"; tag.font = .systemFont(ofSize: 10, weight: .semibold); tag.textColor = .white; tag.backgroundColor = .fdPrimary; tag.layer.cornerRadius = 4; tag.clipsToBounds = true; tag.textAlignment = .center
        let name = UILabel(); name.text = "德好 · 慢病逆转管理"; name.font = .systemFont(ofSize: 17, weight: .bold); name.textColor = .fdText
        let desc = UILabel(); desc.text = "12 周完整方案 · 已完成第 5 周 / 12"; desc.font = .systemFont(ofSize: 12); desc.textColor = .fdText2

        let progressBg = UIView(); progressBg.backgroundColor = UIColor.white.withAlphaComponent(0.6); progressBg.layer.cornerRadius = 4
        let progressFill = UIView(); progressFill.backgroundColor = .fdPrimary; progressFill.layer.cornerRadius = 4
        progressBg.addSubview(progressFill)
        let daysLbl = UILabel()
        let daysAttr = NSMutableAttributedString(string: "剩 ", attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.fdText2])
        daysAttr.append(NSAttributedString(string: "\(mock.daysLeft)", attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .bold), .foregroundColor: UIColor.fdPrimary]))
        daysAttr.append(NSAttributedString(string: " 天", attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.fdText2]))
        daysLbl.attributedText = daysAttr

        banner.addSubview(tag); banner.addSubview(name); banner.addSubview(desc); banner.addSubview(progressBg); banner.addSubview(daysLbl)
        tag.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16); $0.width.equalTo(46); $0.height.equalTo(20) }
        name.snp.makeConstraints { $0.top.equalTo(tag.snp.bottom).offset(8); $0.leading.equalToSuperview().inset(16); $0.trailing.equalToSuperview().offset(-16) }
        desc.snp.makeConstraints { $0.top.equalTo(name.snp.bottom).offset(4); $0.leading.equalToSuperview().inset(16) }
        progressBg.snp.makeConstraints { $0.top.equalTo(desc.snp.bottom).offset(12); $0.leading.equalToSuperview().inset(16); $0.height.equalTo(8) }
        progressFill.snp.makeConstraints { $0.leading.top.bottom.equalToSuperview(); $0.width.equalTo(progressBg).multipliedBy(5.0/12.0) }
        daysLbl.snp.makeConstraints { $0.centerY.equalTo(progressBg); $0.leading.equalTo(progressBg.snp.trailing).offset(12); $0.trailing.equalToSuperview().offset(-16); $0.bottom.equalToSuperview().offset(-16) }

        banner.isUserInteractionEnabled = true
        banner.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToService)))

        return banner
    }

    @objc private func goToService() { Router.shared.push("/services") }

    // MARK: - Articles

    private func buildArticlesSection() -> UIView {
        let section = UIView()
        let titleRow = SectionTitleView(title: "健康陪伴", more: "更多 ›")
        section.addSubview(titleRow); titleRow.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }

        var prev: UIView = titleRow
        for (i, a) in mock.articles.enumerated() {
            let row = buildArticleRow(a, isLast: i == mock.articles.count - 1)
            section.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(prev.snp.bottom)
            }
            prev = row
        }
        prev.snp.makeConstraints { $0.bottom.equalToSuperview() }
        return section
    }

    private func buildArticleRow(_ a: (String, String, String, String, String), isLast: Bool) -> UIView {
        let row = UIView()
        let img = UIView(); img.backgroundColor = .fdBg2; img.layer.borderWidth = 1; img.layer.borderColor = UIColor.fdBorderStrong.cgColor; img.layer.cornerRadius = 12
        let imgLbl = UILabel(); imgLbl.text = "文章\n封面"; imgLbl.font = .systemFont(ofSize: 11); imgLbl.textColor = .fdMuted; imgLbl.numberOfLines = 0; imgLbl.textAlignment = .center
        img.addSubview(imgLbl); imgLbl.snp.makeConstraints { $0.center.equalToSuperview() }

        let tagColors: [String: (bg: UIColor, fg: UIColor)] = [
            "warning": (.fdWarningSoft, UIColor(hexString: "#B47300")),
            "success": (.fdSuccessSoft, .fdSuccess),
            "primary": (.fdPrimarySoft, .fdPrimary),
            "info": (.fdInfoSoft, .fdInfo),
        ]
        let tc = tagColors[a.1] ?? (.fdBg2, .fdSubtext)
        let tag = UILabel(); tag.text = a.0; tag.font = .systemFont(ofSize: 10, weight: .semibold); tag.textColor = tc.fg; tag.backgroundColor = tc.bg; tag.layer.cornerRadius = 999; tag.clipsToBounds = true; tag.textAlignment = .center

        let titleLbl = UILabel(); titleLbl.text = a.2; titleLbl.font = .systemFont(ofSize: 14, weight: .medium); titleLbl.textColor = .fdText; titleLbl.numberOfLines = 2
        let metaLbl = UILabel(); metaLbl.text = "\(a.3) · \(a.4)"; metaLbl.font = .systemFont(ofSize: 11); metaLbl.textColor = .fdMuted

        row.addSubview(img); row.addSubview(tag); row.addSubview(titleLbl); row.addSubview(metaLbl)
        img.snp.makeConstraints { $0.top.equalToSuperview().offset(12); $0.leading.equalToSuperview().inset(16); $0.size.equalTo(84) }
        tag.snp.makeConstraints { $0.top.equalTo(img); $0.leading.equalTo(img.snp.trailing).offset(12) }
        titleLbl.snp.makeConstraints { $0.top.equalTo(tag.snp.bottom).offset(6); $0.leading.equalTo(tag); $0.trailing.equalToSuperview().offset(-16) }
        metaLbl.snp.makeConstraints { $0.top.equalTo(titleLbl.snp.bottom).offset(6); $0.leading.equalTo(tag); $0.bottom.equalToSuperview().offset(-12) }

        if !isLast {
            let div = UIView(); div.backgroundColor = .fdBorder; row.addSubview(div)
            div.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview().inset(16); $0.height.equalTo(1) }
        }
        return row
    }
}
