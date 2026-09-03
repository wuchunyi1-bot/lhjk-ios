import SnapKit
import UIKit

/// 今日健康任务详情卡片 — 对齐 Figma 4903:17050 / 4903:17094
final class DailyTaskCardView: UIView {

    var onAction: (() -> Void)?

    private let accentBar = UIView()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let cornerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 18, weight: .medium)
        l.textColor = .fdText
        l.numberOfLines = 2
        return l
    }()

    private let categoryPill = UIView()
    private let categoryLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .regular)
        return l
    }()

    private let innerCard: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        return v
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(hexString: "#535D72")
        l.numberOfLines = 0
        return l
    }()

    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#EEEEEE")
        return v
    }()

    private let periodTitleLabel = DailyTaskCardView.kvTitleLabel("计划时段")
    private let periodValueLabel = DailyTaskCardView.kvValueLabel()
    private let timeTitleLabel = DailyTaskCardView.kvTitleLabel("计划时间")
    private let timeValueLabel = DailyTaskCardView.kvValueLabel()

    private let instructionsLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(hexString: "#A6ACB8")
        l.numberOfLines = 0
        return l
    }()

    private let actionButton: UIButton = {
        let b = UIButton(type: .custom)
        b.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        b.layer.cornerRadius = 22
        b.clipsToBounds = true
        return b
    }()

    private var instructionsBottomConstraint: Constraint?
    private var innerBottomConstraint: Constraint?
    private var boundTaskId: String?
    private var boundMonitorType: Int?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with task: DailyHealthTask) {
        boundTaskId = task.id
        boundMonitorType = task.monitorType
        titleLabel.text = task.title
        categoryLabel.text = task.category
        descLabel.text = {
            let message = task.detailMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            return message.isEmpty ? task.desc : message
        }()

        let period = task.planPeriod?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let planTime = task.planTime.trimmingCharacters(in: .whitespacesAndNewlines)
        periodValueLabel.text = period
        timeValueLabel.text = planTime
        periodTitleLabel.isHidden = period.isEmpty
        periodValueLabel.isHidden = period.isEmpty
        timeTitleLabel.isHidden = planTime.isEmpty
        timeValueLabel.isHidden = planTime.isEmpty

        timeTitleLabel.snp.remakeConstraints { make in
            if period.isEmpty {
                make.top.equalTo(divider.snp.bottom).offset(12)
            } else {
                make.top.equalTo(periodTitleLabel.snp.bottom).offset(8)
            }
            make.leading.equalToSuperview().offset(12)
            if planTime.isEmpty {
                make.height.equalTo(0)
            }
            make.bottom.equalToSuperview().offset(-12)
        }
        timeValueLabel.isHidden = planTime.isEmpty

        if let instructions = task.instructions?.trimmingCharacters(in: .whitespacesAndNewlines),
           !instructions.isEmpty {
            instructionsLabel.text = instructions.hasPrefix("监测说明")
                ? instructions
                : "监测说明：\n\(instructions)"
            instructionsLabel.isHidden = false
            instructionsBottomConstraint?.activate()
            innerBottomConstraint?.deactivate()
        } else {
            instructionsLabel.text = nil
            instructionsLabel.isHidden = true
            instructionsBottomConstraint?.deactivate()
            innerBottomConstraint?.activate()
        }

        applyStyle(done: task.done)

        if task.done {
            actionButton.setTitle("已完成", for: .normal)
            actionButton.isEnabled = false
        } else {
            actionButton.setTitle("去完成", for: .normal)
            actionButton.isEnabled = true
        }
    }

    private func applyStyle(done: Bool) {
        // 已完成用 gray，未完成用 high（与切图命名一致）
        let iconName = done ? "home_task_icon_gray" : "home_task_icon_high"
        let cornerName = done ? "home_task_image_gray" : "home_task_image_high"
        iconImageView.image = UIImage(named: iconName)
        cornerImageView.image = UIImage(named: cornerName)
        cornerImageView.isHidden = false

        if done {
            backgroundColor = UIColor(hexString: "#F9F9F9")
            layer.borderColor = UIColor(hexString: "#EEEEEE").cgColor
            accentBar.backgroundColor = UIColor(hexString: "#C8C8C8")
            categoryPill.layer.borderColor = UIColor(hexString: "#C8C8C8").cgColor
            categoryLabel.textColor = UIColor(hexString: "#AAAAAA")
            actionButton.backgroundColor = UIColor(hexString: "#9F9F9F").withAlphaComponent(0.5)
            actionButton.setTitleColor(.white, for: .normal)
        } else {
            backgroundColor = UIColor(hexString: "#FFF7F4")
            layer.borderColor = UIColor(hexString: "#FFE8DE").cgColor
            accentBar.backgroundColor = UIColor(hexString: "#FF7A50")
            categoryPill.layer.borderColor = UIColor(hexString: "#FF7A50").withAlphaComponent(0.5).cgColor
            categoryLabel.textColor = UIColor(hexString: "#FF7A50")
            actionButton.backgroundColor = UIColor(hexString: "#FF7950")
            actionButton.setTitleColor(.white, for: .normal)
        }
    }

    private func setupUI() {
        layer.cornerRadius = 16
        layer.borderWidth = 0.5
        clipsToBounds = true

        categoryPill.layer.cornerRadius = 12
        categoryPill.layer.borderWidth = 0.5
        categoryPill.addSubview(categoryLabel)
        categoryLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6))
        }

        instructionsLabel.isUserInteractionEnabled = false
        innerCard.isUserInteractionEnabled = false

        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        let headerRow = UIStackView(arrangedSubviews: [iconImageView, titleLabel, categoryPill])
        headerRow.axis = .horizontal
        headerRow.spacing = 8
        headerRow.alignment = .center

        addSubview(accentBar)
        addSubview(headerRow)
        addSubview(cornerImageView)
        addSubview(innerCard)
        addSubview(instructionsLabel)
        addSubview(actionButton)

        innerCard.addSubview(descLabel)
        innerCard.addSubview(divider)
        innerCard.addSubview(periodTitleLabel)
        innerCard.addSubview(periodValueLabel)
        innerCard.addSubview(timeTitleLabel)
        innerCard.addSubview(timeValueLabel)

        accentBar.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(24)
            make.width.equalTo(3)
            make.height.equalTo(16)
        }

        iconImageView.snp.makeConstraints { $0.size.equalTo(34) }

        headerRow.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(cornerImageView.snp.leading).offset(-4)
            make.top.equalToSuperview().offset(16)
        }

        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        categoryPill.setContentHuggingPriority(.required, for: .horizontal)

        cornerImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(101)
            make.height.equalTo(63)
        }
        cornerImageView.isUserInteractionEnabled = false

        innerCard.snp.makeConstraints { make in
            make.top.equalTo(headerRow.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
        }

        descLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
        }

        divider.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(0.5)
        }

        periodTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(12)
        }
        periodValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(periodTitleLabel)
            make.trailing.equalToSuperview().inset(12)
        }

        timeTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(periodTitleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
        timeValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(timeTitleLabel)
            make.trailing.equalToSuperview().inset(12)
        }

        instructionsLabel.snp.makeConstraints { make in
            make.top.equalTo(innerCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        actionButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().offset(-12)
            instructionsBottomConstraint = make.top.equalTo(instructionsLabel.snp.bottom).offset(16).constraint
            innerBottomConstraint = make.top.equalTo(innerCard.snp.bottom).offset(16).constraint
        }
        innerBottomConstraint?.deactivate()

        bringSubviewToFront(actionButton)
        actionButton.isUserInteractionEnabled = true
    }

    @objc private func actionTapped() {
        print(
            "[DailyTaskCard] 去完成按钮点击 taskId=\(boundTaskId ?? "?") " +
            "type=\(boundMonitorType.map(String.init) ?? "nil") " +
            "enabled=\(actionButton.isEnabled) title=\(titleLabel.text ?? "")"
        )
        onAction?()
    }

    private static func kvTitleLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .fdFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(hexString: "#535D72")
        return l
    }

    private static func kvValueLabel() -> UILabel {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .regular)
        l.textColor = .fdText
        l.textAlignment = .right
        return l
    }
}
