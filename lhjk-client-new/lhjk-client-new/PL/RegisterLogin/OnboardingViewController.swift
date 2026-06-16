import UIKit
import SnapKit

/// 新用户引导 — 4 步健康档案初始建立
/// 参考 funde-client: OnboardingView.vue
///
/// Step 1: 基本信息（姓名/性别/出生年份）
/// Step 2: 健康史（既往病史多选 chip）
/// Step 3: 生活习惯（吸烟/运动频率单选 chip）
/// Step 4: 认识专属团队（卡片淡入动画）
final class OnboardingViewController: BaseViewController {

    // MARK: - Constants

    private let totalSteps = 4

    // MARK: - Team Mock Data

    private struct TeamMember {
        let avatar: String; let name: String; let title: String; let specialty: String
    }

    private let team: [TeamMember] = [
        TeamMember(avatar: "张", name: "张医生", title: "主治医师", specialty: "心内科·高血压管理"),
        TeamMember(avatar: "陈", name: "陈营养师", title: "国家注册营养师", specialty: "慢病饮食·体重管理"),
        TeamMember(avatar: "王", name: "王顾问", title: "高级健管师", specialty: "慢病逆转·日常跟进"),
    ]

    // MARK: - State

    private var currentStep = 1

    // Step 1 data
    private var nameText = ""
    private var selectedGender = ""
    private var birthYearText = ""

    // MARK: - UI — Top

    private lazy var progressFill: UIView = {
        let v = UIView()
        v.backgroundColor = .fdPrimary
        v.layer.cornerRadius = 1
        return v
    }()

    private let progressBar = UIView()

    private let stepLabel = UILabel()
    private let titleLabel = UILabel()
    private let descLabel = UILabel()

    // MARK: - UI — Body containers

