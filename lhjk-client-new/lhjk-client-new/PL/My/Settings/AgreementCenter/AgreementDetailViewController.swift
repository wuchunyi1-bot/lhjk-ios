import UIKit
import SnapKit

/// 协议详情只读页 — 对齐 AgreementView.vue `/auth/agreement/:docType`
final class AgreementDetailViewController: BaseViewController {

    struct Block {
        let heading: String
        let paragraphs: [String]
    }

    struct Doc {
        let title: String
        let intro: String
        let updatedAt: String
        let blocks: [Block]
    }

    private let docType: String
    private let doc: Doc

    init(docType: String) {
        self.docType = docType
        self.doc = Self.doc(for: docType)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    /// 登录等无导航栈场景：以独立 Nav present 本页
    static func present(from presenter: UIViewController, docType: String) {
        let detail = AgreementDetailViewController(docType: docType)
        let nav = UINavigationController(rootViewController: detail)
        presenter.present(nav, animated: true)
    }

    override func setupUI() {
        title = doc.title
        view.backgroundColor = .fdBg
        if navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "关闭",
                style: .plain,
                target: self,
                action: #selector(dismissPresented)
            )
        }

        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        view.addSubview(scroll)
        scroll.snp.makeConstraints { $0.edges.equalToSuperview() }

