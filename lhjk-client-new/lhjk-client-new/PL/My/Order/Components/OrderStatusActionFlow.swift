import UIKit

/// 确认发货 / 确认收货 / 退款售后 / 结算订单 — 列表与详情共用
enum OrderStatusActionFlow {

    // MARK: - 列表入口

    static func confirmShipment(from presenter: UIViewController, order: MOrder, onSuccess: @escaping () -> Void) {
        guard let orderId = order.id, orderId > 0 else {
            showToast("订单信息缺失", on: presenter)
            return
        }
        runWithHospitalId(from: presenter, orderId: orderId, order: order) { hospitalId in
            confirmShipment(from: presenter, orderId: orderId, hospitalId: hospitalId, onSuccess: onSuccess)
        }
    }

    static func confirmReceipt(from presenter: UIViewController, order: MOrder, onSuccess: @escaping () -> Void) {
        guard let orderId = order.id, orderId > 0 else {
            showToast("订单信息缺失", on: presenter)
            return
        }
        runWithHospitalId(from: presenter, orderId: orderId, order: order) { hospitalId in
            confirmReceipt(from: presenter, orderId: orderId, hospitalId: hospitalId, onSuccess: onSuccess)
        }
    }

    static func afterSale(from presenter: UIViewController, order: MOrder, onSuccess: @escaping () -> Void) {
        guard let orderId = order.id, orderId > 0 else {
            showToast("订单信息缺失", on: presenter)
            return
        }
        let preview = OrderCancelPackagePreview.from(order: order)
        runWithHospitalId(from: presenter, orderId: orderId, order: order) { hospitalId in
            presentRefundSheet(
                from: presenter,
                orderId: orderId,
                hospitalId: hospitalId,
                preview: preview,
                sheetTitle: "退款/售后",
                successMessage: "已提交退款申请",
                onSuccess: onSuccess
            ) { orderId, hospitalId, remark in
                try await OrderService.shared.submitRefundRequest(
                    orderId: orderId,
                    hospitalId: hospitalId,
                    remark: remark
                )
            }
        }
    }

    static func settle(from presenter: UIViewController, order: MOrder, onSuccess: @escaping () -> Void) {
        guard let orderId = order.id, orderId > 0 else {
            showToast("订单信息缺失", on: presenter)
            return
        }
        let preview = OrderCancelPackagePreview.from(order: order)
        runWithHospitalId(from: presenter, orderId: orderId, order: order) { hospitalId in
            presentSettlementSheet(
                from: presenter,
                orderId: orderId,
                hospitalId: hospitalId,
                preview: preview,
                onSuccess: onSuccess
            )
        }
    }

    // MARK: - 详情入口

    static func confirmShipment(from presenter: UIViewController, detail: AppOrderDetailBO, onSuccess: @escaping () -> Void) {
        guard let orderId = detail.id, orderId > 0,
              let hospitalId = OrderInsertOrEditContext.resolvedHospitalId(from: detail) else {
            showToast("订单信息缺失", on: presenter)
            return
        }
        confirmShipment(from: presenter, orderId: orderId, hospitalId: hospitalId, onSuccess: onSuccess)
    }

    static func confirmReceipt(from presenter: UIViewController, detail: AppOrderDetailBO, onSuccess: @escaping () -> Void) {
        guard let orderId = detail.id, orderId > 0,
              let hospitalId = OrderInsertOrEditContext.resolvedHospitalId(from: detail) else {
            showToast("订单信息缺失", on: presenter)
            return
        }
        confirmReceipt(from: presenter, orderId: orderId, hospitalId: hospitalId, onSuccess: onSuccess)
    }

    static func afterSale(from presenter: UIViewController, detail: AppOrderDetailBO, onSuccess: @escaping () -> Void) {
        guard let orderId = detail.id, orderId > 0,
              let hospitalId = OrderInsertOrEditContext.resolvedHospitalId(from: detail) else {
            showToast("订单信息缺失", on: presenter)
            return
        }
        presentRefundSheet(
            from: presenter,
            orderId: orderId,
            hospitalId: hospitalId,
            preview: OrderCancelPackagePreview.from(detail: detail),
            sheetTitle: "退款/售后",
            successMessage: "已提交退款申请",
            onSuccess: onSuccess
        ) { orderId, hospitalId, remark in
            try await OrderService.shared.submitRefundRequest(
                orderId: orderId,
                hospitalId: hospitalId,
                remark: remark
            )
        }
    }

    static func settle(from presenter: UIViewController, detail: AppOrderDetailBO, onSuccess: @escaping () -> Void) {
        guard let orderId = detail.id, orderId > 0,
              let hospitalId = OrderInsertOrEditContext.resolvedHospitalId(from: detail) else {
            showToast("订单信息缺失", on: presenter)
            return
        }
        presentSettlementSheet(
            from: presenter,
            orderId: orderId,
            hospitalId: hospitalId,
            preview: OrderCancelPackagePreview.from(detail: detail),
            onSuccess: onSuccess
        )
    }

