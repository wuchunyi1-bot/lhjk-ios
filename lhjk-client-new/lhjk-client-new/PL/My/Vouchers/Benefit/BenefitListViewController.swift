import UIKit
import SnapKit
import Kingfisher

/// 权益卡模块容器 — 对齐 `OrderListViewController`（状态 Tab + 独立子 VC）
final class BenefitListViewController: BaseViewController {

    private struct TabItem {
        let filter: BenefitStatusFilter
        let emptyText: String
        var title: String { filter.title }
    }

    private let tabs: [TabItem] = [
        TabItem(filter: .all, emptyText: "暂无相关权益卡"),
        TabItem(filter: .pendingBind, emptyText: "暂无待绑定权益卡"),
        TabItem(filter: .pendingReceive, emptyText: "暂无待领取权益卡"),
        TabItem(filter: .available, emptyText: "暂无待使用权益卡"),
        TabItem(filter: .redeemed, emptyText: "暂无已兑换权益卡"),
        TabItem(filter: .expired, emptyText: "暂无已过期权益卡"),
        TabItem(filter: .transferRecords, emptyText: "暂无转赠记录"),
    ]

    private var selectedTabIndex = 0
    private var childVCs: [BenefitTabViewController] = []
    private var currentChildVC: BenefitTabViewController?
    private var availableCount = 0

