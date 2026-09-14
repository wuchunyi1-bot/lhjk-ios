import UIKit
import SnapKit

/// 完善信息 — 选择出生日期底部弹层，对齐 Figma `5346:16324`
final class OnboardingBirthdayPickerSheet: UIViewController {

    var onConfirm: ((Date) -> Void)?

    private let dimView = UIView()
    private let panel = UIView()
    private let picker = UIPickerView()
    private let highlight = UIView()

    private var years: [Int] = []
    private var months: [Int] = Array(1...12)
    private var days: [Int] = Array(1...31)

    private var yearIndex = 0
    private var monthIndex = 0
    private var dayIndex = 0
    private var didApplyDraft = false

    private let calendar = Calendar(identifier: .gregorian)
    private let maxDate = Date()
    private let draft: Date

    init(selected: Date?) {
        let fallback = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        self.draft = min(selected ?? fallback, Date())
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        rebuildYears()
        applyDraftToIndices()
        rebuildDays()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        picker.subviews.forEach { $0.backgroundColor = .clear }
        guard !didApplyDraft, picker.numberOfComponents == 3 else { return }
        didApplyDraft = true
        picker.selectRow(yearIndex, inComponent: 0, animated: false)
        picker.selectRow(monthIndex, inComponent: 1, animated: false)
        picker.selectRow(dayIndex, inComponent: 2, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.28, delay: 0, options: .curveEaseOut) {
            self.dimView.alpha = 1
            self.panel.transform = .identity
        }
    }

    // MARK: - UI

    private func setupUI() {
        view.backgroundColor = .clear

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimView.alpha = 0
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeTapped)))
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        panel.backgroundColor = .fdSurface
        panel.layer.cornerRadius = 16
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panel.clipsToBounds = true
        panel.transform = CGAffineTransform(translationX: 0, y: 360)
        view.addSubview(panel)
        panel.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }

        let titleLabel = UILabel()
        titleLabel.text = "选择出生日期"
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .fdText
        titleLabel.textAlignment = .center
        panel.addSubview(titleLabel)

        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(named: "address_close"), for: .normal)
        if closeButton.image(for: .normal) == nil {
            closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
            closeButton.tintColor = .fdMuted
        }
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        panel.addSubview(closeButton)

        let divider = UIView()
        divider.backgroundColor = .fdBorder
        panel.addSubview(divider)

        highlight.backgroundColor = .fdBg
        highlight.layer.cornerRadius = 20
        highlight.isUserInteractionEnabled = false
        panel.addSubview(highlight)

        picker.dataSource = self
        picker.delegate = self
        picker.backgroundColor = .clear
        panel.addSubview(picker)

        let confirm = UIButton(type: .custom)
        confirm.backgroundColor = .fdPrimary
        confirm.layer.cornerRadius = 21.5
        confirm.clipsToBounds = true
        confirm.setTitle("确定", for: .normal)
        confirm.setTitleColor(.white, for: .normal)
        confirm.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        confirm.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        panel.addSubview(confirm)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.centerX.equalToSuperview()
        }
        closeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(titleLabel)
            $0.size.equalTo(20)
        }
        divider.snp.makeConstraints {
            $0.top.equalToSuperview().offset(63)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(0.5)
        }
        picker.snp.makeConstraints {
            $0.top.equalTo(divider.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(168)
        }
        highlight.snp.makeConstraints {
            $0.centerY.equalTo(picker)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(40)
        }
        confirm.snp.makeConstraints {
            $0.top.equalTo(picker.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(43)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
        }

        panel.bringSubviewToFront(picker)
    }

    // MARK: - Data

    private func rebuildYears() {
        let maxYear = calendar.component(.year, from: maxDate)
        years = Array(1920...maxYear)
    }

    private func applyDraftToIndices() {
        let y = calendar.component(.year, from: draft)
        let m = calendar.component(.month, from: draft)
        let d = calendar.component(.day, from: draft)
        yearIndex = years.firstIndex(of: y) ?? max(years.count - 1, 0)
        monthIndex = max(0, min(m - 1, months.count - 1))
        dayIndex = max(0, d - 1)
    }

    private func currentYear() -> Int {
        years.indices.contains(yearIndex) ? years[yearIndex] : calendar.component(.year, from: draft)
    }

    private func currentMonth() -> Int {
        months.indices.contains(monthIndex) ? months[monthIndex] : calendar.component(.month, from: draft)
    }

    private func currentDay() -> Int {
        days.indices.contains(dayIndex) ? days[dayIndex] : 1
    }

    private func rebuildDays() {
        var comps = DateComponents()
        comps.year = currentYear()
        comps.month = currentMonth()
        comps.day = 1
        let start = calendar.date(from: comps) ?? maxDate
        let count = calendar.range(of: .day, in: .month, for: start)?.count ?? 31

        var maxDay = count
        let maxY = calendar.component(.year, from: maxDate)
        let maxM = calendar.component(.month, from: maxDate)
        if currentYear() == maxY, currentMonth() == maxM {
            maxDay = min(maxDay, calendar.component(.day, from: maxDate))
        }
        days = Array(1...maxDay)
        dayIndex = min(dayIndex, max(days.count - 1, 0))
    }

    private func composedDate() -> Date {
        var comps = DateComponents()
        comps.year = currentYear()
        comps.month = currentMonth()
        comps.day = currentDay()
        let date = calendar.date(from: comps) ?? draft
        return min(date, maxDate)
    }

    private func title(forRow row: Int, component: Int) -> String {
        switch component {
        case 0: return years.indices.contains(row) ? "\(years[row])年" : ""
        case 1: return months.indices.contains(row) ? String(format: "%02d月", months[row]) : ""
        default: return days.indices.contains(row) ? "\(days[row])日" : ""
        }
    }

    private func isSelected(row: Int, component: Int) -> Bool {
        switch component {
        case 0: return row == yearIndex
        case 1: return row == monthIndex
        default: return row == dayIndex
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismissAnimated()
    }

    @objc private func confirmTapped() {
        onConfirm?(composedDate())
        dismissAnimated()
    }

    private func dismissAnimated() {
        UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseIn) {
            self.dimView.alpha = 0
            self.panel.transform = CGAffineTransform(translationX: 0, y: 360)
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }
}

extension OnboardingBirthdayPickerSheet: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 3 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0: return years.count
        case 1: return months.count
        default: return days.count
        }
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { 36 }

    func pickerView(
        _ pickerView: UIPickerView,
        attributedTitleForRow row: Int,
        forComponent component: Int
    ) -> NSAttributedString? {
        let selected = isSelected(row: row, component: component)
        return NSAttributedString(
            string: title(forRow: row, component: component),
            attributes: [
                .font: UIFont.fdFont(ofSize: selected ? 16 : 14, weight: selected ? .medium : .regular),
                .foregroundColor: selected ? UIColor.fdPrimary : UIColor.fdMuted,
            ]
        )
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0: yearIndex = row
        case 1: monthIndex = row
        default: dayIndex = row
        }
        if component == 0 || component == 1 {
            rebuildDays()
            pickerView.reloadComponent(2)
            pickerView.selectRow(dayIndex, inComponent: 2, animated: false)
        }
        pickerView.reloadAllComponents()
        pickerView.selectRow(yearIndex, inComponent: 0, animated: false)
        pickerView.selectRow(monthIndex, inComponent: 1, animated: false)
        pickerView.selectRow(dayIndex, inComponent: 2, animated: false)
    }
}
