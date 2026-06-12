import UIKit
import SnapKit

/// 手动录入数据页
/// 参考 funde-client: MetricAddView.vue
final class MetricAddViewController: BaseViewController {

    // MARK: - Config

    struct FieldConfig {
        let id: String; let label: String; let unit: String
        let min: Double; let max: Double; let step: Double; let defaultValue: Double
        let labelEvery: Double
    }

    struct ExtraConfig {
        let id: String; let label: String; let options: [String]
    }

    private let metricKey: String
    private var fields: [FieldConfig] = []
    private var extras: [ExtraConfig] = []
    private var values: [String: Double] = [:]
    private var selectedExtras: [String: String] = [:]

    private let configs: [String: (title: String, fields: [FieldConfig], extras: [ExtraConfig])] = [
        "blood-pressure": ("血压记录", [
            FieldConfig(id: "sys", label: "收缩压", unit: "mmHg", min: 80, max: 220, step: 1, defaultValue: 120, labelEvery: 20),
            FieldConfig(id: "dia", label: "舒张压", unit: "mmHg", min: 40, max: 140, step: 1, defaultValue: 80, labelEvery: 20),
            FieldConfig(id: "pulse", label: "脉搏", unit: "次/分钟", min: 40, max: 180, step: 1, defaultValue: 72, labelEvery: 20),
        ], []),
        "blood-sugar": ("血糖记录", [
            FieldConfig(id: "glucose", label: "血糖值", unit: "mmol/L", min: 1, max: 30, step: 0.1, defaultValue: 5.5, labelEvery: 2),
        ], [ExtraConfig(id: "type", label: "测量时机", options: ["空腹", "餐后2小时", "随机血糖"])]),
        "weight": ("体重记录", [
            FieldConfig(id: "weight", label: "体重", unit: "kg", min: 30, max: 180, step: 0.1, defaultValue: 65, labelEvery: 10),
        ], []),
        "heart-rate": ("心率记录", [
            FieldConfig(id: "hr", label: "心率", unit: "bpm", min: 40, max: 220, step: 1, defaultValue: 75, labelEvery: 20),
        ], [ExtraConfig(id: "scene", label: "测量场景", options: ["静息状态", "运动后"])]),
        "spo2": ("血氧记录", [
            FieldConfig(id: "spo2", label: "血氧饱和度", unit: "%", min: 70, max: 100, step: 1, defaultValue: 98, labelEvery: 5),
        ], []),
        "sleep": ("睡眠记录", [
            FieldConfig(id: "hours", label: "睡眠时长", unit: "小时", min: 1, max: 14, step: 0.5, defaultValue: 7, labelEvery: 2),
        ], []),
    ]

