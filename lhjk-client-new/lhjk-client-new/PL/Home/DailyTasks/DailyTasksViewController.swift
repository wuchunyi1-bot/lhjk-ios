import Combine
import SnapKit
import UIKit

/// 今日健康任务详情 — 对齐 DailyTasksView.vue
final class DailyTasksViewController: BaseViewController {

    private let viewModel: DailyTasksViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private weak var heroGradientLayer: CAGradientLayer?

    init(viewModel: DailyTasksViewModel = DailyTasksViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.load()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let hero = contentStack.arrangedSubviews.first?.subviews.first {
            heroGradientLayer?.frame = hero.bounds
        }
    }

    override func setupUI() {
        title = "今日健康任务"
        view.backgroundColor = .fdBg

        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }

        contentStack.axis = .vertical
        contentStack.spacing = 0
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        rebuildContent()
    }

    override func bindViewModel() {
        viewModel.$tasks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.rebuildContent() }
            .store(in: &cancellables)
    }

    // MARK: - Build

    private func rebuildContent() {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        heroGradientLayer = nil

        contentStack.addArrangedSubview(wrap(buildHero(), insets: UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16)))

        if viewModel.tasks.isEmpty {
            contentStack.addArrangedSubview(wrap(buildEmpty(), insets: UIEdgeInsets(top: 24, left: 16, bottom: 16, right: 16)))
        } else {
            let header = buildSectionHeader(title: "任务列表", more: "共 \(viewModel.totalCount) 项")
            contentStack.addArrangedSubview(wrap(header, insets: UIEdgeInsets(top: 12, left: 16, bottom: 8, right: 16)))

            for task in viewModel.tasks {
                contentStack.addArrangedSubview(wrap(buildTaskCard(task), insets: UIEdgeInsets(top: 0, left: 16, bottom: 12, right: 16)))
            }
        }

        contentStack.addArrangedSubview(wrap(buildTipCard(), insets: UIEdgeInsets(top: 8, left: 16, bottom: 28, right: 16)))
        view.setNeedsLayout()
    }

    private func wrap(_ view: UIView, insets: UIEdgeInsets) -> UIView {
        let box = UIView()
        box.addSubview(view)
        view.snp.makeConstraints { $0.edges.equalToSuperview().inset(insets) }
        return box
    }

    private func buildHero() -> UIView {
        let card = UIView()
        card.layer.cornerRadius = 18
        card.clipsToBounds = true

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(hexString: "#FF8A5C").cgColor,
            UIColor(hexString: "#FF6B3D").cgColor,
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        card.layer.insertSublayer(gradient, at: 0)
        heroGradientLayer = gradient

        let label = UILabel()
        label.text = "今日完成进度"
        label.font = .fdCaption
        label.textColor = UIColor.white.withAlphaComponent(0.9)

        let value = UILabel()
        value.text = "\(viewModel.doneCount) / \(viewModel.totalCount)"
        value.font = .fdNumL
        value.textColor = .white

        let meta = UILabel()
        meta.text = "坚持完成每日任务，帮助健管师更好跟进您的健康状态"
        meta.font = .fdMicro
        meta.textColor = UIColor.white.withAlphaComponent(0.92)
        meta.numberOfLines = 0

        let track = UIView()
        track.backgroundColor = UIColor.white.withAlphaComponent(0.28)
        track.layer.cornerRadius = 4

        let fill = UIView()
        fill.backgroundColor = .white
        fill.layer.cornerRadius = 4
        track.addSubview(fill)

        card.addSubview(label)
        card.addSubview(value)
        card.addSubview(meta)
        card.addSubview(track)

        label.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(20)
        }
        value.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        meta.snp.makeConstraints { make in
            make.top.equalTo(value.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        track.snp.makeConstraints { make in
            make.top.equalTo(meta.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(8)
        }
        let ratio = max(0.001, viewModel.progressPercent)
        fill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(track.snp.width).multipliedBy(ratio)
        }

        return card
    }

    private func buildSectionHeader(title: String, more: String) -> UIView {
        let row = UIView()
        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .fdH3
        titleLbl.textColor = .fdText
        let moreLbl = UILabel()
        moreLbl.text = more
        moreLbl.font = .fdCaption
        moreLbl.textColor = .fdSubtext
        row.addSubview(titleLbl)
        row.addSubview(moreLbl)
        titleLbl.snp.makeConstraints { $0.leading.centerY.equalToSuperview() }
        moreLbl.snp.makeConstraints { $0.trailing.centerY.equalToSuperview() }
        row.snp.makeConstraints { $0.height.equalTo(28) }
        return row
    }

    private func buildEmpty() -> UIView {
        let lbl = UILabel()
        lbl.text = "暂无今日健康任务"
        lbl.font = .fdBody
        lbl.textColor = .fdSubtext
        lbl.textAlignment = .center
        return lbl
    }

    private func buildTaskCard(_ task: DailyHealthTask) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.addFundeShadow()
        if task.done { card.alpha = 0.92 }

        let check = UIView()
        check.layer.cornerRadius = 13
        check.layer.borderWidth = 1.6
        if task.done {
            check.backgroundColor = .fdSuccess
            check.layer.borderColor = UIColor.fdSuccess.cgColor
            let img = UIImageView(image: UIImage(systemName: "checkmark"))
            img.tintColor = .white
            img.contentMode = .scaleAspectFit
            check.addSubview(img)
            img.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(12) }
        } else {
            check.backgroundColor = .clear
            check.layer.borderColor = UIColor.fdBorderStrong.cgColor
        }

        let titleLbl = UILabel()
        titleLbl.numberOfLines = 0
        if task.done {
            titleLbl.attributedText = NSAttributedString(
                string: task.title,
                attributes: [
                    .font: UIFont.fdBodyBold,
                    .foregroundColor: UIColor.fdMuted,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                ]
            )
        } else {
            titleLbl.text = task.title
            titleLbl.font = .fdBodyBold
            titleLbl.textColor = .fdText
        }

        let tag = makePill(task.category)

        let actionBtn = UIButton(type: .system)
        actionBtn.titleLabel?.font = .fdCaptionSemibold
        actionBtn.layer.cornerRadius = 18
        actionBtn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        if task.done {
            actionBtn.setTitle("已完成", for: .normal)
            actionBtn.setTitleColor(.fdSuccess, for: .normal)
            actionBtn.backgroundColor = .fdSuccessSoft
            actionBtn.isEnabled = false
        } else {
            actionBtn.setTitle("去完成", for: .normal)
            actionBtn.setTitleColor(.white, for: .normal)
            actionBtn.backgroundColor = .fdPrimary
            actionBtn.accessibilityIdentifier = task.id
            actionBtn.addTarget(self, action: #selector(handleCompleteTap(_:)), for: .touchUpInside)
        }
        actionBtn.snp.makeConstraints { $0.height.greaterThanOrEqualTo(36) }

        let desc = UILabel()
        desc.text = task.desc
        desc.font = .fdCaption
        desc.textColor = .fdSubtext
        desc.numberOfLines = 0

        let rowsStack = UIStackView()
        rowsStack.axis = .vertical
        rowsStack.spacing = 8
        for row in task.detailRows {
            rowsStack.addArrangedSubview(makeKVRow(label: row.label, value: row.value, valueColor: .fdText))
        }
        let statusColor: UIColor = task.done ? .fdSuccess : UIColor(hexString: "#B47300")
        rowsStack.addArrangedSubview(makeKVRow(
            label: "完成状态",
            value: task.done ? "已完成" : "待完成",
            valueColor: statusColor
        ))
        if let completedAt = task.completedAt, !completedAt.isEmpty {
            rowsStack.addArrangedSubview(makeKVRow(label: "完成时间", value: completedAt, valueColor: .fdText))
        }

        let divider = UIView()
        divider.backgroundColor = .fdBorder

        card.addSubview(check)
        card.addSubview(titleLbl)
        card.addSubview(tag)
        card.addSubview(actionBtn)
        card.addSubview(desc)
        card.addSubview(divider)
        card.addSubview(rowsStack)

        check.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
            make.size.equalTo(26)
        }
        actionBtn.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().inset(16)
        }
        titleLbl.snp.makeConstraints { make in
            make.top.equalTo(check)
            make.leading.equalTo(check.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(actionBtn.snp.leading).offset(-8)
        }
        tag.snp.makeConstraints { make in
            make.top.equalTo(titleLbl.snp.bottom).offset(6)
            make.leading.equalTo(titleLbl)
        }
        desc.snp.makeConstraints { make in
            make.top.equalTo(tag.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        divider.snp.makeConstraints { make in
            make.top.equalTo(desc.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(1)
        }
        if let instructions = task.instructions, !instructions.isEmpty {
            let box = UIView()
            box.backgroundColor = .fdBg2
            box.layer.cornerRadius = 12
            let t = UILabel()
            t.text = "监测说明"
            t.font = .fdCaptionSemibold
            t.textColor = .fdText
            let body = UILabel()
            body.text = instructions
            body.font = .fdMicro
            body.textColor = .fdSubtext
            body.numberOfLines = 0
            box.addSubview(t)
            box.addSubview(body)
            t.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview().inset(12)
            }
            body.snp.makeConstraints { make in
                make.top.equalTo(t.snp.bottom).offset(6)
                make.leading.trailing.bottom.equalToSuperview().inset(12)
            }
            card.addSubview(box)
            rowsStack.snp.makeConstraints { make in
                make.top.equalTo(divider.snp.bottom).offset(12)
                make.leading.trailing.equalToSuperview().inset(16)
            }
            box.snp.makeConstraints { make in
                make.top.equalTo(rowsStack.snp.bottom).offset(12)
                make.leading.trailing.equalToSuperview().inset(16)
                make.bottom.equalToSuperview().offset(-16)
            }
        } else {
            rowsStack.snp.makeConstraints { make in
                make.top.equalTo(divider.snp.bottom).offset(12)
                make.leading.trailing.equalToSuperview().inset(16)
                make.bottom.equalToSuperview().offset(-16)
            }
        }

        return card
    }

    private func buildTipCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.addFundeShadow()
        let title = UILabel()
        title.text = "温馨提示"
        title.font = .fdBodySemibold
        title.textColor = .fdText
        let body = UILabel()
        body.text = viewModel.tipText
        body.font = .fdCaption
        body.textColor = .fdSubtext
        body.numberOfLines = 0
        card.addSubview(title)
        card.addSubview(body)
        title.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        body.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
        }
        return card
    }

    private func makePill(_ text: String) -> UIView {
        let bg = UIView()
        bg.backgroundColor = .fdBg2
        bg.layer.cornerRadius = 999
        let lbl = UILabel()
        lbl.text = text
        lbl.font = .fdMicroBold
        lbl.textColor = .fdText2
        bg.addSubview(lbl)
        lbl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)) }
        return bg
    }

    private func makeKVRow(label: String, value: String, valueColor: UIColor) -> UIView {
        let row = UIView()
        let l = UILabel()
        l.text = label
        l.font = .fdCaption
        l.textColor = .fdMuted
        let v = UILabel()
        v.text = value
        v.font = .fdCaptionSemibold
        v.textColor = valueColor
        v.textAlignment = .right
        v.numberOfLines = 0
        row.addSubview(l)
        row.addSubview(v)
        l.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.4)
        }
        v.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.leading.greaterThanOrEqualTo(l.snp.trailing).offset(12)
        }
        return row
    }

    @objc private func handleCompleteTap(_ sender: UIButton) {
        guard let id = sender.accessibilityIdentifier,
              let task = viewModel.tasks.first(where: { $0.id == id }),
              let route = viewModel.actionRoute(for: task) else { return }
        Router.shared.push(route)
    }
}