    // MARK: - Private

    private static func confirmShipment(
        from presenter: UIViewController,
        orderId: Int64,
        hospitalId: String,
        onSuccess: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title: "确认发货？",
            message: "确认后订单将进入待收货",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认发货", style: .default) { _ in
            submit(
                from: presenter,
                action: {
                    try await OrderService.shared.confirmShipment(orderId: orderId, hospitalId: hospitalId)
                },
                successMessage: "已确认发货",
                onSuccess: onSuccess
            )
        })
        presenter.present(alert, animated: true)
    }

    private static func confirmReceipt(
        from presenter: UIViewController,
        orderId: Int64,
        hospitalId: String,
        onSuccess: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title: "确认收货？",
            message: "确认收货后服务将开始使用",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认收货", style: .default) { _ in
            submit(
                from: presenter,
                action: {
                    try await OrderService.shared.confirmReceipt(orderId: orderId, hospitalId: hospitalId)
                },
                successMessage: "已确认收货",
                onSuccess: onSuccess
            )
        })
        presenter.present(alert, animated: true)
    }

    private static func presentSettlementSheet(
        from presenter: UIViewController,
        orderId: Int64,
        hospitalId: String,
        preview: OrderCancelPackagePreview,
        onSuccess: @escaping () -> Void
    ) {
        let sheet = OrderSettlementSheet(preview: preview)
        sheet.onSubmit = { remark in
            sheet.setSubmitting(true)
            Task {
                do {
                    try await OrderService.shared.settleOrder(
                        orderId: orderId,
                        hospitalId: hospitalId,
                        remark: remark
                    )
                    await MainActor.run {
                        sheet.setSubmitting(false)
                        sheet.dismiss(animated: true) {
                            notifyRefresh()
                            showToast("已提交结算", on: presenter)
                            onSuccess()
                        }
                    }
                } catch {
                    await MainActor.run {
                        sheet.setSubmitting(false)
                        showToast(error.localizedDescription, on: presenter)
                    }
                }
            }
        }
        presenter.present(sheet, animated: true)
    }

    private static func presentRefundSheet(
        from presenter: UIViewController,
        orderId: Int64,
        hospitalId: String,
        preview: OrderCancelPackagePreview,
        sheetTitle: String,
        successMessage: String,
        onSuccess: @escaping () -> Void,
        submit: @escaping (Int64, String, String) async throws -> Void
    ) {
        let sheet = OrderCancelRefundSheet(preview: preview, sheetTitle: sheetTitle)
        sheet.onSubmit = { remark in
            sheet.setSubmitting(true)
            Task {
                do {
                    try await submit(orderId, hospitalId, remark)
                    await MainActor.run {
                        sheet.setSubmitting(false)
                        sheet.dismiss(animated: true) {
                            notifyRefresh()
                            showToast(successMessage, on: presenter)
                            onSuccess()
                        }
                    }
                } catch {
                    await MainActor.run {
                        sheet.setSubmitting(false)
                        showToast(error.localizedDescription, on: presenter)
                    }
                }
            }
        }
        presenter.present(sheet, animated: true)
    }

    private static func runWithHospitalId(
        from presenter: UIViewController,
        orderId: Int64,
        order: MOrder,
        action: @escaping (String) -> Void
    ) {
        if let hospitalId = OrderInsertOrEditContext.resolvedHospitalId(from: order) {
            action(hospitalId)
            return
        }
        Task {
            do {
                let detail = try await OrderService.shared.getAppOrderDetail(orderId: orderId)
                await MainActor.run {
                    guard let hospitalId = OrderInsertOrEditContext.resolvedHospitalId(from: detail) else {
                        showToast("机构信息缺失", on: presenter)
                        return
                    }
                    action(hospitalId)
                }
            } catch {
                await MainActor.run {
                    showToast(error.localizedDescription, on: presenter)
                }
            }
        }
    }

    private static func submit(
        from presenter: UIViewController,
        action: @escaping () async throws -> Void,
        successMessage: String,
        onSuccess: @escaping () -> Void
    ) {
        Task {
            do {
                try await action()
                await MainActor.run {
                    notifyRefresh()
                    showToast(successMessage, on: presenter)
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    showToast(error.localizedDescription, on: presenter)
                }
            }
        }
    }

    private static func notifyRefresh() {
        NotificationCenter.default.post(name: .orderListNeedsRefresh, object: nil)
    }

    private static func showToast(_ message: String, on presenter: UIViewController) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        presenter.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