    init(metricKey: String) {
        self.metricKey = metricKey
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI

    private let scrollView = UIScrollView()
    private var rulerViews: [String: MetricRulerView] = [:]

    override func setupUI() {
        title = "手动输入数据"
        view.backgroundColor = .fdBg

        let config = configs[metricKey] ?? ("录入数据", [FieldConfig(id: "value", label: "数值", unit: "", min: 0, max: 999, step: 1, defaultValue: 0, labelEvery: 50)], [])
        fields = config.fields
        extras = config.extras
        values = Dictionary(uniqueKeysWithValues: fields.map { ($0.id, $0.defaultValue) })
        selectedExtras = Dictionary(uniqueKeysWithValues: extras.map { ($0.id, $0.options[0]) })

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        let content = UIView()
        scrollView.addSubview(content)
        content.snp.makeConstraints { $0.edges.width.equalToSuperview() }
        let pad: CGFloat = 16

        // 1. Date/Time card
        let metaCard = buildDateCard()
        content.addSubview(metaCard)
        metaCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(pad)
        }

        // 2. Extra selectors
        if !extras.isEmpty {
            let extraCard = buildExtraCard()
            content.addSubview(extraCard)
            extraCard.snp.makeConstraints { make in
                make.top.equalTo(metaCard.snp.bottom).offset(12)
                make.leading.trailing.equalToSuperview().inset(pad)
            }
        }

        // 3. Fields card
        let fieldsCard = buildFieldsCard()
        content.addSubview(fieldsCard)
        let extraBottom = extras.isEmpty ? metaCard.snp.bottom : content.subviews[content.subviews.count - 2].snp.bottom
        fieldsCard.snp.makeConstraints { make in
            make.top.equalTo(extraBottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(pad)
        }

        // 4. Save button
        let saveBtn = UIButton(type: .system)
        saveBtn.setTitle("保存", for: .normal)
        saveBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        saveBtn.setTitleColor(.white, for: .normal)
        saveBtn.backgroundColor = .fdPrimary
        saveBtn.layer.cornerRadius = 14
        saveBtn.addTarget(self, action: #selector(save), for: .touchUpInside)
        content.addSubview(saveBtn)
        saveBtn.snp.makeConstraints { make in
            make.top.equalTo(fieldsCard.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(pad)
            make.height.equalTo(52)
            make.bottom.equalToSuperview().offset(-28)
        }

        // Scroll to rulers after layout
        DispatchQueue.main.async { [weak self] in
            self?.rulerViews.values.forEach { $0.setValue($0.currentValue) }
        }
    }

    // MARK: - Date Card

    private func buildDateCard() -> UIView {
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()

        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter(); timeFormatter.dateFormat = "HH:mm"

        let dateRow = buildMetaRow(label: "日期", value: formatter.string(from: Date()))
        let timeRow = buildMetaRow(label: "测量时间", value: timeFormatter.string(from: Date()))
        timeRow.subviews.last?.subviews.compactMap { $0 as? UIView }.forEach { $0.removeFromSuperview() }

        card.addSubview(dateRow); card.addSubview(timeRow)
        let divider = UIView(); divider.backgroundColor = .fdBorder
        card.addSubview(divider)

        dateRow.snp.makeConstraints { make in make.top.leading.trailing.equalToSuperview().inset(16) }
        divider.snp.makeConstraints { make in make.top.equalTo(dateRow.snp.bottom); make.leading.trailing.equalToSuperview().inset(16); make.height.equalTo(1) }
        timeRow.snp.makeConstraints { make in make.top.equalTo(divider.snp.bottom); make.leading.trailing.equalToSuperview().inset(16); make.bottom.equalToSuperview() }
        return card
    }

    private func buildMetaRow(label: String, value: String) -> UIView {
        let row = UIView()
        let l = UILabel(); l.text = label; l.font = .systemFont(ofSize: 15, weight: .semibold); l.textColor = .fdText
        let v = UILabel(); v.text = value; v.font = .systemFont(ofSize: 15); v.textColor = .fdSubtext
        row.addSubview(l); row.addSubview(v)
        l.snp.makeConstraints { make in make.top.bottom.equalToSuperview().inset(14); make.leading.equalToSuperview() }
        v.snp.makeConstraints { make in make.centerY.equalTo(l); make.trailing.equalToSuperview() }
        return row
    }

    // MARK: - Extra Selectors

    private func buildExtraCard() -> UIView {
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()

        var prevLabel: UIView?
        for extra in extras {
            let label = UILabel(); label.text = extra.label; label.font = .systemFont(ofSize: 13); label.textColor = .fdSubtext
            card.addSubview(label)
            label.snp.makeConstraints { make in
                if let prev = prevLabel { make.top.equalTo(prev.snp.bottom).offset(16) } else { make.top.equalToSuperview().inset(14) }
                make.leading.equalToSuperview().inset(16)
            }

            let pillStack = UIStackView(); pillStack.axis = .horizontal; pillStack.spacing = 8
            card.addSubview(pillStack)
            pillStack.snp.makeConstraints { make in
                make.top.equalTo(label.snp.bottom).offset(10)
                make.leading.trailing.equalToSuperview().inset(16)
            }
            for opt in extra.options {
                let pill = UIButton(type: .system)
                pill.setTitle(opt, for: .normal); pill.titleLabel?.font = .systemFont(ofSize: 14)
                pill.setTitleColor(.fdText, for: .normal); pill.layer.borderWidth = 1.5; pill.layer.borderColor = UIColor.fdBorder.cgColor
                pill.layer.cornerRadius = 999; pill.contentEdgeInsets = UIEdgeInsets(top: 7, left: 16, bottom: 7, right: 16)
                pill.tag = extra.options.firstIndex(of: opt) ?? 0
                pill.accessibilityIdentifier = "\(extra.id):\(opt)"
                pill.addTarget(self, action: #selector(extraPillTapped(_:)), for: .touchUpInside)
                if opt == extra.options[0] { selectPill(pill) }
                pillStack.addArrangedSubview(pill)
            }
            prevLabel = pillStack
        }
        prevLabel?.snp.makeConstraints { $0.bottom.equalToSuperview().offset(-14) }
        return card
    }

    @objc private func extraPillTapped(_ sender: UIButton) {
        guard let id = sender.accessibilityIdentifier?.components(separatedBy: ":").first else { return }
        guard let opt = sender.accessibilityIdentifier?.components(separatedBy: ":").last else { return }
        selectedExtras[id] = opt

        // Update all pills in same group
        if let stack = sender.superview as? UIStackView {
            for case let pill as UIButton in stack.arrangedSubviews {
                if pill == sender { selectPill(pill) } else { deselectPill(pill) }
            }
        }
    }

    private func selectPill(_ pill: UIButton) {
        pill.setTitleColor(.fdPrimary, for: .normal)
        pill.layer.borderColor = UIColor.fdPrimary.cgColor
        pill.backgroundColor = .fdPrimarySoft
    }

    private func deselectPill(_ pill: UIButton) {
        pill.setTitleColor(.fdText, for: .normal)
        pill.layer.borderColor = UIColor.fdBorder.cgColor
        pill.backgroundColor = .clear
    }

    // MARK: - Fields Card

    private func buildFieldsCard() -> UIView {
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()

        // Title bar
        let bar = UIView(); bar.backgroundColor = .fdPrimary; bar.layer.cornerRadius = 2
        let title = UILabel(); title.font = .systemFont(ofSize: 15, weight: .bold); title.textColor = .fdText
        if let cfg = configs[metricKey] { title.text = cfg.title } else { title.text = "数据录入" }
        card.addSubview(bar); card.addSubview(title)
        bar.snp.makeConstraints { make in make.top.equalToSuperview().offset(18); make.leading.equalToSuperview().inset(16); make.width.equalTo(3); make.height.equalTo(16) }
        title.snp.makeConstraints { make in make.centerY.equalTo(bar); make.leading.equalTo(bar.snp.trailing).offset(8) }

        var prevTitle: UIView = bar
        for field in fields {
            // Header: label + current value
            let header = UILabel(); header.text = field.label; header.font = .systemFont(ofSize: 14, weight: .semibold); header.textColor = .fdText
            let valLabel = UILabel(); valLabel.text = formatFieldValue(field); valLabel.font = .systemFont(ofSize: 24, weight: .bold); valLabel.textColor = .fdText
            valLabel.accessibilityIdentifier = "val_\(field.id)"
            let unitLabel = UILabel(); unitLabel.text = field.unit; unitLabel.font = .systemFont(ofSize: 13); unitLabel.textColor = .fdSubtext

            // Ruler
            let ruler = MetricRulerView(min: field.min, max: field.max, step: field.step, defaultValue: field.defaultValue, labelEvery: field.labelEvery, unit: field.unit)
            ruler.onValueChanged = { [weak self, id = field.id] newVal in
                self?.values[id] = newVal
                if let vl = self?.view.viewWithTag(0) as? UILabel {} // placeholder
                // Update value label
                for sv in self?.view.subviews ?? [] {
                    for case let lbl as UILabel in sv.subviews {
                        if lbl.accessibilityIdentifier == "val_\(id)" {
                            lbl.text = self?.formatFieldValue(FieldConfig(id: id, label: "", unit: field.unit, min: field.min, max: field.max, step: field.step, defaultValue: field.defaultValue, labelEvery: field.labelEvery))
                        }
                    }
                }
                // Simpler: just find and update the label
                self?.updateValueLabel(for: field.id)
            }
            rulerViews[field.id] = ruler

            card.addSubview(header)
            card.addSubview(valLabel); card.addSubview(unitLabel)
            card.addSubview(ruler)

            header.snp.makeConstraints { make in
                make.top.equalTo(prevTitle.snp.bottom).offset(24)
                make.leading.equalToSuperview().inset(16)
            }
            valLabel.snp.makeConstraints { make in
                make.top.equalTo(header.snp.bottom).offset(4)
                make.leading.equalToSuperview().inset(16)
            }
            unitLabel.snp.makeConstraints { make in
                make.lastBaseline.equalTo(valLabel)
                make.leading.equalTo(valLabel.snp.trailing).offset(4)
            }
            ruler.snp.makeConstraints { make in
                make.top.equalTo(valLabel.snp.bottom).offset(10)
                make.leading.trailing.equalToSuperview().inset(16)
            }

            prevTitle = ruler
        }
        prevTitle.snp.makeConstraints { $0.bottom.equalToSuperview().offset(-16) }
        return card
    }

    private func updateValueLabel(for id: String) {
        guard let field = fields.first(where: { $0.id == id }),
              let value = values[id] else { return }
        for sv in scrollView.subviews {
            for case let lbl as UILabel in sv.allSubviews() {
                if lbl.accessibilityIdentifier == "val_\(id)" {
                    lbl.text = formatValue(value, step: field.step)
                }
            }
        }
    }

    private func formatFieldValue(_ f: FieldConfig) -> String {
        formatValue(values[f.id] ?? f.defaultValue, step: f.step)
    }

    private func formatValue(_ v: Double, step: Double) -> String {
        let decimals = String(step).components(separatedBy: ".").last?.count ?? 0
        return decimals > 0 ? String(format: "%.\(decimals)f", v) : String(Int(v))
    }

    // MARK: - Save

    @objc private func save() {
        // TODO: BLL save logic
        navigationController?.popViewController(animated: true)
    }
}

private extension UIView {
    func allSubviews() -> [UIView] {
        var result: [UIView] = []
        for sv in subviews {
            result.append(sv)
            result.append(contentsOf: sv.allSubviews())
        }
        return result
    }
}