        let content = UIView()
        scroll.addSubview(content)
        content.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        content.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-24)
        }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let intro = UILabel()
        intro.text = doc.intro
        intro.font = .fdMyBody
        intro.textColor = .fdText
        intro.numberOfLines = 0
        stack.addArrangedSubview(intro)

        let updated = UILabel()
        updated.text = "更新日期：\(doc.updatedAt)"
        updated.font = .fdMyCaption
        updated.textColor = .fdSubtext
        stack.addArrangedSubview(updated)

        for block in doc.blocks {
            let heading = UILabel()
            heading.text = block.heading
            heading.font = .fdMyBodySemibold
            heading.textColor = .fdText
            heading.numberOfLines = 0
            stack.addArrangedSubview(heading)

            for p in block.paragraphs {
                let body = UILabel()
                body.text = p
                body.font = .fdMyBody
                body.textColor = .fdSubtext
                body.numberOfLines = 0
                stack.addArrangedSubview(body)
            }
        }
    }

    @objc private func dismissPresented() {
        dismiss(animated: true)
    }

    // MARK: - Static docs（对齐 Vue agreementMap；未知类型回退 user）

    private static func doc(for type: String) -> Doc {
        docs[type] ?? docs["user"]!
    }

    private static let docs: [String: Doc] = [
        "user": Doc(
            title: "用户协议",
            intro: "本协议用于说明您在使用富德联好健康平台账号、服务预约、健康档案与消息沟通功能时的基本权利义务。",
            updatedAt: "2026-06-25",
            blocks: [
                Block(heading: "一、服务范围", paragraphs: [
                    "富德联好健康为您提供账号登录、健康数据查看、服务预约、消息沟通、保单权益查询等线上服务，具体以页面展示和实际开通权益为准。",
                    "您理解并同意，部分健康管理服务需要结合线下履约、保险权益或第三方服务能力完成，页面展示不构成医疗诊断结论。",
                ]),
                Block(heading: "二、账号使用", paragraphs: [
                    "您应当使用本人手机号或经授权的身份信息完成注册、登录与实名校验，并妥善保管验证码、密码及登录设备。",
                    "若发现账号被冒用、异常登录或重要资料被篡改，请及时通过平台客服或安全入口进行处理。",
                ]),
                Block(heading: "三、服务规范", paragraphs: [
                    "您在平台提交的健康信息、问诊描述、预约资料应当真实、准确、完整，不得冒用他人身份或提交虚假材料。",
                ]),
                Block(heading: "四、责任说明", paragraphs: [
                    "平台提供的健康建议、科普内容与风险评估结果主要用于健康管理参考，不能替代医生面对面诊疗意见。",
                ]),
            ]
        ),
        "privacy": Doc(
            title: "隐私政策",
            intro: "本政策用于说明平台如何收集、使用、存储、共享和保护您的个人信息与健康数据。",
            updatedAt: "2026-06-25",
            blocks: [
                Block(heading: "一、信息收集", paragraphs: [
                    "在您登录、建档、预约、激活权益或使用健康管理服务时，我们会收集手机号、姓名、性别、年龄、设备信息、服务记录及必要的健康指标数据。",
                ]),
                Block(heading: "二、信息使用", paragraphs: [
                    "收集的信息主要用于身份验证、服务履约、健康档案管理、消息通知、安全风控、服务改进与合规留痕。",
                ]),
                Block(heading: "三、信息共享", paragraphs: [
                    "仅在为您完成体检预约、健康咨询、保单权益履约、客服处理等必要场景下，我们才会向对应合作方提供最小必要的信息。",
                ]),
            ]
        ),
        "consent": Doc(
            title: "健康管理服务知情同意书",
            intro: "本知情同意书用于说明健康管理服务的告知事项、授权范围与您的权利。",
            updatedAt: "2026-06-25",
            blocks: [
                Block(heading: "一、服务告知", paragraphs: [
                    "健康管理服务可能包括健康评估、指标监测、随访提醒、生活方式建议及与健管师的沟通支持。",
                ]),
                Block(heading: "二、授权内容", paragraphs: [
                    "您授权平台在履约所需范围内处理相关健康信息，并在必要时与服务团队共享最小必要数据。",
                ]),
            ]
        ),
        "personal-info": Doc(
            title: "个人信息收集清单",
            intro: "本清单说明我们收集的信息类型、使用目的与方式。",
            updatedAt: "2026-06-25",
            blocks: [
                Block(heading: "一、账号信息", paragraphs: [
                    "手机号、微信授权信息、头像/昵称等，用于注册登录与身份识别。",
                ]),
                Block(heading: "二、健康信息", paragraphs: [
                    "健康档案数据、指标测量记录、体检报告等，用于健康管理服务履约。",
                ]),
                Block(heading: "三、服务信息", paragraphs: [
                    "订单与交易记录、服务履约记录、咨询交流记录等，用于服务交付与售后。",
                ]),
            ]
        ),
        "third-party-sharing": Doc(
            title: "第三方信息收集清单",
            intro: "本清单说明可能涉及的第三方服务、共享信息与使用目的。",
            updatedAt: "2026-06-25",
            blocks: [
                Block(heading: "一、第三方 SDK", paragraphs: [
                    "微信 SDK（登录/支付）、推送 SDK、支付宝 SDK 等，仅在对应功能启用时使用。",
                ]),
                Block(heading: "二、共享原则", paragraphs: [
                    "仅在必要情况下与第三方共享脱敏或最小化信息，并要求其履行保密义务。",
                ]),
            ]
        ),
        "benefit-card": Doc(
            title: "权益卡使用规则",
            intro: "请您在绑定或领取权益卡前完整阅读本规则。本规则以问答形式逐条写明，每条问答都是规则正文。您勾选「我已阅读并同意《权益卡使用规则》」并完成绑定或领取，即表示已阅读并同意本规则的全部内容。",
            updatedAt: "2026-09-10",
            blocks: [
                Block(heading: "一、认识权益卡", paragraphs: [
                    "1. 什么是权益卡？",
                    "权益卡是本平台发行的优惠凭证，和优惠券同类，用来抵扣或兑换指定健康服务套餐。它不是储值卡：卡面金额不是账户余额，不能充值、提现、转账，不能兑换现金，也不能找零。",
                    "2. 权益卡的面值、有效期和适用套餐以什么为准？",
                    "以卡面（或电子凭证）、「我的卡券」、兑换页和确认订单页当时展示的内容为准。",
                ]),
                Block(heading: "二、绑定与领取", paragraphs: [
                    "3. 怎样获得权益卡？",
                    "两种方式：输入卡密或扫码，把卡绑定到您本人已登录的账号；或者领取他人转赠给您的卡。绑定或领取前，须先阅读并同意本规则。扫码只是识别卡密或领取信息，经您确认后卡才会进入卡包。",
                    "4. 一张卡能绑定几次？绑定后能解绑吗？",
                    "一张权益卡只能绑定一次。已绑定、已过期或凭证无效的，不能绑定。绑定成功后不能解绑，也不能改绑到其他账号。",
                    "5. 绑定或领取成功后，在哪里查看？",
                    "打开「我的 → 我的卡券」即可查看。",
                    "6. 卡密丢失或泄露了怎么办？",
                    "请妥善保管卡密等凭证。凭证一旦被他人绑定，就不能再绑定到您的账号，平台不补发、不挂失。",
                ]),
                Block(heading: "三、使用", paragraphs: [
                    "7. 哪些套餐可以使用权益卡？",
                    "待使用、未过期且未处于等待领取状态的权益卡，可以兑换适用套餐，也可以在下单时抵扣套餐金额。能不能用、能抵多少，以您使用当时页面展示为准。",
                    "8. 一张卡能用几次？没抵完的面值怎么办？",
                    "一张权益卡支付成功后只能使用一次。没抵完的面值不退回、不找零，也不能留到下次再用。",
                    "9. 权益卡能和优惠券一起用吗？能抵运费吗？",
                    "可以一起用。同一订单可同时使用一张优惠券和多张适用权益卡：优惠券先抵扣，权益卡再抵扣剩余的套餐金额。权益卡不抵扣运费。",
                    "10. 什么时候算使用完成？",
                    "待支付订单只保存您的选择，不占用权益卡；支付成功后才核销。抵扣后应付金额为 0 元的，仍须按页面提示完成支付确认，订单才生效。",
                    "11. 权益卡过期了还能用吗？",
                    "不能。超过有效期，权益卡即失效，不可再使用。",
                ]),
                Block(heading: "四、转赠", paragraphs: [
                    "12. 权益卡可以转赠吗？",
                    "待使用、未过期且未处于等待领取状态的权益卡可以转赠。转出后不可撤回，请在赠送前确认。",
                    "13. 对方一直不领取怎么办？",
                    "经平台转赠或发放的权益卡，须在页面展示的时限内领取；超时未领取的，卡原路退回，有效期不变。",
                    "14. 等待对方领取期间，这张卡还能用吗？",
                    "不能。等待领取期间，该卡不可兑换，也不可再次转赠。",
                    "15. 领取别人转赠的卡后，还能再转赠吗？",
                    "可以。领取成功后，权益卡归您持有，可以再次转赠，次数不限。",
                ]),
                Block(heading: "五、退款与退卡", paragraphs: [
                    "16. 权益卡能退成现金吗？",
                    "不能。权益卡不因退卡向您返还现金。",
                    "17. 用权益卡兑换或抵扣的套餐退款了，卡怎么办？",
                    "该卡是否退回您的卡包，由人工审核确定：退回的是卡，不是现金；未获准退回的，卡保持已使用状态。审核结果以订单或售后页面展示为准。审核同意退回的，退回的仍是原卡，到期日不变，不因退回而延长。尚未支付成功、权益卡未核销的，卡仍可使用；若此时已过期，按过期处理。",
                ]),
                Block(heading: "六、其他", paragraphs: [
                    "18. 在哪里查询权益卡？有问题找谁？",
                    "在「我的卡券」可查询权益卡状态。如有疑问，或对绑定、核销、退回结果有异议，请联系平台客服或致电 0755-61909838，核实后按实际情况处理。",
                    "19. 使用权益卡有哪些禁止行为？",
                    "不得倒卖、冒用或伪造卡密，不得将权益卡用于违法违规用途。",
                    "20. 权益卡兑换的套餐开发票吗？",
                    "不开发票。",
                ]),
                Block(heading: "七、规则修订与争议解决", paragraphs: [
                    "21. 本规则会变更吗？",
                    "平台可根据实际经营情况修订本规则，修订内容将在正式生效前至少 7 日通过 App 或小程序页面公示，公示期满后依法生效。您对修订内容有异议的，可在生效日前停止使用权益卡；生效后继续绑定、领取或使用的，视为已接受修订后的规则。",
                    "22. 发生争议如何解决？",
                    "本规则的订立、执行与解释均适用中华人民共和国法律。因本规则产生的争议，双方应友好协商解决；协商不成的，任何一方可依法向有管辖权的人民法院提起诉讼。",
                ]),
            ]
        ),
        "member-service": Doc(
            title: "会员服务协议",
            intro: "本协议用于说明富德联好健康会员等级、虚拟币、积分及会员兑换服务的规则。请您在使用会员服务前审慎阅读、充分理解本协议各条款内容。",
            updatedAt: "2026-09-10",
            blocks: [
                Block(heading: "一、会员等级介绍", paragraphs: [
                    "本平台会员分为 5 个等级，根据会员累计获得的虚拟币划分：V1 健康体验官（注册即享）、V2 健康银卡会员（累计虚拟币 ≥ 500）、V3 健康金卡会员（≥ 2,000）、V4 健康铂金会员（≥ 8,000）、V5 健康钻石会员（≥ 30,000）。",
                    "不同等级会员享有不同的兑换资格与会员权益，等级越高，可兑换的商品范围越丰富，具体以平台页面公示为准。",
                ]),
                Block(heading: "二、虚拟币定义", paragraphs: [
                    "虚拟币是本平台根据会员实际现金消费授予的会员成长资产，分为两个独立账户：累计虚拟币用于计算和确定会员等级，持续累计（发生退款扣回、违规处理或账号注销的情形除外）；可用虚拟币用于会员兑换，兑换成功后相应扣减。",
                    "会员兑换消耗可用虚拟币，不影响累计虚拟币的计算，也不影响当前会员等级。",
                ]),
                Block(heading: "三、虚拟币获取规则", paragraphs: [
                    "会员注册后，在平台购买商品或服务且订单完成后，系统按该订单的实际现金支付金额即时发放虚拟币：每实际现金消费 1 元可获得 n 虚拟币（返币比例以平台页面公示为准），不足 1 元的部分四舍五入计算。",
                    "【举例】订单商品金额 99.6 元，使用优惠券抵扣 20 元，实际现金支付 79.6 元，四舍五入后按 80 元计算，可获得 80 × n 虚拟币。",
                    "以下金额不计入虚拟币计算：（一）权益卡抵扣金额；（二）优惠券抵扣金额；（三）积分抵扣金额；（四）虚拟币抵扣金额；（五）运费金额；（六）已发生退款的金额。",
                ]),
                Block(heading: "四、会员等级累计与升降级", paragraphs: [
                    "持续累计：会员等级依据累计虚拟币确定。自会员注册后的第一笔消费起，累计虚拟币持续累加、不设时间窗口、不因时间经过而减少（本协议约定的退款扣回、违规处理或账号注销情形除外）。",
                    "只升不降：累计虚拟币达到更高等级门槛时，系统即时自动升级，无需会员操作。会员使用等级权益、使用可用虚拟币兑换商品，均不影响累计虚拟币，也不会导致等级下降。",
                    "退款重算（唯一的降级情形）：订单退款完成后，系统扣回该订单已发放的虚拟币——整单退款的，扣回该单全部虚拟币；部分退款的，按退款金额对应扣减（不足 1 元部分向下取整）。因退款意味着该笔消费及其对应权益被收回，若扣回后累计虚拟币低于当前等级门槛，会员等级将按剩余累计虚拟币重新计算，可能出现降级。",
                    "不追溯追回：退款扣回前会员已使用可用虚拟币兑换的商品，平台不予追回；若扣回时可用虚拟币余额不足，余额将相应减少至负数，后续获得的虚拟币优先补足负值部分。",
                ]),
                Block(heading: "五、虚拟币有效期", paragraphs: [
                    "可用虚拟币自获得之日起一年（365 天）内有效，按自然日滚动过期，到期未使用的部分自动失效；系统按获得时间先后，优先扣减先到期的部分。",
                    "【举例】2026 年 4 月 16 日 12:01 获得的虚拟币，将于 2027 年 4 月 16 日 12:01 到期失效。",
                    "上述有效期适用于全部来源的虚拟币（含消费获得、活动获得等）。用于确定会员等级的累计虚拟币不受有效期限制，自第一笔消费起持续累计，仅因退款扣回、违规处理或账号注销而减少。",
                    "虚拟币余额、明细及到期情况可在「我的-会员兑换/等级成长」页面查询。",
                ]),
                Block(heading: "六、积分获取", paragraphs: [
                    "会员可通过完成平台发布的活动任务获得积分，任务类型包括但不限于：注册账号、完善健康档案、记录健康数据（如体征、饮食、运动等）、上传健康报告、阅读健康内容、参与平台活动等。",
                    "各项任务的具体内容、可获得的积分数量及领取次数限制，以平台页面公示为准。任务完成后积分自动发放至会员账户。",
                    "平台可根据运营需要调整任务种类、积分数量及领取规则，调整前将通过页面公示等方式通知会员。",
                ]),
                Block(heading: "七、积分使用与有效期", paragraphs: [
                    "积分可用于会员兑换。兑换时系统校验积分余额，余额充足即可兑换，不校验会员等级。",
                    "积分扣减情形包括：（一）兑换商品或服务；（二）有效期届满自动失效；（三）违规扣减（见第九条）。",
                    "积分自获得之日起一年（365 天）内有效，按自然日滚动过期，过期积分自动失效；系统按获得时间先后，优先扣减先到期的部分。【举例】2026 年 4 月 16 日 12:01 获得的积分，将于 2027 年 4 月 16 日 12:01 到期失效。",
                    "上述有效期适用于全部来源的积分（含活动任务获得、活动获得等）。积分余额及明细可在「我的-积分明细」页面查询。",
                ]),
                Block(heading: "八、会员兑换规则", paragraphs: [
                    "会员兑换是积分与虚拟币的使用场景，可兑换范围包括：实物商品、优惠券、权益卡、健康服务体验，具体以兑换页面展示为准。",
                    "兑换方式：每件商品仅支持单一资产兑换，即「积分兑换」或「虚拟币兑换」二选一，不支持积分与虚拟币组合支付。",
                    "兑换校验：（一）积分兑换：积分余额不低于商品所需积分即可兑换；（二）虚拟币兑换：需同时满足两个条件——①可用虚拟币余额充足；②当前会员等级达到商品标注的解锁等级。等级不足时，即使虚拟币余额充足亦无法兑换，页面将展示所需解锁等级（如「V2 解锁」）。",
                    "兑换商品的库存、每人限兑数量以页面展示为准，库存有限，兑完即止。",
                    "退换规则：兑换商品非因质量问题不支持退货、换货；如商品存在质量问题，可联系平台客服处理换货，或退回兑换所扣的积分/虚拟币。虚拟类商品（优惠券、权益卡）一经兑换发放，不支持退换。",
                ]),
                Block(heading: "九、资产性质、发票与违规处理", paragraphs: [
                    "积分与虚拟币均为平台授予会员的虚拟资产，不具有货币属性：不可提现、不可转让、不可兑换现金；二者相互独立，不可相互转换；仅可用于平台会员兑换。以积分或虚拟币兑换的部分，平台不单独开具发票。",
                    "会员等级、积分、虚拟币及相关权益仅限会员本人享有，不得转卖或转借他人；因转卖、转借造成的个人信息泄露和资金安全风险由会员本人承担，平台有权作废或收回相关等级与权益。",
                    "如会员通过虚假交易、伪造信息、利用系统漏洞等不正当手段获取虚拟币、积分或其他会员权益，平台有权根据违规情节采取以下措施：取消相关订单的虚拟币与积分、作废已通过违规手段兑换但尚未使用的权益、冻结账户、暂停部分或全部会员权益；情节严重的，平台有权追究法律责任。会员对扣减有异议的，可联系平台客服或致电 0755-61909838 提交凭证申诉，平台核实后将根据实际情况处理。",
                    "会员注销账号的，账户内累计/可用虚拟币与积分将全部清零且不可恢复；注销后可按平台规则重新注册。",
                ]),
                Block(heading: "十、规则修订与生效", paragraphs: [
                    "在法律法规允许的范围内，平台可根据实际经营情况对本协议进行修订，修订内容将在正式生效前至少 7 日通过 App/小程序页面公示，公示期满后依法生效。若您对修订内容有异议，有权在生效日前联系我们终止会员服务；若您在生效后继续使用会员服务，即视为已接受修订后的协议。",
                    "本协议自 2026 年 xx 月 xx 日起生效。",
                    "本协议的订立、执行与解释均适用中华人民共和国法律。因本协议产生的争议，双方应友好协商解决；协商不成的，任何一方可向本平台所在地有管辖权的人民法院提起诉讼。",
                ]),
            ]
        ),
    ]
}
