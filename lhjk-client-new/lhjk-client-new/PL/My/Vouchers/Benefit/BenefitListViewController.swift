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
        cv.backgroundColor = .fdBg
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
        view.backgroundColor = .fdBg

        let tabContainer = UIView()
        tabContainer.backgroundColor = .fdBg
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
            attributes: [.font: UIFont.fdCaptionSemibold],
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

/// 绑定权益卡 — 对齐原型 `/activate/bind`
final class BenefitBindViewController: BaseViewController {

    var onBound: (() -> Void)?

    private let voucherService: VoucherService
    private var agreed = false
    private var bindTask: Task<Void, Never>?
    private var showingSuccess = false

    private let scrollView = UIScrollView()
    private let formStack = UIStackView()
    private let successStack = UIStackView()

    private let keyField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "请输入卡密"
        tf.font = .fdH3
        tf.textColor = .fdText
        tf.borderStyle = .none
        tf.clearButtonMode = .whileEditing
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.smartDashesType = .no
        tf.smartQuotesType = .no
        tf.returnKeyType = .done
        tf.keyboardType = .default
        return tf
    }()

    private let keyBox = UIView()
    private let errorLabel = UILabel()
    private let scanButton = UIButton(type: .system)
    private let bindButton = UIButton(type: .system)
    private let agreeButton = UIButton(type: .system)
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
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }

        buildForm()
        buildSuccess()

        scrollView.addSubview(formStack)
        scrollView.addSubview(successStack)
        formStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.width.equalTo(scrollView).offset(-32)
        }
        successStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(24)
            make.width.equalTo(scrollView).offset(-48)
        }
        successStack.isHidden = true

        keyField.delegate = self
        keyField.addTarget(self, action: #selector(keyChanged), for: .editingChanged)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !showingSuccess {
            keyField.becomeFirstResponder()
        }
    }

    private func buildForm() {
        let introIcon = UIImageView(image: UIImage(systemName: "giftcard.fill"))
        introIcon.tintColor = .fdPrimary
        introIcon.contentMode = .scaleAspectFit
        let introIconBox = UIView()
        introIconBox.backgroundColor = .fdPrimarySoft
        introIconBox.layer.cornerRadius = 12
        introIconBox.layer.borderWidth = 1
        introIconBox.layer.borderColor = UIColor.fdPrimaryEdge.cgColor
        introIconBox.addSubview(introIcon)
        introIcon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(28) }
        introIconBox.snp.makeConstraints { $0.size.equalTo(48) }

        let introTitle = UILabel()
        introTitle.text = "绑定权益卡"
        introTitle.font = .fdH2
        introTitle.textColor = .fdText
        introTitle.textAlignment = .center

        let introSub = UILabel()
        introSub.text = "请输入卡密，或扫码绑定权益卡。"
        introSub.font = .fdBody
        introSub.textColor = .fdSubtext
        introSub.textAlignment = .center
        introSub.numberOfLines = 0

        let intro = UIStackView(arrangedSubviews: [introIconBox, introTitle, introSub])
        intro.axis = .vertical
        intro.alignment = .center
        intro.spacing = 8

        keyBox.backgroundColor = .fdBg2
        keyBox.layer.cornerRadius = 8
        keyBox.layer.borderWidth = 1
        keyBox.layer.borderColor = UIColor.fdBorder.cgColor
        keyBox.addSubview(keyField)
        keyField.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))
            $0.height.equalTo(22)
        }

        errorLabel.font = .fdCaption
        errorLabel.textColor = .fdDanger
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        scanButton.backgroundColor = .fdPrimarySoft
        scanButton.layer.cornerRadius = 8
        scanButton.layer.borderWidth = 1
        scanButton.layer.borderColor = UIColor.fdPrimaryEdge.cgColor
        scanButton.setTitle("  扫码绑定", for: .normal)
        scanButton.setTitleColor(.fdText, for: .normal)
        scanButton.titleLabel?.font = .fdBodySemibold
        scanButton.setImage(UIImage(systemName: "qrcode.viewfinder"), for: .normal)
        scanButton.tintColor = .fdPrimary
        scanButton.contentHorizontalAlignment = .left
        scanButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        scanButton.addTarget(self, action: #selector(tapScan), for: .touchUpInside)
        let scanChevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        scanChevron.tintColor = .fdMuted
        scanButton.addSubview(scanChevron)
        scanChevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.centerY.equalToSuperview()
        }

        bindButton.setTitle("立即绑定", for: .normal)
        bindButton.titleLabel?.font = .fdBodySemibold
        bindButton.setTitleColor(.white, for: .normal)
        bindButton.backgroundColor = .fdPrimary
        bindButton.layer.cornerRadius = 24
        bindButton.addTarget(self, action: #selector(tapBind), for: .touchUpInside)

        agreeButton.setImage(UIImage(systemName: "circle"), for: .normal)
        agreeButton.tintColor = .fdMuted
        agreeButton.addTarget(self, action: #selector(toggleAgree), for: .touchUpInside)
        agreeButton.snp.makeConstraints { $0.size.equalTo(22) }

        let agreePrefix = UILabel()
        agreePrefix.text = "我已阅读并同意"
        agreePrefix.font = .fdCaption
        agreePrefix.textColor = .fdSubtext

        rulesLinkButton.setTitle("《权益卡使用规则》", for: .normal)
        rulesLinkButton.setTitleColor(.fdPrimary, for: .normal)
        rulesLinkButton.titleLabel?.font = .fdCaptionSemibold
        rulesLinkButton.addTarget(self, action: #selector(tapRules), for: .touchUpInside)

        ruleRow.axis = .horizontal
        ruleRow.alignment = .center
        ruleRow.spacing = 4
        ruleRow.addArrangedSubview(agreeButton)
        ruleRow.addArrangedSubview(agreePrefix)
        ruleRow.addArrangedSubview(rulesLinkButton)
        let ruleWrap = UIView()
        ruleWrap.addSubview(ruleRow)
        ruleRow.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.top.bottom.equalToSuperview() }

        let noteCard = makeNotesCard()

        formStack.axis = .vertical
        formStack.spacing = 12
        formStack.addArrangedSubview(intro)
        formStack.setCustomSpacing(24, after: intro)
        formStack.addArrangedSubview(keyBox)
        formStack.addArrangedSubview(errorLabel)
        formStack.addArrangedSubview(scanButton)
        formStack.addArrangedSubview(bindButton)
        formStack.addArrangedSubview(ruleWrap)
        formStack.setCustomSpacing(20, after: ruleWrap)
        formStack.addArrangedSubview(noteCard)

        scanButton.snp.makeConstraints { $0.height.equalTo(48) }
        bindButton.snp.makeConstraints { $0.height.equalTo(48) }
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
        title.font = .fdH2
        title.textColor = .fdText
        title.textAlignment = .center

        let sub = UILabel()
        sub.text = "您现在可以使用权益卡兑换套餐"
        sub.font = .fdBody
        sub.textColor = .fdSubtext
        sub.textAlignment = .center
        sub.numberOfLines = 0

        let redeemBtn = UIButton(type: .system)
        redeemBtn.setTitle("去兑换套餐", for: .normal)
        redeemBtn.titleLabel?.font = .fdBodySemibold
        redeemBtn.setTitleColor(.white, for: .normal)
        redeemBtn.backgroundColor = .fdPrimary
        redeemBtn.layer.cornerRadius = 24
        redeemBtn.addTarget(self, action: #selector(tapGoRedeem), for: .touchUpInside)

        let vouchersBtn = UIButton(type: .system)
        vouchersBtn.setTitle("查看我的权益卡", for: .normal)
        vouchersBtn.titleLabel?.font = .fdBodySemibold
        vouchersBtn.setTitleColor(.fdPrimary, for: .normal)
        vouchersBtn.backgroundColor = .fdPrimarySoft
        vouchersBtn.layer.cornerRadius = 24
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
        redeemBtn.snp.makeConstraints { $0.height.equalTo(48); $0.width.equalTo(successStack.snp.width) }
        vouchersBtn.snp.makeConstraints { $0.height.equalTo(48); $0.width.equalTo(successStack.snp.width) }
    }

    private func makeNotesCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdBorder.cgColor

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
        l.font = .fdBodySemibold
        l.textColor = .fdText
        return l
    }

    private func sectionBody(_ lines: [String]) -> UILabel {
        let l = UILabel()
        l.numberOfLines = 0
        l.font = .fdCaption
        l.textColor = .fdSubtext
        l.text = lines.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        return l
    }

    @objc private func keyChanged() {
        setError(nil)
    }

    @objc private func toggleAgree() {
        agreed.toggle()
        agreeButton.setImage(UIImage(systemName: agreed ? "checkmark.circle.fill" : "circle"), for: .normal)
        agreeButton.tintColor = agreed ? .fdPrimary : .fdMuted
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
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            alert.dismiss(animated: true)
        }
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
        tv.font = .fdBody
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
        l.font = .fdMicro
        l.textColor = .fdMuted
        l.textAlignment = .right
        l.text = "0/50"
        return l
    }()
    private let hintLabel: UILabel = {
        let l = UILabel()
        l.font = .fdCaption
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

        cardNameLabel.font = .fdBodyBold
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
        msgTitle.font = .fdCaptionSemibold
        msgTitle.textColor = .fdText2

        messageView.delegate = self

        cancelButton.setTitle("我再想想", for: .normal)
        cancelButton.titleLabel?.font = .fdBodySemibold
        cancelButton.setTitleColor(.fdPrimary, for: .normal)
        cancelButton.backgroundColor = .fdPrimarySoft
        cancelButton.layer.cornerRadius = 24
        cancelButton.addTarget(self, action: #selector(tapCancel), for: .touchUpInside)

        confirmButton.setTitle("立即赠送", for: .normal)
        confirmButton.titleLabel?.font = .fdBodySemibold
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
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            alert.dismiss(animated: true)
        }
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

// MARK: - 激活兑换 Hub `/activate`

/// 激活兑换 — 对齐 funde `ActivateView` / `activate.page.yaml`
final class ActivateViewController: BaseViewController {

    private let voucherService: VoucherService
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private var loadTask: Task<Void, Never>?
    private var availableCount = 0

    private let redeemSubtitleLabel = UILabel()
    private let redeemFooterHintLabel = UILabel()

    init(voucherService: VoucherService = AppContainer.shared.voucherService) {
        self.voucherService = voucherService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit { loadTask?.cancel() }

    override func setupUI() {
        title = "激活兑换"
        view.backgroundColor = .fdBg
        hidesBottomBarWhenPushed = true

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }

        let heroTitle = UILabel()
        heroTitle.text = "权益卡服务"
        heroTitle.font = .fdH2
        heroTitle.textColor = .fdText

        let heroSub = UILabel()
        heroSub.text = "先绑定企业发放的权益卡，再兑换健康服务套餐。"
        heroSub.font = .fdBody
        heroSub.textColor = .fdText2
        heroSub.numberOfLines = 0

        let hero = UIStackView(arrangedSubviews: [heroTitle, heroSub])
        hero.axis = .vertical
        hero.spacing = 8

        let bindCard = makeActionCard(
            step: "第一步",
            stepColor: .fdPrimary,
            stepBg: .fdSurface,
            icon: "link",
            iconBg: .fdPrimary,
            title: "绑定权益卡",
            subtitle: "输入卡密或扫码，将权益卡放入我的卡券",
            footerHint: "绑定后可兑换服务套餐",
            cta: "去绑定",
            ctaBg: .fdPrimary,
            borderColor: .fdPrimaryEdge,
            action: #selector(tapBind)
        )

        redeemSubtitleLabel.font = .fdCaption
        redeemSubtitleLabel.textColor = .fdText2
        redeemSubtitleLabel.numberOfLines = 0
        redeemFooterHintLabel.font = .fdCaption
        redeemFooterHintLabel.textColor = .fdText2

        let redeemCard = makeActionCard(
            step: "第二步",
            stepColor: .fdInfo,
            stepBg: .fdInfoSoft,
            icon: "bag.fill",
            iconBg: .fdInfo,
            title: "兑换健康服务套餐",
            subtitleView: redeemSubtitleLabel,
            footerHintLabel: redeemFooterHintLabel,
            cta: "去兑换",
            ctaBg: .fdInfo,
            borderColor: UIColor.fdInfo.withAlphaComponent(0.42),
            action: #selector(tapRedeem)
        )

        stack.axis = .vertical
        stack.spacing = 16
        stack.addArrangedSubview(hero)
        stack.setCustomSpacing(20, after: hero)
        stack.addArrangedSubview(bindCard)
        stack.addArrangedSubview(redeemCard)

        scrollView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.width.equalTo(scrollView).offset(-32)
        }

        refreshCountUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            let n = await self.voucherService.refreshAvailableBenefitCount()
            await MainActor.run {
                self.availableCount = n
                self.refreshCountUI()
            }
        }
    }

    private func refreshCountUI() {
        if availableCount > 0 {
            redeemSubtitleLabel.text = "当前有 \(availableCount) 张权益卡可用"
            redeemFooterHintLabel.text = "选择专属健康服务套餐"
        } else {
            redeemSubtitleLabel.text = "暂无可用权益卡，先去绑定"
            redeemFooterHintLabel.text = "可先查看可兑换套餐"
        }
    }

    @objc private func tapBind() {
        Router.shared.push("/activate/bind", from: self)
    }

    @objc private func tapRedeem() {
        Router.shared.push("/activate/redeem", from: self)
    }

    /// 对齐 funde ActivateView：整卡可点（含右侧胶囊视觉区）→ `/activate/bind` | `/activate/redeem`
    private func makeActionCard(
        step: String,
        stepColor: UIColor,
        stepBg: UIColor,
        icon: String,
        iconBg: UIColor,
        title: String,
        subtitle: String? = nil,
        subtitleView: UILabel? = nil,
        footerHint: String? = nil,
        footerHintLabel: UILabel? = nil,
        cta: String,
        ctaBg: UIColor,
        borderColor: UIColor,
        action: Selector
    ) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = borderColor.cgColor
        card.isUserInteractionEnabled = true

        let stepBadge = UILabel()
        stepBadge.text = step
        stepBadge.font = .fdMicro
        stepBadge.textColor = stepColor
        stepBadge.backgroundColor = stepBg
        stepBadge.textAlignment = .center
        stepBadge.layer.cornerRadius = 10
        stepBadge.clipsToBounds = true
        // 包一层：竖向 Stack 用 .fill 时不能直接给徽章定宽，否则与 UISV-alignment 冲突
        let stepRow = UIView()
        stepRow.addSubview(stepBadge)
        stepBadge.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.height.equalTo(20)
            $0.width.equalTo(52)
        }

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        let iconBox = UIView()
        iconBox.backgroundColor = iconBg
        iconBox.layer.cornerRadius = 12
        iconBox.setContentHuggingPriority(.required, for: .horizontal)
        iconBox.setContentCompressionResistancePriority(.required, for: .horizontal)
        iconBox.addSubview(iconView)
        iconView.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(26) }
        iconBox.snp.makeConstraints { $0.size.equalTo(52) }

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .fdH3
        titleLabel.textColor = .fdText

        let subLabel = subtitleView ?? UILabel()
        if let subtitle {
            subLabel.text = subtitle
            subLabel.font = .fdCaption
            subLabel.textColor = .fdText2
            subLabel.numberOfLines = 0
        }

        let bodyText = UIStackView(arrangedSubviews: [titleLabel, subLabel])
        bodyText.axis = .vertical
        bodyText.spacing = 4
        bodyText.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let contentRow = UIStackView(arrangedSubviews: [iconBox, bodyText])
        contentRow.axis = .horizontal
        contentRow.alignment = .center
        contentRow.spacing = 12

        let footerHintLbl = footerHintLabel ?? UILabel()
        if let footerHint {
            footerHintLbl.text = footerHint
            footerHintLbl.font = .fdCaption
            footerHintLbl.textColor = .fdText2
        }
        footerHintLbl.setContentHuggingPriority(.defaultLow, for: .horizontal)
        footerHintLbl.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let ctaLabel = UILabel()
        ctaLabel.text = cta
        ctaLabel.font = .fdCaptionSemibold
        ctaLabel.textColor = .white
        ctaLabel.textAlignment = .center
        ctaLabel.backgroundColor = ctaBg
        ctaLabel.layer.cornerRadius = 18
        ctaLabel.clipsToBounds = true
        ctaLabel.setContentHuggingPriority(.required, for: .horizontal)
        ctaLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        ctaLabel.snp.makeConstraints {
            $0.height.equalTo(36)
            $0.width.greaterThanOrEqualTo(64)
        }

        let footer = UIStackView(arrangedSubviews: [footerHintLbl, ctaLabel])
        footer.axis = .horizontal
        footer.alignment = .center
        footer.distribution = .fill
        footer.spacing = 8

        let divider = UIView()
        divider.backgroundColor = borderColor.withAlphaComponent(0.55)
        divider.snp.makeConstraints { $0.height.equalTo(1) }

        let inner = UIStackView(arrangedSubviews: [stepRow, contentRow, divider, footer])
        inner.axis = .vertical
        inner.alignment = .fill
        inner.spacing = 12
        inner.setCustomSpacing(4, after: stepRow)
        // 关闭内层交互，避免吞掉卡片手势（对齐原型整张 button）
        inner.isUserInteractionEnabled = false

        card.addSubview(inner)
        inner.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        card.snp.makeConstraints { $0.height.greaterThanOrEqualTo(132) }

        let tap = UITapGestureRecognizer(target: self, action: action)
        card.addGestureRecognizer(tap)

        return card
    }
}

