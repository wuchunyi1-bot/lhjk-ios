import UIKit
import SnapKit

final class ExerciseFoodDateBarView: UIView {

    var onPrevious: (() -> Void)?
    var onNext: (() -> Void)?
    var onPickDate: (() -> Void)?

    private let previousButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let dateButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface

        previousButton.setTitle("‹", for: .normal)
        previousButton.titleLabel?.font = .fdH2
        previousButton.setTitleColor(.fdText, for: .normal)
        previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)

        nextButton.setTitle("›", for: .normal)
        nextButton.titleLabel?.font = .fdH2
        nextButton.setTitleColor(.fdText, for: .normal)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        dateButton.titleLabel?.font = .fdBodySemibold
        dateButton.setTitleColor(.fdText, for: .normal)
        dateButton.addTarget(self, action: #selector(dateTapped), for: .touchUpInside)

        addSubview(previousButton)
        addSubview(dateButton)
        addSubview(nextButton)

        previousButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        nextButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        dateButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setDateText(_ text: String) {
        dateButton.setTitle(text, for: .normal)
    }

    func setNextEnabled(_ enabled: Bool) {
        nextButton.isEnabled = enabled
        nextButton.alpha = enabled ? 1 : 0.35
    }

    @objc private func previousTapped() { onPrevious?() }
    @objc private func nextTapped() { onNext?() }
    @objc private func dateTapped() { onPickDate?() }
}
