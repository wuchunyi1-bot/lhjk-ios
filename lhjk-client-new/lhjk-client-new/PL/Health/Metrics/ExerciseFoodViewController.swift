import Combine
import UIKit
import SnapKit

/// 饮食运动（Funde 风格 UI + Angel Doctor API）
final class ExerciseFoodViewController: BaseViewController {

    private let viewModel = ExerciseFoodFundeViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let calCard = UIView()
    private let calVal = UILabel()
    private let calUnit = UILabel()
    private let remainLabel = UILabel()
    private let sportValue = UILabel()
    private let sportHint = UILabel()

    override func setupUI() {
        title = "饮食运动"
        view.backgroundColor = .fdBg
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "明细",
            style: .plain,
            target: self,
            action: #selector(openDetailHome)
        )

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }
        let pad: CGFloat = 16

        calCard.backgroundColor = UIColor(hexString: "#FF7A50")
        calCard.layer.cornerRadius = 24
        let calTitle = UILabel()
        calTitle.text = "今日热量"
        calTitle.font = .fdCaption
        calTitle.textColor = UIColor.white.withAlphaComponent(0.8)
        calVal.font = .fdFont(ofSize: 42, weight: .bold)
        calVal.textColor = .white
        calVal.text = "--"
        calUnit.font = .fdBody
        calUnit.textColor = UIColor.white.withAlphaComponent(0.7)
        calUnit.text = "/ -- kcal"
        remainLabel.font = .fdCaption
        remainLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        [calTitle, calVal, calUnit, remainLabel].forEach(calCard.addSubview)
        calTitle.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(20) }
        calVal.snp.makeConstraints { $0.top.equalTo(calTitle.snp.bottom).offset(4); $0.leading.equalToSuperview().inset(20) }
        calUnit.snp.makeConstraints { $0.lastBaseline.equalTo(calVal).offset(-6); $0.leading.equalTo(calVal.snp.trailing).offset(4) }
        remainLabel.snp.makeConstraints { $0.top.equalTo(calVal.snp.bottom).offset(4); $0.leading.equalToSuperview().inset(20); $0.bottom.equalToSuperview().offset(-20) }

        // 运动卡（无步数接口：展示运动消耗）
        let exCard = UIView()
        exCard.backgroundColor = .fdSurface
        exCard.layer.cornerRadius = 18
        exCard.addFundeShadow()
        let exTitle = UILabel(); exTitle.text = "今日运动"; exTitle.font = .fdBodySemibold; exTitle.textColor = .fdText
        sportValue.font = .fdH1; sportValue.textColor = .fdText; sportValue.text = "-- kcal"
        sportHint.font = .fdCaption; sportHint.textColor = .fdSubtext; sportHint.text = "运动消耗"
        [exTitle, sportValue, sportHint].forEach(exCard.addSubview)
        exTitle.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }
        sportValue.snp.makeConstraints { $0.top.equalTo(exTitle.snp.bottom).offset(8); $0.leading.equalToSuperview().inset(16) }
        sportHint.snp.makeConstraints { $0.top.equalTo(sportValue.snp.bottom).offset(4); $0.leading.equalToSuperview().inset(16); $0.bottom.equalToSuperview().offset(-16) }

        let dietBtn = makeActionButton(title: "记录饮食", action: #selector(addDiet))
        let sportBtn = makeActionButton(title: "记录运动", action: #selector(addSport))
        let aiBtn = UIButton(type: .system)
        aiBtn.setTitle("AI 拍照识别食物", for: .normal)
        aiBtn.titleLabel?.font = .fdBodySemibold
        aiBtn.setTitleColor(.fdPrimary, for: .normal)
        aiBtn.backgroundColor = .fdPrimarySoft
        aiBtn.layer.cornerRadius = 14
        aiBtn.addTarget(self, action: #selector(aiTapped), for: .touchUpInside)

        [calCard, exCard, dietBtn, sportBtn, aiBtn].forEach(contentView.addSubview)
        calCard.snp.makeConstraints { $0.top.equalToSuperview().offset(12); $0.leading.trailing.equalToSuperview().inset(pad) }
        exCard.snp.makeConstraints { $0.top.equalTo(calCard.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(pad) }
        dietBtn.snp.makeConstraints { $0.top.equalTo(exCard.snp.bottom).offset(16); $0.leading.trailing.equalToSuperview().inset(pad); $0.height.equalTo(48) }
        sportBtn.snp.makeConstraints { $0.top.equalTo(dietBtn.snp.bottom).offset(10); $0.leading.trailing.equalToSuperview().inset(pad); $0.height.equalTo(48) }
        aiBtn.snp.makeConstraints { $0.top.equalTo(sportBtn.snp.bottom).offset(10); $0.leading.trailing.equalToSuperview().inset(pad); $0.height.equalTo(50); $0.bottom.equalToSuperview().offset(-20) }
    }

    override func bindViewModel() {
        viewModel.$summary
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reloadUI() }
            .store(in: &cancellables)

        viewModel.toastMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.showToast($0) }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleChange),
            name: .exerciseFoodRecordDidChange,
            object: nil
        )
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.load()
    }

    private func reloadUI() {
        calVal.text = viewModel.intakeText
        calUnit.text = "/ \(viewModel.targetHint) kcal"
        remainLabel.text = "\(viewModel.remainLabel) \(viewModel.remainValue) kcal"
        sportValue.text = "\(viewModel.sportConsume) kcal"
    }

    private func makeActionButton(title: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .fdBodySemibold
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .fdPrimary
        btn.layer.cornerRadius = 14
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }

    @objc private func handleChange() { viewModel.load() }

    @objc private func openDetailHome() {
        Router.shared.push("/health/metrics/exercise/home")
    }

    @objc private func addDiet() {
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
        Router.shared.push("/health/metrics/exercise/add-diet", params: [
            "timeType": 1,
            "date": formatter.string(from: Date()),
        ])
    }

    @objc private func addSport() {
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
        Router.shared.push("/health/metrics/exercise/add-motion", params: [
            "date": formatter.string(from: Date()),
        ])
    }

    @objc private func aiTapped() {
        showToast("拍照识别即将上线")
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}