    private let bodyScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.bounces = true
        return sv
    }()

    private let bodyContent = UIView()

    // Step 1
    private let step1View = UIView()

    private lazy var nameField: LoginFieldView = {
        let f = LoginFieldView(title: "您的姓名", placeholder: "请输入真实姓名", sfSymbol: "")
        f.textField.addTarget(self, action: #selector(step1Changed), for: .editingChanged)
        return f
    }()

    private let genderChipGroup = UIView()
    private var genderChips: [OptionChipView] = []
    private var genderGroup: OptionChipGroup?

    private lazy var birthYearField: LoginFieldView = {
        let f = LoginFieldView(title: "出生年份", placeholder: "例如：1980", sfSymbol: "")
        f.textField.keyboardType = .numberPad
        f.textField.addTarget(self, action: #selector(step1Changed), for: .editingChanged)
        return f
    }()

    // Step 2
    private let step2View = UIView()
    private let historyChipContainer = UIView()
    private var historyChips: [OptionChipView] = []
    private var historyGroup: OptionChipGroup?

    // Step 3
    private let step3View = UIView()
    private let smokingChipContainer = UIView()
    private var smokingChips: [OptionChipView] = []
    private var smokingGroup: OptionChipGroup?

    private let exerciseChipContainer = UIView()
    private var exerciseChips: [OptionChipView] = []
    private var exerciseGroup: OptionChipGroup?

    // Step 4
    private let step4View = UIView()
    private var teamCardViews: [UIView] = []

    // MARK: - UI — Bottom

    private let footerBar = UIView()

    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("返回", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        b.setTitleColor(.fdSubtext, for: .normal)
        b.backgroundColor = .fdSurface
        b.layer.cornerRadius = 18
        b.layer.borderWidth = 1.5
        b.layer.borderColor = UIColor.fdBorder.cgColor
        b.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        return b
    }()

    private lazy var nextButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("下一步", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .fdPrimary
        b.layer.cornerRadius = 18
        b.layer.shadowColor = UIColor.fdPrimary.cgColor
        b.layer.shadowOffset = CGSize(width: 0, height: 6)
        b.layer.shadowRadius = 18
        b.layer.shadowOpacity = 0.32
        b.addTarget(self, action: #selector(goNext), for: .touchUpInside)
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSteps()
        updateStepUI(animated: false)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg

        // Progress bar
        progressBar.backgroundColor = .fdBorder
        view.addSubview(progressBar)
        progressBar.addSubview(progressFill)
        progressBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(4)
        }
        progressFill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.25)
        }

        // Header (step label + title + desc) — fixed at top
        stepLabel.font = .systemFont(ofSize: 12)
        stepLabel.textColor = .fdMuted
        view.addSubview(stepLabel)
        stepLabel.snp.makeConstraints { make in
            make.top.equalTo(progressBar.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .fdText
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(stepLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = .fdSubtext
        view.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        // Footer — fixed at bottom
        footerBar.backgroundColor = .fdBg
        view.addSubview(footerBar)
        footerBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(68)
        }
        footerBar.addSubview(backButton)
        footerBar.addSubview(nextButton)

        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.centerY.equalToSuperview()
            make.width.equalTo(88)
            make.height.equalTo(52)
        }
        nextButton.snp.makeConstraints { make in
            make.leading.equalTo(backButton.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-24)
            make.centerY.equalToSuperview()
            make.height.equalTo(52)
        }

        // Body ScrollView — between header and footer, content scrollable
        view.addSubview(bodyScrollView)
        bodyScrollView.addSubview(bodyContent)
        bodyScrollView.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(footerBar.snp.top)
        }
        bodyContent.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }

        // Step containers in body content
        [step1View, step2View, step3View, step4View].forEach {
            bodyContent.addSubview($0)
            $0.snp.makeConstraints { m in
                m.top.leading.trailing.equalToSuperview()
                m.bottom.equalToSuperview().priority(.low)
            }
            $0.isHidden = true
        }
    }

    // MARK: - Steps Setup

    private func setupSteps() {
        setupStep1()
        setupStep2()
        setupStep3()
        setupStep4()
    }

    private func setupStep1() {
        // Gender chips
        let male = OptionChipView(label: "男")
        let female = OptionChipView(label: "女")
        genderChips = [male, female]
        genderGroup = OptionChipGroup(chips: genderChips, allowsMultipleSelection: false)

        let genderLabel = UILabel()
        genderLabel.text = "性别"
        genderLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        genderLabel.textColor = .fdSubtext

        let chipRow = UIStackView()
        chipRow.spacing = 10
        chipRow.distribution = .fillEqually
        genderChips.forEach { chipRow.addArrangedSubview($0) }

        let genderStack = UIStackView(arrangedSubviews: [genderLabel, chipRow])
        genderStack.axis = .vertical
        genderStack.spacing = 10

        let step1Stack = UIStackView(arrangedSubviews: [nameField, genderStack, birthYearField])
        step1Stack.axis = .vertical
        step1Stack.spacing = 24
        step1View.addSubview(step1Stack)
        step1Stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)) }
    }

    private func setupStep2() {
        let label = UILabel()
        label.text = "既往病史（可多选）"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .fdSubtext

        let historyOptions = ["高血压", "糖尿病", "血脂异常", "高尿酸", "冠心病", "甲状腺疾病", "骨质疏松", "无"]
        historyChips = historyOptions.map { OptionChipView(label: $0) }
        historyGroup = OptionChipGroup(chips: historyChips, allowsMultipleSelection: true)
        historyGroup?.onSelectionChanged = { [weak self] _ in self?.updateNextButtonState() }

        let chipGrid = UIStackView()
        chipGrid.axis = .vertical
        chipGrid.spacing = 10

        // Build 2-column rows
        for rowIndex in stride(from: 0, to: historyChips.count, by: 2) {
            let row = UIStackView()
            row.spacing = 10
            row.distribution = .fillEqually
            row.addArrangedSubview(historyChips[rowIndex])
            if rowIndex + 1 < historyChips.count {
                row.addArrangedSubview(historyChips[rowIndex + 1])
            } else {
                row.addArrangedSubview(UIView())
            }
            chipGrid.addArrangedSubview(row)
        }

        let stack = UIStackView(arrangedSubviews: [label, chipGrid])
        stack.axis = .vertical
        stack.spacing = 10
        step2View.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)) }
    }

    private func setupStep3() {
        let smokingLabel = UILabel()
        smokingLabel.text = "吸烟情况"
        smokingLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        smokingLabel.textColor = .fdSubtext

        smokingChips = ["不吸烟", "偶尔吸", "每天吸"].map { OptionChipView(label: $0) }
        smokingGroup = OptionChipGroup(chips: smokingChips, allowsMultipleSelection: false)
        smokingGroup?.onSelectionChanged = { [weak self] _ in self?.updateNextButtonState() }

        let smokingRow = UIStackView()
        smokingRow.spacing = 10
        smokingChips.forEach { smokingRow.addArrangedSubview($0) }

        let exerciseLabel = UILabel()
        exerciseLabel.text = "运动频率（每周）"
        exerciseLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        exerciseLabel.textColor = .fdSubtext

        exerciseChips = ["几乎不运动", "每周1-2次", "每周3-4次", "每周5次以上"].map { OptionChipView(label: $0) }
        exerciseGroup = OptionChipGroup(chips: exerciseChips, allowsMultipleSelection: false)
        exerciseGroup?.onSelectionChanged = { [weak self] _ in self?.updateNextButtonState() }

        let exerciseGrid = UIStackView()
        exerciseGrid.axis = .vertical
        exerciseGrid.spacing = 10
        for rowIndex in stride(from: 0, to: exerciseChips.count, by: 2) {
            let row = UIStackView()
            row.spacing = 10
            row.distribution = .fillEqually
            row.addArrangedSubview(exerciseChips[rowIndex])
            if rowIndex + 1 < exerciseChips.count {
                row.addArrangedSubview(exerciseChips[rowIndex + 1])
            } else {
                row.addArrangedSubview(UIView())
            }
            exerciseGrid.addArrangedSubview(row)
        }

        let stack = UIStackView(arrangedSubviews: [smokingLabel, smokingRow, exerciseLabel, exerciseGrid])
        stack.axis = .vertical
        stack.spacing = 24
        step3View.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)) }
    }

    private func setupStep4() {
        // Team cards built dynamically on reveal
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        step4View.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 24, bottom: 0, right: 24)) }

        for member in team {
            let card = buildTeamCard(member)
            card.alpha = 0
            card.transform = CGAffineTransform(translationX: 0, y: 16)
            stack.addArrangedSubview(card)
            teamCardViews.append(card)
        }
    }

    private func buildTeamCard(_ member: TeamMember) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03

        // Avatar
        let avatar = UIView()
        avatar.layer.cornerRadius = 26
        avatar.clipsToBounds = true
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.fdPrimary.cgColor, UIColor(hexString: "#F25E36").cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = CGRect(x: 0, y: 0, width: 52, height: 52)
        avatar.layer.insertSublayer(gradient, at: 0)

        let avatarLabel = UILabel()
        avatarLabel.text = member.avatar
        avatarLabel.font = .systemFont(ofSize: 18, weight: .bold)
        avatarLabel.textColor = .white
        avatarLabel.textAlignment = .center
        avatar.addSubview(avatarLabel)
        avatarLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        card.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().inset(16)
            make.size.equalTo(52)
            // Anchor card bottom to avatar bottom + padding so card has definite height
            make.bottom.equalToSuperview().offset(-16)
        }

        // Info
        let nameLbl = UILabel()
        nameLbl.text = member.name
        nameLbl.font = .systemFont(ofSize: 16, weight: .bold)
        nameLbl.textColor = .fdText

        let titleLbl = UILabel()
        titleLbl.text = member.title
        titleLbl.font = .systemFont(ofSize: 12)
        titleLbl.textColor = .fdPrimary

        let specialtyLbl = UILabel()
        specialtyLbl.text = member.specialty
        specialtyLbl.font = .systemFont(ofSize: 12)
        specialtyLbl.textColor = .fdSubtext

        let infoStack = UIStackView(arrangedSubviews: [nameLbl, titleLbl, specialtyLbl])
        infoStack.axis = .vertical
        infoStack.spacing = 2
        card.addSubview(infoStack)
        infoStack.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(14)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(avatar)
        }

        return card
    }

    // MARK: - Step UI Update

    private func updateStepUI(animated: Bool) {
        let progress = CGFloat(currentStep) / CGFloat(totalSteps)

        let changes = {
            // Progress bar
            self.progressFill.snp.remakeConstraints { make in
                make.leading.top.bottom.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(progress)
            }
            self.view.layoutIfNeeded()

            // Step label
            self.stepLabel.text = "\(self.currentStep) / \(self.totalSteps)"

            // Step content
            self.step1View.isHidden = self.currentStep != 1
            self.step2View.isHidden = self.currentStep != 2
            self.step3View.isHidden = self.currentStep != 3
            self.step4View.isHidden = self.currentStep != 4

            // Footer
            self.backButton.isHidden = self.currentStep == 1
            if self.currentStep == 4 {
                self.nextButton.setTitle("开始我的健康之旅", for: .normal)
                self.backButton.isHidden = true
            } else {
                self.nextButton.setTitle("下一步", for: .normal)
            }
        }

        switch currentStep {
        case 1:
            titleLabel.text = "基本信息"
            descLabel.text = "建立您的健康档案基础"
        case 2:
            titleLabel.text = "健康史"
            descLabel.text = "了解您的既往病史"
        case 3:
            titleLabel.text = "生活习惯"
            descLabel.text = "评估日常健康行为"
        case 4:
            titleLabel.text = "认识您的专属团队"
            descLabel.text = "三位专家即将就位"
        default: break
        }

        if animated {
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: changes) { _ in
                if self.currentStep == 4 { self.revealTeam() }
            }
        } else {
            changes()
        }

        updateNextButtonState()
    }

    private func updateNextButtonState() {
        let canGo = canGoNext()
        nextButton.isEnabled = canGo
        nextButton.alpha = canGo ? 1.0 : 0.45
        nextButton.layer.shadowOpacity = canGo ? 0.32 : 0
    }

    private func canGoNext() -> Bool {
        switch currentStep {
        case 1:
            return !nameField.textField.text!.trimmingCharacters(in: .whitespaces).isEmpty &&
                   genderGroup?.selectedChips.isEmpty == false
        case 2:
            return historyGroup?.selectedChips.isEmpty == false
        case 3:
            return smokingGroup?.selectedChips.isEmpty == false &&
                   exerciseGroup?.selectedChips.isEmpty == false
        default:
            return true
        }
    }

    // MARK: - Team Reveal Animation

    private func revealTeam() {
        for (i, card) in teamCardViews.enumerated() {
            let delay = 0.35 + Double(i) * 0.25
            UIView.animate(withDuration: 0.45, delay: delay, options: .curveEaseOut) {
                card.alpha = 1
                card.transform = .identity
            }
        }
    }

    // MARK: - Actions

    @objc private func step1Changed() {
        updateNextButtonState()
    }

    @objc private func goBack() {
        guard currentStep > 1 else { return }
        currentStep -= 1
        updateStepUI(animated: true)
    }

    @objc private func goNext() {
        if currentStep < totalSteps {
            currentStep += 1
            updateStepUI(animated: true)
        } else {
            finish()
        }
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: "fd_onboarded")
        UserDefaults.standard.set(38, forKey: "fd_archive_progress")
        let name = nameField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        if !name.isEmpty {
            UserDefaults.standard.set(name, forKey: "fd_profile_name")
        }

        // Dismiss back to TabBar — onboarding sits on top of the main app
        // so user returns to the already-existing TabBar (typically /home)
        dismiss(animated: true)
    }
}