    private lazy var tabCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.showsHorizontalScrollIndicator = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(OrderTabCell.self, forCellWithReuseIdentifier: OrderTabCell.reuseID)
        return cv
    }()

    private let containerView = UIView()

    override var shouldAutomaticallyForwardAppearanceMethods: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        availableCount = AppContainer.shared.voucherService.availableBenefitCount
        buildChildVCs()
    }

    override func setupUI() {
        view.backgroundColor = .white

        let tabContainer = UIView()
        tabContainer.backgroundColor = .white
        view.addSubview(tabContainer)
        tabContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        tabContainer.addSubview(tabCollectionView)
        tabCollectionView.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalTo(tabContainer.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if currentChildVC == nil {
            showChildVC(at: selectedTabIndex)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        availableCount = AppContainer.shared.voucherService.availableBenefitCount
        tabCollectionView.reloadData()
        currentChildVC?.beginAppearanceTransition(true, animated: animated)
        Task { [weak self] in
            let n = await AppContainer.shared.voucherService.refreshAvailableBenefitCount()
            await MainActor.run {
                self?.availableCount = n
                self?.tabCollectionView.reloadData()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        currentChildVC?.endAppearanceTransition()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        currentChildVC?.beginAppearanceTransition(false, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        currentChildVC?.endAppearanceTransition()
    }

    func refreshVisibleTab() {
        availableCount = AppContainer.shared.voucherService.availableBenefitCount
        tabCollectionView.reloadData()
        currentChildVC?.refresh()
    }

    private func buildChildVCs() {
        childVCs = tabs.map {
            let vc = BenefitTabViewController(filter: $0.filter, emptyText: $0.emptyText)
            vc.onAvailableCountUpdated = { [weak self] count in
                self?.availableCount = count
                self?.tabCollectionView.reloadData()
            }
            return vc
        }
    }

    private func showChildVC(at index: Int) {
        guard index >= 0, index < childVCs.count else { return }
        let isVisible = isViewLoaded && view.window != nil

        if let old = currentChildVC, isVisible {
            old.beginAppearanceTransition(false, animated: false)
            old.endAppearanceTransition()
        }

        for vc in children {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }

        let child = childVCs[index]
        addChild(child)
        containerView.addSubview(child.view)
        child.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        child.didMove(toParent: self)
        currentChildVC = child

        if isVisible {
            child.beginAppearanceTransition(true, animated: false)
            child.endAppearanceTransition()
        }
    }

    private func selectTab(at index: Int) {
        guard index != selectedTabIndex else { return }
        selectedTabIndex = index
        tabCollectionView.reloadData()
        tabCollectionView.scrollToItem(
            at: IndexPath(item: index, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
        showChildVC(at: index)
    }

    private func tabTitle(at index: Int) -> String {
        let item = tabs[index]
        if item.filter == .available, availableCount > 0 {
            return "\(item.title) \(availableCount)"
        }
        return item.title
    }
}

extension BenefitListViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tabs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OrderTabCell.reuseID,
            for: indexPath
        ) as! OrderTabCell
        cell.configure(title: tabTitle(at: indexPath.item), isSelected: indexPath.item == selectedTabIndex)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectTab(at: indexPath.item)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let title = tabTitle(at: indexPath.item)
        let width = title.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30),
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.fdMyCaptionSemibold],
            context: nil
        ).width + 16
        return CGSize(width: ceil(width), height: 30)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}

/// 绑定权益卡 — 对齐 Figma 4086:3936
final class BenefitBindViewController: BaseViewController {

    var onBound: (() -> Void)?

    private let voucherService: VoucherService
    private var agreed = false
    private var bindTask: Task<Void, Never>?
    private var showingSuccess = false

    private let scanOrange = UIColor(hexString: "#FD6111")
    private let titleBrown = UIColor(hexString: "#522B0F")
    private let subtitleBrown = UIColor(hexString: "#8C714F")
    private let noteTitleBrown = UIColor(hexString: "#592F10")
    private let noteBodyBrown = UIColor(hexString: "#592F10").withAlphaComponent(0.6)

    private let scrollView = UIScrollView()
    private let formStack = UIStackView()
    private let successStack = UIStackView()

    private let keyField: UITextField = {
        let tf = UITextField()
        tf.font = .fdFont(ofSize: 14, weight: .regular)
        tf.textColor = .fdText
        tf.borderStyle = .none
        tf.clearButtonMode = .whileEditing
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.smartDashesType = .no
        tf.smartQuotesType = .no
        tf.returnKeyType = .done
        tf.keyboardType = .default
        tf.attributedPlaceholder = NSAttributedString(
            string: "请输入卡密",
            attributes: [
                .font: UIFont.fdFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.fdTabInactive,
            ]
        )
        return tf
    }()

    private let keyBox = UIView()
    private let errorLabel = UILabel()
    private let scanButton = UIButton(type: .custom)
    private let bindButton = UIButton(type: .custom)
    private let agreeButton = UIButton(type: .custom)
    private let rulesLinkButton = UIButton(type: .system)
    private let ruleRow = UIStackView()

    init(voucherService: VoucherService = AppContainer.shared.voucherService) {
        self.voucherService = voucherService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit { bindTask?.cancel() }

    override func setupUI() {
        title = "绑定权益卡"
        view.backgroundColor = .fdBg
        hidesBottomBarWhenPushed = true

        scrollView.keyboardDismissMode = .onDrag
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }

        buildForm()
        buildSuccess()

        scrollView.addSubview(formStack)
        scrollView.addSubview(successStack)
        formStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        successStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(24)
            make.width.equalTo(scrollView).offset(-48)
        }
        successStack.isHidden = true

        keyField.delegate = self
        keyField.addTarget(self, action: #selector(keyChanged), for: .editingChanged)
    }

    private func buildForm() {
        let hero = makeHeroHeader()

        keyBox.backgroundColor = .fdSurface
        keyBox.layer.cornerRadius = 12
        keyBox.clipsToBounds = true

        let keyIcon = UIImageView(image: UIImage(named: "benefit_bind_key"))
        keyIcon.contentMode = .scaleAspectFit
        let divider = UIView()
        divider.backgroundColor = UIColor(hexString: "#E5E7EB")

        keyBox.addSubview(keyIcon)
        keyBox.addSubview(divider)
        keyBox.addSubview(keyField)
        keyIcon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(18)
        }
        divider.snp.makeConstraints {
            $0.leading.equalTo(keyIcon.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(0.5)
            $0.height.equalTo(16)
        }
        keyField.snp.makeConstraints {
            $0.leading.equalTo(divider.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(14)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(22)
        }

        errorLabel.font = .fdFont(ofSize: 12, weight: .regular)
        errorLabel.textColor = .fdDanger
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        bindButton.setTitle("立即绑定", for: .normal)
        bindButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        bindButton.setTitleColor(.white, for: .normal)
        bindButton.backgroundColor = .fdPrimary
        bindButton.layer.cornerRadius = 25.5
        bindButton.clipsToBounds = true
        bindButton.addTarget(self, action: #selector(tapBind), for: .touchUpInside)

        scanButton.setTitle("扫码绑定", for: .normal)
        scanButton.setTitleColor(scanOrange, for: .normal)
        scanButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        scanButton.setImage(UIImage(named: "benefit_bind_scan"), for: .normal)
        scanButton.tintColor = scanOrange
        scanButton.backgroundColor = .clear
        scanButton.layer.cornerRadius = 25.5
        scanButton.layer.borderWidth = 0.5
        scanButton.layer.borderColor = scanOrange.cgColor
        scanButton.clipsToBounds = true
        scanButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -3, bottom: 0, right: 3)
        scanButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: -3)
        scanButton.addTarget(self, action: #selector(tapScan), for: .touchUpInside)

        agreeButton.setImage(UIImage(named: "login_checkbox"), for: .normal)
        agreeButton.setImage(UIImage(named: "login_checkbox_checked"), for: .selected)
        agreeButton.addTarget(self, action: #selector(toggleAgree), for: .touchUpInside)
        agreeButton.snp.makeConstraints { $0.size.equalTo(22) }

        let agreePrefix = UILabel()
        agreePrefix.text = "我已阅读并同意 "
        agreePrefix.font = .fdFont(ofSize: 12, weight: .regular)
        agreePrefix.textColor = .fdMuted

        rulesLinkButton.setTitle("《权益卡使用规则》", for: .normal)
        rulesLinkButton.setTitleColor(.fdPrimary, for: .normal)
        rulesLinkButton.titleLabel?.font = .fdFont(ofSize: 12, weight: .regular)
        rulesLinkButton.addTarget(self, action: #selector(tapRules), for: .touchUpInside)
        rulesLinkButton.contentEdgeInsets = .zero

        ruleRow.axis = .horizontal
        ruleRow.alignment = .center
        ruleRow.spacing = 6
        ruleRow.addArrangedSubview(agreeButton)
        ruleRow.addArrangedSubview(agreePrefix)
        ruleRow.addArrangedSubview(rulesLinkButton)
        let ruleWrap = UIView()
        ruleWrap.addSubview(ruleRow)
        ruleRow.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.top.bottom.equalToSuperview() }

        let noteCard = makeNotesCard()

        let formPad = UIView()
        let padded = UIStackView(arrangedSubviews: [keyBox, bindButton, scanButton, ruleWrap])
        padded.axis = .vertical
        padded.spacing = 20
        padded.setCustomSpacing(28, after: keyBox)
        padded.setCustomSpacing(24, after: scanButton)
        formPad.addSubview(padded)
        padded.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        formPad.addSubview(errorLabel)
        errorLabel.snp.makeConstraints {
            $0.top.equalTo(keyBox.snp.bottom).offset(6)
            $0.leading.trailing.equalTo(padded)
        }

        let notePad = UIView()
        notePad.addSubview(noteCard)
        noteCard.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-24)
        }

        formStack.axis = .vertical
        formStack.spacing = 0
        formStack.addArrangedSubview(hero)
        formStack.addArrangedSubview(formPad)
        formStack.addArrangedSubview(notePad)

        keyBox.snp.makeConstraints { $0.height.equalTo(48) }
        scanButton.snp.makeConstraints { $0.height.equalTo(51) }
        bindButton.snp.makeConstraints { $0.height.equalTo(51) }
    }

    private func makeHeroHeader() -> UIView {
        let header = UIView()
        header.clipsToBounds = true

        let heroImage = UIImageView(image: UIImage(named: "benefit_bind_hero"))
        heroImage.contentMode = .scaleAspectFill
        heroImage.clipsToBounds = true

        let fade = UIView()
        let fadeLayer = CAGradientLayer()
        fadeLayer.colors = [
            UIColor.fdBg.withAlphaComponent(0).cgColor,
            UIColor.fdBg.cgColor,
        ]
        fadeLayer.name = "heroFade"
        fadeLayer.startPoint = CGPoint(x: 0.5, y: 0)
        fadeLayer.endPoint = CGPoint(x: 0.5, y: 1)
        fade.layer.addSublayer(fadeLayer)

        let cards = UIImageView(image: UIImage(named: "benefit_bind_cards"))
        cards.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = "绑定权益卡"
        title.font = .fdFont(ofSize: 20, weight: .semibold)
        title.textColor = titleBrown
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "请输入卡密，或扫码绑定权益卡"
        subtitle.font = .fdFont(ofSize: 14, weight: .regular)
        subtitle.textColor = subtitleBrown
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        header.addSubview(heroImage)
        header.addSubview(fade)
        header.addSubview(cards)
        header.addSubview(title)
        header.addSubview(subtitle)

        header.snp.makeConstraints { $0.height.equalTo(202) }
        heroImage.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(header.snp.width).multipliedBy(212.0 / 375.0)
        }
        fade.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(heroImage)
            $0.height.equalTo(80)
        }
        cards.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.size.equalTo(160)
        }
        title.snp.makeConstraints {
            $0.top.equalToSuperview().offset(132)
            $0.centerX.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        subtitle.snp.makeConstraints {
            $0.top.equalToSuperview().offset(161)
            $0.centerX.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        return header
    }

    private func buildSuccess() {
        let iconBox = UIView()
        iconBox.backgroundColor = .fdSuccessSoft
        iconBox.layer.cornerRadius = 32
        let check = UIImageView(image: UIImage(systemName: "checkmark"))
        check.tintColor = .fdSuccess
        check.contentMode = .scaleAspectFit
        iconBox.addSubview(check)
        check.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(28) }
        iconBox.snp.makeConstraints { $0.size.equalTo(64) }

        let title = UILabel()
        title.text = "权益卡已绑定"
        title.font = .fdFont(ofSize: 20, weight: .semibold)
        title.textColor = titleBrown
        title.textAlignment = .center

        let sub = UILabel()
        sub.text = "您现在可以使用权益卡兑换套餐"
        sub.font = .fdFont(ofSize: 14, weight: .regular)
        sub.textColor = subtitleBrown
        sub.textAlignment = .center
        sub.numberOfLines = 0

        let redeemBtn = UIButton(type: .custom)
        redeemBtn.setTitle("去兑换套餐", for: .normal)
        redeemBtn.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        redeemBtn.setTitleColor(.white, for: .normal)
        redeemBtn.backgroundColor = .fdPrimary
        redeemBtn.layer.cornerRadius = 25.5
        redeemBtn.clipsToBounds = true
        redeemBtn.addTarget(self, action: #selector(tapGoRedeem), for: .touchUpInside)

        let vouchersBtn = UIButton(type: .custom)
        vouchersBtn.setTitle("查看我的权益卡", for: .normal)
        vouchersBtn.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        vouchersBtn.setTitleColor(scanOrange, for: .normal)
        vouchersBtn.backgroundColor = .clear
        vouchersBtn.layer.cornerRadius = 25.5
        vouchersBtn.layer.borderWidth = 0.5
        vouchersBtn.layer.borderColor = scanOrange.cgColor
        vouchersBtn.addTarget(self, action: #selector(tapGoVouchers), for: .touchUpInside)

        successStack.axis = .vertical
        successStack.alignment = .center
        successStack.spacing = 12
        successStack.addArrangedSubview(iconBox)
        successStack.addArrangedSubview(title)
        successStack.addArrangedSubview(sub)
        successStack.setCustomSpacing(28, after: sub)
        successStack.addArrangedSubview(redeemBtn)
        successStack.addArrangedSubview(vouchersBtn)
        redeemBtn.snp.makeConstraints { $0.height.equalTo(51); $0.width.equalTo(successStack.snp.width) }
        vouchersBtn.snp.makeConstraints { $0.height.equalTo(51); $0.width.equalTo(successStack.snp.width) }
    }

    private func makeNotesCard() -> UIView {
        let card = UIView()
        card.layer.cornerRadius = 16
        card.clipsToBounds = true

        let bg = CAGradientLayer()
        bg.colors = [
            UIColor(hexString: "#FFF1E5").cgColor,
            UIColor.fdBg.cgColor,
        ]
        bg.startPoint = CGPoint(x: 0.15, y: 0)
        bg.endPoint = CGPoint(x: 0.85, y: 1)
        bg.name = "noteGradient"
        card.layer.insertSublayer(bg, at: 0)

        let bindTitle = sectionTitle("绑定说明")
        let bindBody = sectionBody([
            "卡密为字母与数字的组合。",
            "输入正确卡密后，即可绑定到当前账号。",
            "绑定成功后，可在“我的 - 我的卡券”中查看。",
        ])
        let useTitle = sectionTitle("使用说明")
        let useBody = sectionBody([
            "卡密仅用于绑定权益卡，不可兑换现金或找零。",
            "同一张权益卡仅限绑定一次，绑定后不可重复使用。",
        ])

        let stack = UIStackView(arrangedSubviews: [bindTitle, bindBody, useTitle, useBody])
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(16, after: bindBody)
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        return card
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .fdFont(ofSize: 14, weight: .medium)
        l.textColor = noteTitleBrown
        return l
    }

    private func sectionBody(_ lines: [String]) -> UILabel {
        let l = UILabel()
        l.numberOfLines = 0
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.5
        paragraph.headIndent = 14
        let text = lines.map { "•  \($0)" }.joined(separator: "\n")
        l.attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.fdFont(ofSize: 12, weight: .regular),
            .foregroundColor: noteBodyBrown,
            .paragraphStyle: paragraph,
        ])
        return l
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutNamedGradients(in: view)
    }

    private func layoutNamedGradients(in root: UIView) {
        root.layer.sublayers?.forEach { layer in
            guard layer.name == "noteGradient" || layer.name == "heroFade" else { return }
            layer.frame = root.bounds
        }
        root.subviews.forEach { layoutNamedGradients(in: $0) }
    }

    @objc private func keyChanged() {
        setError(nil)
    }

    @objc private func toggleAgree() {
        agreed.toggle()
        agreeButton.isSelected = agreed
        setError(nil)
    }

    @objc private func tapRules() {
        Router.shared.push("/auth/agreement/benefit-card")
    }

    @objc private func tapScan() {
        view.endEditing(true)
        let vc = QRCodeScanViewController()
        vc.onScanResult = { [weak self] raw in
            self?.fillKeyField(withScanResult: raw)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    /// 扫码结果原样回填到卡密输入框（不自动绑定、不做格式化）
    private func fillKeyField(withScanResult raw: String) {
        guard !raw.isEmpty else {
            setError("未识别到内容，请重试或手动输入")
            return
        }
        keyField.text = raw
        setError(nil)
        keyField.becomeFirstResponder()
    }

    @objc private func tapBind() {
        view.endEditing(true)
        guard agreed else {
            shake(ruleRow)
            return
        }
        // 输入框内容原样提交，不做 trim / 大小写 / 过滤
        let key = keyField.text ?? ""
        guard !key.isEmpty else {
            setError("请输入权益卡卡密")
            return
        }

        bindButton.isEnabled = false
        bindTask?.cancel()
        bindTask = Task { [weak self] in
            guard let self else { return }
            do {
                let pre = try await self.voucherService.preCheckByKey(key)
                switch pre.checkStatusCode {
                case 1:
                    try await self.voucherService.bindByKey(key)
                    _ = await self.voucherService.refreshAvailableBenefitCount()
                    await MainActor.run {
                        self.bindButton.isEnabled = true
                        self.onBound?()
                        self.showSuccessState()
                    }
                case 2:
                    await MainActor.run {
                        self.bindButton.isEnabled = true
                        self.setError("该权益卡已被绑定，不能重复绑定")
                    }
                case 3:
                    await MainActor.run {
                        self.bindButton.isEnabled = true
                        self.setError("该权益卡已过期，不能绑定")
                    }
                case 4:
                    await MainActor.run {
                        self.bindButton.isEnabled = true
                        self.setError("卡密无法识别，请检查后重试")
                    }
                default:
                    await MainActor.run {
                        self.bindButton.isEnabled = true
                        self.setError("卡密校验失败，请稍后重试")
                    }
                }
            } catch {
                await MainActor.run {
                    self.bindButton.isEnabled = true
                    self.setError(error.localizedDescription.isEmpty ? "绑定失败，请稍后重试" : error.localizedDescription)
                }
            }
        }
    }

    @objc private func tapGoRedeem() {
        if let nav = navigationController {
            var stack = nav.viewControllers.filter { !($0 is BenefitBindViewController) }
            stack.append(BenefitRedeemViewController())
            nav.setViewControllers(stack, animated: true)
        } else {
            Router.shared.push("/activate/redeem")
        }
    }

    @objc private func tapGoVouchers() {
        if let nav = navigationController {
            var stack = nav.viewControllers.filter {
                !($0 is BenefitBindViewController) && !($0 is ActivateViewController)
            }
            stack.append(VoucherListViewController(topTab: .benefit))
            nav.setViewControllers(stack, animated: true)
        } else {
            Router.shared.push("/me/vouchers", params: ["tab": "benefit"])
        }
    }

    private func showSuccessState() {
        showingSuccess = true
        view.endEditing(true)
        formStack.isHidden = true
        successStack.isHidden = false
    }

    private func setError(_ message: String?) {
        let text = message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        errorLabel.text = text
        errorLabel.isHidden = text.isEmpty
    }

    private func shake(_ target: UIView) {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        anim.duration = 0.36
        anim.values = [-8, 8, -6, 6, -3, 3, 0]
        target.layer.add(anim, forKey: "shake")
    }

    private func showToast(_ message: String) {
        showToastAlert(message, duration: 1.3)
    }
}

extension BenefitBindViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

/// 赠送权益卡 — 对齐原型 `/me/vouchers/transfer/:cardId`
final class BenefitTransferViewController: BaseViewController {

    var onGifted: (() -> Void)?

    private let card: BenefitCard
    private let benefitsTakeId: Int64
    private let voucherService: VoucherService
    private var giftTask: Task<Void, Never>?

    private let cardNameLabel = UILabel()
    private let amountLabel = UILabel()
    private let messageView: UITextView = {
        let tv = UITextView()
        tv.font = .fdMyBody
        tv.textColor = .fdText
        tv.backgroundColor = .fdSurface
        tv.layer.cornerRadius = 12
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.fdBorder.cgColor
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        return tv
    }()
    private let counterLabel: UILabel = {
        let l = UILabel()
        l.font = .fdMyMicro
        l.textColor = .fdMuted
        l.textAlignment = .right
        l.text = "0/50"
        return l
    }()
    private let hintLabel: UILabel = {
        let l = UILabel()
        l.font = .fdMyCaption
        l.textColor = .fdWarning
        l.numberOfLines = 0
        l.text = "赠送后24小时未领取自动退回，期间不可兑换或转赠。"
        return l
    }()
    private let cancelButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)

    init(
        card: BenefitCard,
        benefitsTakeId: Int64,
        voucherService: VoucherService = AppContainer.shared.voucherService
    ) {
        self.card = card
        self.benefitsTakeId = benefitsTakeId
        self.voucherService = voucherService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit { giftTask?.cancel() }

    override func setupUI() {
        title = "赠送权益卡"
        view.backgroundColor = .fdBg

        let summary = UIView()
        summary.backgroundColor = .fdSurface
        summary.layer.cornerRadius = 14
        summary.layer.borderWidth = 1
        summary.layer.borderColor = UIColor.fdBorder.cgColor

        cardNameLabel.font = .fdMyBodyBold
        cardNameLabel.textColor = .fdText
        cardNameLabel.text = card.name
        amountLabel.font = .fdNumM
        amountLabel.textColor = .fdPrimary
        amountLabel.text = "面值：¥\(card.amount == floor(card.amount) ? "\(Int(card.amount))" : String(format: "%.2f", card.amount))"

        let summaryStack = UIStackView(arrangedSubviews: [cardNameLabel, amountLabel])
        summaryStack.axis = .vertical
        summaryStack.spacing = 6
        summary.addSubview(summaryStack)
        summaryStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }

        let msgTitle = UILabel()
        msgTitle.text = "留言（选填）"
        msgTitle.font = .fdMyCaptionSemibold
        msgTitle.textColor = .fdText2

        messageView.delegate = self

        cancelButton.setTitle("我再想想", for: .normal)
        cancelButton.titleLabel?.font = .fdMyBodySemibold
        cancelButton.setTitleColor(.fdPrimary, for: .normal)
        cancelButton.backgroundColor = .fdPrimarySoft
        cancelButton.layer.cornerRadius = 24
        cancelButton.addTarget(self, action: #selector(tapCancel), for: .touchUpInside)

        confirmButton.setTitle("立即赠送", for: .normal)
        confirmButton.titleLabel?.font = .fdMyBodySemibold
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.backgroundColor = .fdPrimary
        confirmButton.layer.cornerRadius = 24
        confirmButton.addTarget(self, action: #selector(tapConfirm), for: .touchUpInside)

        let actions = UIStackView(arrangedSubviews: [cancelButton, confirmButton])
        actions.axis = .horizontal
        actions.spacing = 12
        actions.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [
            summary, msgTitle, messageView, counterLabel, hintLabel, actions,
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.setCustomSpacing(8, after: msgTitle)
        stack.setCustomSpacing(4, after: messageView)
        stack.setCustomSpacing(20, after: hintLabel)

        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        messageView.snp.makeConstraints { $0.height.equalTo(120) }
        actions.snp.makeConstraints { $0.height.equalTo(48) }
    }

    @objc private func tapCancel() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func tapConfirm() {
        view.endEditing(true)

        guard WeChatSDKManager.shared.isWeChatInstalled else {
            presentToast("请先安装微信后再赠送好友")
            return
        }

        confirmButton.isEnabled = false
        giftTask?.cancel()
        giftTask = Task { [weak self] in
            guard let self else { return }
            do {
                let issue = try await self.voucherService.giftBenefit(
                    benefitsTakeId: self.benefitsTakeId,
                    message: self.messageView.text
                )
                let operationNo = (issue.operationNo ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !operationNo.isEmpty else {
                    await MainActor.run {
                        self.confirmButton.isEnabled = true
                        self.onGifted?()
                        self.presentAlert(
                            title: "赠送成功",
                            message: "转赠已创建，但未返回分享凭证，请稍后在转赠记录查看。"
                        ) {
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                    return
                }

                let thumbURL = issue.primaryCard?.imageUrl ?? self.card.imageUrl
                let thumb = await self.loadShareThumbImage(from: thumbURL)
                await MainActor.run {
                    self.shareGiftCard(issue: issue, thumb: thumb)
                }
            } catch {
                await MainActor.run {
                    self.confirmButton.isEnabled = true
                    self.presentToast(error.localizedDescription)
                }
            }
        }
    }

    private func shareGiftCard(issue: BenefitsIssueVO, thumb: UIImage?) {
        let payload = BenefitGiftShareBuilder.miniProgramPayload(
            issue: issue,
            fallbackCard: card,
            hdImage: thumb
        )
        print("[BenefitTransfer] share path=\(payload.path) appId=\(issue.appId ?? "") cards=\(issue.cards?.count ?? 0)")
        WeChatSDKManager.shared.shareMiniProgram(payload) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.confirmButton.isEnabled = true
                self.onGifted?()
                switch result {
                case .success:
                    self.presentToast("已分享给微信好友")
                    self.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    let message: String
                    switch error {
                    case .userCancelled:
                        message = "已取消分享。转赠记录仍保留，可请好友在 24 小时内领取。"
                    default:
                        message = "\(error.localizedDescription)。转赠已创建，可在转赠记录查看。"
                    }
                    self.presentAlert(title: "赠送成功", message: message) {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }

    private func loadShareThumbImage(from rawURL: String?) async -> UIImage? {
        guard let raw = rawURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let url = URL(string: raw)
        else { return nil }

        return await withCheckedContinuation { cont in
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data, let image = UIImage(data: data) else {
                    cont.resume(returning: nil)
                    return
                }
                cont.resume(returning: image)
            }.resume()
        }
    }

    private func presentToast(_ message: String) {
        showToastAlert(message, duration: 1.4)
    }

    private func presentAlert(title: String?, message: String, onOK: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default) { _ in onOK() })
        present(alert, animated: true)
    }
}

extension BenefitTransferViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count > 50 {
            textView.text = String(textView.text.prefix(50))
        }
        counterLabel.text = "\(textView.text.count)/50"
    }
}

// MARK: - 兑换套餐 `/activate/redeem`

/// 兑换套餐专区 — 对齐 Figma `4086:4162`；数据 `getRedeemPageInfo` + `getRedeemPackagePage`
final class BenefitRedeemViewController: BaseViewController {

    private let voucherService: VoucherService
    private var loadTask: Task<Void, Never>?
    private var packageTask: Task<Void, Never>?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let hospitalHeader = UIView()
    private let hospitalIcon = UIImageView()
    private let hospitalNameLabel = UILabel()
    private let hospitalAddressLabel = UILabel()
    private let hospitalDivider = UIView()

    private let tabsScroll = UIScrollView()
    private let tabsStack = UIStackView()

    private let hintBar = UIView()
    private let hintIcon = UIImageView()
    private let hintLabel = UILabel()

    private let packageStack = UIStackView()
    private let emptyWrap = UIStackView()
    private let emptyCard = UIView()
    private let emptyMessage = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var pageInfo: BenefitsRedeemPageInfoVO?
    /// nil = 全部
    private var selectedCategoryId: String?
    private var packages: [BenefitsRedeemPackageItem] = []
    private var currentPage = 1
    private var hasMore = false
    private var isLoadingPackages = false

    init(voucherService: VoucherService = AppContainer.shared.voucherService) {
        self.voucherService = voucherService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        loadTask?.cancel()
        packageTask?.cancel()
    }

    override func setupUI() {
        title = "兑换套餐"
        view.backgroundColor = .fdBg
        hidesBottomBarWhenPushed = true

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false

        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.alignment = .fill
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        setupHospitalHeader()
        setupTabs()
        setupHintBar()
        setupPackageArea()

        contentStack.addArrangedSubview(hospitalHeader)
        contentStack.addArrangedSubview(hospitalDivider)
        contentStack.addArrangedSubview(tabsScroll)
        contentStack.addArrangedSubview(hintBar)
        contentStack.addArrangedSubview(packageStack)
        contentStack.addArrangedSubview(emptyWrap)
        contentStack.addArrangedSubview(loadingIndicator)

        hospitalDivider.snp.makeConstraints { $0.height.equalTo(0.5) }
        tabsScroll.snp.makeConstraints { $0.height.equalTo(48) }
        hintBar.snp.makeConstraints { $0.height.equalTo(42) }

        contentStack.setCustomSpacing(18, after: hospitalDivider)
        contentStack.setCustomSpacing(12, after: tabsScroll)
        contentStack.setCustomSpacing(12, after: hintBar)
        contentStack.setCustomSpacing(24, after: packageStack)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPageInfo()
    }

    // MARK: - Header

    private func setupHospitalHeader() {
        hospitalHeader.backgroundColor = .clear

        hospitalIcon.contentMode = .scaleAspectFill
        hospitalIcon.clipsToBounds = true
        hospitalIcon.layer.cornerRadius = 8
        hospitalIcon.image = UIImage(named: "redeem_brand_logo")
        hospitalIcon.snp.makeConstraints { $0.size.equalTo(42) }

        hospitalNameLabel.font = .fdFont(ofSize: 16, weight: .semibold)
        hospitalNameLabel.textColor = .fdText
        hospitalNameLabel.text = "富德健康"
        hospitalNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let badge = PaddedLabel()
        badge.text = "品牌机构"
        badge.font = .fdFont(ofSize: 12, weight: .regular)
        badge.textColor = .fdPrimary
        badge.textAlignment = .center
        badge.contentInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        badge.layer.cornerRadius = 4
        badge.layer.borderWidth = 0.5
        badge.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.5).cgColor
        badge.clipsToBounds = true
        badge.setContentHuggingPriority(.required, for: .horizontal)
        badge.setContentCompressionResistancePriority(.required, for: .horizontal)

        let nameRow = UIStackView(arrangedSubviews: [hospitalNameLabel, badge])
        nameRow.axis = .horizontal
        nameRow.spacing = 6
        nameRow.alignment = .center

        hospitalAddressLabel.font = .fdFont(ofSize: 12, weight: .regular)
        hospitalAddressLabel.textColor = UIColor(hexString: "#6D7381")
        hospitalAddressLabel.numberOfLines = 1
        hospitalAddressLabel.lineBreakMode = .byTruncatingTail
        hospitalAddressLabel.text = "全国服务网络｜距离最近"

        let textCol = UIStackView(arrangedSubviews: [nameRow, hospitalAddressLabel])
        textCol.axis = .vertical
        textCol.spacing = 6
        textCol.alignment = .leading

        let row = UIStackView(arrangedSubviews: [hospitalIcon, textCol])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        hospitalHeader.addSubview(row)
        row.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.equalToSuperview().offset(18)
            $0.bottom.equalToSuperview().offset(-12)
        }

        hospitalDivider.backgroundColor = .fdBorder
    }

    private func setupTabs() {
        tabsScroll.showsHorizontalScrollIndicator = false
        tabsStack.axis = .horizontal
        tabsStack.spacing = 35
        tabsStack.alignment = .top
        tabsStack.isLayoutMarginsRelativeArrangement = true
        tabsStack.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tabsScroll.addSubview(tabsStack)
        tabsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
    }

    private func setupHintBar() {
        hintBar.backgroundColor = .white
        hintBar.layer.cornerRadius = 16
        hintBar.layer.borderWidth = 1
        hintBar.layer.borderColor = UIColor.white.cgColor
        hintBar.clipsToBounds = true

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.white.cgColor,
            UIColor(hexString: "#FDF6F4").cgColor
        ]
        gradient.locations = [0.21, 1.0]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        gradient.name = "hintGradient"
        hintBar.layer.insertSublayer(gradient, at: 0)

        hintIcon.image = UIImage(named: "redeem_hint_horn")
        hintIcon.contentMode = .scaleAspectFit
        hintIcon.snp.makeConstraints { $0.size.equalTo(14) }

        hintLabel.text = "以下套餐可使用权益卡抵扣，具体抵扣金额以兑换页为准"
        hintLabel.font = .fdFont(ofSize: 12, weight: .regular)
        hintLabel.textColor = UIColor(hexString: "#A6ACB8")
        hintLabel.numberOfLines = 1
        hintLabel.lineBreakMode = .byTruncatingTail

        let row = UIStackView(arrangedSubviews: [hintIcon, hintLabel])
        row.axis = .horizontal
        row.spacing = 4
        row.alignment = .center
        hintBar.addSubview(row)
        row.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(15)
            $0.trailing.lessThanOrEqualToSuperview().offset(-15)
            $0.centerY.equalToSuperview()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradient = hintBar.layer.sublayers?.first(where: { $0.name == "hintGradient" }) as? CAGradientLayer {
            gradient.frame = hintBar.bounds
        }
    }

    private func setupPackageArea() {
        packageStack.axis = .vertical
        packageStack.spacing = 12
        packageStack.isLayoutMarginsRelativeArrangement = true
        packageStack.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        emptyMessage.font = .fdFont(ofSize: 13, weight: .regular)
        emptyMessage.textColor = .fdSubtext
        emptyMessage.textAlignment = .center
        emptyMessage.numberOfLines = 0
        emptyCard.backgroundColor = .fdSurface
        emptyCard.layer.cornerRadius = 16
        emptyCard.addSubview(emptyMessage)
        emptyMessage.snp.makeConstraints { $0.edges.equalToSuperview().inset(24) }
        emptyCard.isHidden = true

        emptyWrap.axis = .vertical
        emptyWrap.isLayoutMarginsRelativeArrangement = true
        emptyWrap.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        emptyWrap.addArrangedSubview(emptyCard)

        loadingIndicator.hidesWhenStopped = true
    }

    // MARK: - Data

    private func loadPageInfo() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let info = try await self.voucherService.getRedeemPageInfo()
                await MainActor.run {
                    self.pageInfo = info
                    self.applyHospital(info)
                    self.rebuildTabs(categories: info.categories ?? [])
                    self.selectedCategoryId = nil
                    self.reloadPackages(reset: true)
                }
            } catch {
                await MainActor.run {
                    self.applyHospitalFallback()
                    self.rebuildTabs(categories: [])
                    self.showEmpty(message: error.localizedDescription.isEmpty
                        ? "加载失败，请稍后重试"
                        : error.localizedDescription)
                }
            }
        }
    }

    private func applyHospital(_ info: BenefitsRedeemPageInfoVO) {
        let name = info.hospitalName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        hospitalNameLabel.text = name.isEmpty ? "富德健康" : name
        let addr = info.hospitalAddress?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        hospitalAddressLabel.text = addr.isEmpty ? "全国服务网络｜距离最近" : addr
        if let logo = info.hospitalLogo?.trimmingCharacters(in: .whitespacesAndNewlines),
           !logo.isEmpty,
           let url = URL(string: logo) {
            hospitalIcon.kf.setImage(
                with: url,
                placeholder: UIImage(named: "redeem_brand_logo"),
                options: [.transition(.fade(0.2))]
            )
        } else {
            hospitalIcon.image = UIImage(named: "redeem_brand_logo")
        }
    }

    private func applyHospitalFallback() {
        hospitalNameLabel.text = "富德健康"
        hospitalAddressLabel.text = "全国服务网络｜距离最近"
        hospitalIcon.image = UIImage(named: "redeem_brand_logo")
    }

    private func rebuildTabs(categories: [BenefitsRedeemCategoryVO]) {
        tabsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        tabsStack.addArrangedSubview(makeTabButton(title: "全部", categoryId: nil))
        for cat in categories {
            let title = cat.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !title.isEmpty, let id = cat.idString else { continue }
            tabsStack.addArrangedSubview(makeTabButton(title: title, categoryId: id))
        }
        refreshTabSelection()
    }

    private func makeTabButton(title: String, categoryId: String?) -> UIControl {
        let control = RedeemCategoryTabControl(title: title)
        control.accessibilityIdentifier = categoryId ?? ""
        control.addAction(UIAction { [weak self] _ in
            self?.selectedCategoryId = categoryId
            self?.refreshTabSelection()
            self?.reloadPackages(reset: true)
        }, for: .touchUpInside)
        return control
    }

    private func refreshTabSelection() {
        for case let tab as RedeemCategoryTabControl in tabsStack.arrangedSubviews {
            let id = tab.accessibilityIdentifier ?? ""
            let selected = (selectedCategoryId == nil && id.isEmpty)
                || (selectedCategoryId != nil && id == selectedCategoryId)
            tab.isTabSelected = selected
        }
    }

    private func reloadPackages(reset: Bool) {
        if reset {
            currentPage = 1
            packages = []
            hasMore = false
            rebuildPackageCards()
        }
        guard !isLoadingPackages else { return }
        isLoadingPackages = true
        if packages.isEmpty {
            loadingIndicator.startAnimating()
            emptyCard.isHidden = true
        }

        packageTask?.cancel()
        packageTask = Task { [weak self] in
            guard let self else { return }
            do {
                let page = try await self.voucherService.getRedeemPackagePage(
                    categoryServiceId: self.selectedCategoryId,
                    pageNum: self.currentPage,
                    pageSize: 10
                )
                await MainActor.run {
                    self.isLoadingPackages = false
                    self.loadingIndicator.stopAnimating()
                    if self.currentPage == 1 {
                        self.packages = page.items
                    } else {
                        self.packages.append(contentsOf: page.items)
                    }
                    self.hasMore = page.hasMore
                    self.rebuildPackageCards()
                    if self.packages.isEmpty {
                        self.showEmpty(message: "当前分类暂无可兑换套餐")
                    } else {
                        self.emptyCard.isHidden = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingPackages = false
                    self.loadingIndicator.stopAnimating()
                    if self.packages.isEmpty {
                        self.showEmpty(message: error.localizedDescription.isEmpty
                            ? "加载套餐失败"
                            : error.localizedDescription)
                    }
                }
            }
        }
    }

    private func showEmpty(message: String) {
        emptyMessage.text = message
        emptyCard.isHidden = false
        packageStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    private func rebuildPackageCards() {
        packageStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for item in packages {
            let card = RedeemPackageCardView()
            card.configure(item: item)
            let packageId = item.packageId
            let hospitalId = item.hospitalIdString ?? pageInfo?.hospitalIdString
            card.onRedeem = {
                Router.shared.push(
                    "/services/pkg",
                    params: ServiceRoutes.packageDetailParams(
                        packageId: packageId,
                        hospitalId: hospitalId
                    )
                )
            }
            packageStack.addArrangedSubview(card)
            card.snp.makeConstraints { $0.height.equalTo(109) }
        }
        if hasMore {
            let more = UIButton(type: .system)
            more.setTitle("加载更多", for: .normal)
            more.titleLabel?.font = .fdFont(ofSize: 13, weight: .semibold)
            more.setTitleColor(.fdPrimary, for: .normal)
            more.addAction(UIAction { [weak self] _ in
                guard let self, self.hasMore, !self.isLoadingPackages else { return }
                self.currentPage += 1
                self.reloadPackages(reset: false)
            }, for: .touchUpInside)
            packageStack.addArrangedSubview(more)
        }
    }
}

// MARK: - 分类 Tab（Figma 下划线胶囊）

private final class RedeemCategoryTabControl: UIControl {

    private let titleLabel = UILabel()
    private let underline = UIView()

    var isTabSelected = false {
        didSet { applyStyle() }
    }

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.textAlignment = .center
        underline.backgroundColor = .fdPrimary
        underline.layer.cornerRadius = 2
        underline.clipsToBounds = true
        addSubview(titleLabel)
        addSubview(underline)
        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }
        underline.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(18)
            $0.height.equalTo(4)
            $0.bottom.equalToSuperview()
        }
        applyStyle()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func applyStyle() {
        titleLabel.font = .fdFont(ofSize: 14, weight: isTabSelected ? .medium : .regular)
        titleLabel.textColor = isTabSelected
            ? UIColor(hexString: "#1F2942")
            : UIColor(hexString: "#535D72")
        underline.isHidden = !isTabSelected
    }
}