// MARK: - 兑换套餐 `/activate/redeem`

/// 兑换套餐专区 — `getRedeemPageInfo` + `getRedeemPackagePage`
final class BenefitRedeemViewController: BaseViewController {

    private let voucherService: VoucherService
    private var loadTask: Task<Void, Never>?
    private var packageTask: Task<Void, Never>?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let hospitalCard = UIView()
    private let hospitalIcon = UIImageView()
    private let hospitalNameLabel = UILabel()
    private let hospitalBadge = UILabel()
    private let hospitalAddressLabel = UILabel()

    private let tabsScroll = UIScrollView()
    private let tabsStack = UIStackView()
    private let hintLabel = UILabel()
    private let packageStack = UIStackView()
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

        contentStack.axis = .vertical
        contentStack.spacing = 16
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.width.equalTo(scrollView).offset(-32)
        }

        setupHospitalCard()
        setupTabs()
        hintLabel.text = "以下套餐可使用权益卡抵扣，具体抵扣金额以兑换页为准"
        hintLabel.font = .fdCaption
        hintLabel.textColor = .fdMuted
        hintLabel.numberOfLines = 0

        packageStack.axis = .vertical
        packageStack.spacing = 12

        emptyMessage.font = .fdCaption
        emptyMessage.textColor = .fdSubtext
        emptyMessage.textAlignment = .center
        emptyMessage.numberOfLines = 0
        emptyCard.backgroundColor = .fdSurface
        emptyCard.layer.cornerRadius = 12
        emptyCard.addSubview(emptyMessage)
        emptyMessage.snp.makeConstraints { $0.edges.equalToSuperview().inset(24) }
        emptyCard.isHidden = true

        loadingIndicator.hidesWhenStopped = true

        contentStack.addArrangedSubview(hospitalCard)
        contentStack.addArrangedSubview(tabsScroll)
        contentStack.addArrangedSubview(hintLabel)
        contentStack.addArrangedSubview(packageStack)
        contentStack.addArrangedSubview(emptyCard)
        contentStack.addArrangedSubview(loadingIndicator)

        tabsScroll.snp.makeConstraints { $0.height.equalTo(36) }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPageInfo()
    }

    private func setupHospitalCard() {
        hospitalCard.backgroundColor = .fdSurface
        hospitalCard.layer.cornerRadius = 12

        hospitalIcon.contentMode = .scaleAspectFill
        hospitalIcon.clipsToBounds = true
        hospitalIcon.layer.cornerRadius = 8
        hospitalIcon.backgroundColor = .fdPrimarySoft
        hospitalIcon.tintColor = .fdPrimary
        hospitalIcon.image = UIImage(systemName: "building.2.fill")
        hospitalIcon.snp.makeConstraints { $0.size.equalTo(36) }

        hospitalNameLabel.font = .fdBodySemibold
        hospitalNameLabel.textColor = .fdText
        hospitalNameLabel.text = "—"

        hospitalBadge.text = "品牌机构"
        hospitalBadge.font = .fdMicro
        hospitalBadge.textColor = .fdPrimary
        hospitalBadge.backgroundColor = .fdPrimarySoft
        hospitalBadge.textAlignment = .center
        hospitalBadge.layer.cornerRadius = 8
        hospitalBadge.clipsToBounds = true
        hospitalBadge.setContentHuggingPriority(.required, for: .horizontal)
        hospitalBadge.snp.makeConstraints { $0.height.equalTo(20); $0.width.greaterThanOrEqualTo(56) }

        let head = UIStackView(arrangedSubviews: [hospitalNameLabel, hospitalBadge])
        head.axis = .horizontal
        head.spacing = 8
        head.alignment = .center

        hospitalAddressLabel.font = .fdCaption
        hospitalAddressLabel.textColor = .fdSubtext
        hospitalAddressLabel.numberOfLines = 2
        hospitalAddressLabel.text = ""

        let textCol = UIStackView(arrangedSubviews: [head, hospitalAddressLabel])
        textCol.axis = .vertical
        textCol.spacing = 4

        let row = UIStackView(arrangedSubviews: [hospitalIcon, textCol])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        hospitalCard.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
    }

    private func setupTabs() {
        tabsScroll.showsHorizontalScrollIndicator = false
        tabsStack.axis = .horizontal
        tabsStack.spacing = 20
        tabsStack.alignment = .center
        tabsScroll.addSubview(tabsStack)
        tabsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
    }

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
        hospitalAddressLabel.text = addr
        if let logo = info.hospitalLogo?.trimmingCharacters(in: .whitespacesAndNewlines),
           !logo.isEmpty,
           let url = URL(string: logo) {
            hospitalIcon.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "building.2.fill"),
                options: [.transition(.fade(0.2))]
            )
        } else {
            hospitalIcon.image = UIImage(systemName: "building.2.fill")
        }
    }

    private func applyHospitalFallback() {
        hospitalNameLabel.text = "富德健康"
        hospitalAddressLabel.text = ""
        hospitalIcon.image = UIImage(systemName: "building.2.fill")
    }

    private func rebuildTabs(categories: [BenefitsRedeemCategoryVO]) {
        tabsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let allBtn = makeTabButton(title: "全部", categoryId: nil)
        tabsStack.addArrangedSubview(allBtn)

        for cat in categories {
            let title = cat.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !title.isEmpty, let id = cat.idString else { continue }
            tabsStack.addArrangedSubview(makeTabButton(title: title, categoryId: id))
        }
        refreshTabSelection()
    }

    private func makeTabButton(title: String, categoryId: String?) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .fdBody
        btn.tag = categoryId == nil ? -1 : (categoryId.hashValue & 0x7FFF_FFFF)
        btn.accessibilityIdentifier = categoryId ?? ""
        btn.addAction(UIAction { [weak self] _ in
            self?.selectedCategoryId = categoryId
            self?.refreshTabSelection()
            self?.reloadPackages(reset: true)
        }, for: .touchUpInside)
        return btn
    }

    private func refreshTabSelection() {
        for case let btn as UIButton in tabsStack.arrangedSubviews {
            let id = btn.accessibilityIdentifier ?? ""
            let selected = (selectedCategoryId == nil && id.isEmpty)
                || (selectedCategoryId != nil && id == selectedCategoryId)
            btn.setTitleColor(selected ? .fdPrimary : .fdText2, for: .normal)
            btn.titleLabel?.font = selected ? .fdBodySemibold : .fdBody
            btn.layer.shadowOpacity = 0
            if selected {
                // underline via bottom border view tag
            }
            btn.subviews.filter { $0.tag == 9901 }.forEach { $0.removeFromSuperview() }
            if selected {
                let line = UIView()
                line.tag = 9901
                line.backgroundColor = .fdPrimary
                btn.addSubview(line)
                line.snp.makeConstraints {
                    $0.leading.trailing.equalToSuperview()
                    $0.bottom.equalToSuperview()
                    $0.height.equalTo(2)
                }
            }
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
            packageStack.addArrangedSubview(makePackageCard(item))
        }
        if hasMore {
            let more = UIButton(type: .system)
            more.setTitle("加载更多", for: .normal)
            more.titleLabel?.font = .fdCaptionSemibold
            more.setTitleColor(.fdPrimary, for: .normal)
            more.addAction(UIAction { [weak self] _ in
                guard let self, self.hasMore, !self.isLoadingPackages else { return }
                self.currentPage += 1
                self.reloadPackages(reset: false)
            }, for: .touchUpInside)
            packageStack.addArrangedSubview(more)
        }
    }

    private func makePackageCard(_ item: BenefitsRedeemPackageItem) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12

        let thumb = UIImageView()
        thumb.contentMode = .scaleAspectFill
        thumb.clipsToBounds = true
        thumb.layer.cornerRadius = 8
        thumb.backgroundColor = .fdPrimarySoft
        thumb.snp.makeConstraints { $0.size.equalTo(64) }
        if let urlStr = item.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
           !urlStr.isEmpty,
           let url = URL(string: urlStr) {
            thumb.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        }

        let title = UILabel()
        title.text = item.displayTitle
        title.font = .fdBodySemibold
        title.textColor = .fdText
        title.numberOfLines = 2

        let sub = UILabel()
        sub.text = item.displaySubtitle
        sub.font = .fdCaption
        sub.textColor = .fdMuted
        sub.numberOfLines = 2
        sub.isHidden = item.displaySubtitle.isEmpty

        let price = UILabel()
        let amount = item.price ?? 0
        price.text = "¥\(Self.formatPrice(amount)) 起"
        price.font = .fdMonoFont(ofSize: 15, weight: .bold)
        price.textColor = .fdPrimary

        let cta = UIButton(type: .system)
        cta.setTitle("去兑换", for: .normal)
        cta.titleLabel?.font = .fdCaptionSemibold
        cta.setTitleColor(.white, for: .normal)
        cta.backgroundColor = .fdPrimary
        cta.layer.cornerRadius = 16
        cta.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        let packageId = item.packageId
        let hospitalId = item.hospitalIdString ?? pageInfo?.hospitalIdString
        cta.addAction(UIAction { _ in
            Router.shared.push(
                "/services/pkg",
                params: ServiceRoutes.packageDetailParams(
                    packageId: packageId,
                    hospitalId: hospitalId
                )
            )
        }, for: .touchUpInside)

        let bottom = UIStackView(arrangedSubviews: [price, UIView(), cta])
        bottom.axis = .horizontal
        bottom.alignment = .center

        let textCol = UIStackView(arrangedSubviews: [title, sub, bottom])
        textCol.axis = .vertical
        textCol.spacing = 6

        let row = UIStackView(arrangedSubviews: [thumb, textCol])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12
        card.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        return card
    }

    private static func formatPrice(_ value: Double) -> String {
        if value == floor(value) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        }
        return String(format: "%g", value)
    }
}
