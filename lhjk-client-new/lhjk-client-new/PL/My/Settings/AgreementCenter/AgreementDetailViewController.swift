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

    override func setupUI() {
        title = doc.title
        view.backgroundColor = .fdBg

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
            title: "第三方信息共享清单",
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
            intro: "本规则说明权益卡的领取、抵扣、有效期与退款相关约定。",
            updatedAt: "2026-06-25",
            blocks: [
                Block(heading: "一、领取与激活", paragraphs: [
                    "权益卡需在有效期内按页面指引领取或激活，具体以卡面展示规则为准。",
                ]),
                Block(heading: "二、抵扣与退款", paragraphs: [
                    "抵扣范围、叠加规则及退款条件以订单结算页与卡券详情说明为准。",
                ]),
            ]
        ),
    ]
}