// MARK: - 套餐卡片（Figma 4086:4208）

private final class RedeemPackageCardView: UIView {

    var onRedeem: (() -> Void)?

    private let thumbView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let priceLabel = UILabel()
    private let redeemButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 16
        clipsToBounds = true

        thumbView.contentMode = .scaleAspectFill
        thumbView.clipsToBounds = true
        thumbView.layer.cornerRadius = 12
        thumbView.backgroundColor = .fdProductImageBg

        titleLabel.font = .fdFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .fdText
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail

        subtitleLabel.font = .fdFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .fdTabInactive
        subtitleLabel.numberOfLines = 1
        subtitleLabel.lineBreakMode = .byTruncatingTail

        priceLabel.numberOfLines = 1

        redeemButton.setTitle("去兑换", for: .normal)
        redeemButton.setTitleColor(.white, for: .normal)
        redeemButton.titleLabel?.font = .fdFont(ofSize: 12, weight: .medium)
        redeemButton.backgroundColor = .fdPrimary
        redeemButton.layer.cornerRadius = 14
        redeemButton.addTarget(self, action: #selector(tapRedeem), for: .touchUpInside)

        addSubview(thumbView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(priceLabel)
        addSubview(redeemButton)

        thumbView.snp.makeConstraints {
            $0.leading.top.equalToSuperview().offset(12)
            $0.size.equalTo(85)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(thumbView.snp.trailing).offset(12)
            $0.top.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().offset(-12)
        }
        subtitleLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.trailing.equalToSuperview().offset(-12)
        }
        priceLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.bottom.equalToSuperview().offset(-14)
        }
        redeemButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.bottom.equalToSuperview().offset(-12)
            $0.width.equalTo(70)
            $0.height.equalTo(28)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 109)
    }

    func configure(item: BenefitsRedeemPackageItem) {
        titleLabel.text = item.displayTitle
        let sub = item.displaySubtitle
        subtitleLabel.text = sub
        subtitleLabel.isHidden = sub.isEmpty
        priceLabel.attributedText = Self.priceAttributed(amount: item.price ?? 0)

        thumbView.kf.cancelDownloadTask()
        if let urlStr = item.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
           !urlStr.isEmpty,
           let url = URL(string: urlStr) {
            thumbView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            thumbView.image = nil
        }
    }

    @objc private func tapRedeem() { onRedeem?() }

    private static func priceAttributed(amount: Double) -> NSAttributedString {
        let num = formatPrice(amount)
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(
            string: "¥",
            attributes: [
                .font: UIFont.fdFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.fdPrimary,
            ]
        ))
        result.append(NSAttributedString(
            string: num,
            attributes: [
                .font: UIFont.fdFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.fdPrimary,
            ]
        ))
        result.append(NSAttributedString(
            string: " 起",
            attributes: [
                .font: UIFont.fdFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.fdPrimary,
            ]
        ))
        return result
    }

    private static func formatPrice(_ value: Double) -> String {
        let safe = max(0, value)
        let rounded = (safe * 100).rounded() / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
        } else {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
        }
        return formatter.string(from: NSNumber(value: rounded))
            ?? String(format: rounded.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.2f", rounded)
    }
}

/// 带内边距的标签（品牌机构徽章）
private final class PaddedLabel: UILabel {
    var contentInsets = UIEdgeInsets.zero {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let fitted = super.sizeThatFits(size)
        return CGSize(
            width: fitted.width + contentInsets.left + contentInsets.right,
            height: fitted.height + contentInsets.top + contentInsets.bottom
        )
    }
}
