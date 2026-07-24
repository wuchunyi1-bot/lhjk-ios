import UIKit

/// 取消订单统一交互 — 列表与详情共用
enum OrderCancelFlow {

    enum Result {
        case cancelled
        case refundSubmitted
    }

    /// 从列表订单发起取消
    static func start(from presenter: UIViewController, order: MOrder, onSuccess: @escaping (Result) -> Void) {
        guard let orderId = order.id, orderId > 0, let status = order.orderStatus else {
            showToast("订单信息缺失", on: presenter)
            return
        }
        let preview = OrderCancelPackagePreview.from(order: order)
        let hospitalId = OrderInsertOrEditContext.resolvedHospitalId(from: order)
        start(
            from: presenter,
            orderId: orderId,
            hospitalId: hospitalId,
            status: status,
            preview: preview,
            onSuccess: onSuccess
        )
    }

    /// 从详情发起取消
    static func start(from presenter: UIViewController, detail: AppOrderDetailBO, onSuccess: @escaping (Result) -> Void) {
        guard let orderId = detail.id, orderId > 0, let status = detail.orderStatus else {
            showToast("订单信息缺失", on: presenter)
            return
        }
        let preview = OrderCancelPackagePreview.from(detail: detail)
        let hospitalId = OrderInsertOrEditContext.resolvedHospitalId(from: detail)
        start(
            from: presenter,
            orderId: orderId,
            hospitalId: hospitalId,
            status: status,
            preview: preview,
            onSuccess: onSuccess
        )
    }

    // MARK: - Private

    private static func start(
        from presenter: UIViewController,
        orderId: Int64,
        hospitalId: String?,
        status: AppOrderStatus,
        preview: OrderCancelPackagePreview,
        onSuccess: @escaping (Result) -> Void
    ) {
        switch status {
        case .pendingPayment:
            confirmPendingPaymentCancel(
                from: presenter,
                orderId: orderId,
                hospitalId: hospitalId,
                onSuccess: onSuccess
            )
        case .pendingShip:
            confirmPendingShipCancel(
                from: presenter,
                orderId: orderId,
                hospitalId: hospitalId,
                preview: preview,
                onSuccess: onSuccess
            )
        default:
            showToast("当前订单状态不支持取消", on: presenter)
        }
    }

    private static func confirmPendingPaymentCancel(
        from presenter: UIViewController,
        orderId: Int64,
        hospitalId: String?,
        onSuccess: @escaping (Result) -> Void
    ) {
        let alert = UIAlertController(
            title: "取消订单？",
            message: "取消后可重新购买",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "暂不取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认取消", style: .destructive) { _ in
            submitPendingPaymentCancel(
                from: presenter,
                orderId: orderId,
                hospitalId: hospitalId,
                onSuccess: onSuccess
            )
        })
        presenter.present(alert, animated: true)
    }

    private static func confirmPendingShipCancel(
        from presenter: UIViewController,
        orderId: Int64,
        hospitalId: String?,
        preview: OrderCancelPackagePreview,
        partialShipped: Bool = false,
        onSuccess: @escaping (Result) -> Void
    ) {
        let title = partialShipped ? "部分商品已发货" : "确认取消订单？"
        let message = partialShipped
            ? "订单中有商品正在配送。继续取消后，未发货商品将停止发货；退款申请将进入平台审核。"
            : "取消后订单将进入退款审核，是否确认取消？"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: partialShipped ? "暂不取消" : "再想想", style: .cancel))
        alert.addAction(UIAlertAction(title: partialShipped ? "继续取消" : "确认取消", style: .destructive) { _ in
            presentRefundSheet(
                from: presenter,
                orderId: orderId,
                hospitalId: hospitalId,
                preview: preview,
                onSuccess: onSuccess
            )
        })
        presenter.present(alert, animated: true)
    }

    private static func presentRefundSheet(
        from presenter: UIViewController,
        orderId: Int64,
        hospitalId: String?,
        preview: OrderCancelPackagePreview,
        onSuccess: @escaping (Result) -> Void
    ) {
        let sheet = OrderCancelRefundSheet(preview: preview)
        sheet.onSubmit = { reason in
            submitPendingShipRefund(
                from: presenter,
                sheet: sheet,
                orderId: orderId,
                hospitalId: hospitalId,
                remark: reason,
                onSuccess: onSuccess
            )
        }
        presenter.present(sheet, animated: true)
    }

    private static func submitPendingPaymentCancel(
        from presenter: UIViewController,
        orderId: Int64,
        hospitalId: String?,
        onSuccess: @escaping (Result) -> Void
    ) {
        resolveHospitalId(
            from: presenter,
            orderId: orderId,
            hospitalId: hospitalId
        ) { hid in
            Task {
                do {
                    try await OrderService.shared.cancelPendingPaymentOrder(orderId: orderId, hospitalId: hid)
                    await MainActor.run {
                        notifyListRefresh()
                        showToast("订单已取消", on: presenter)
                        onSuccess(.cancelled)
                    }
                } catch {
                    await MainActor.run {
                        showToast(error.localizedDescription, on: presenter)
                    }
                }
            }
        }
    }

    private static func submitPendingShipRefund(
        from presenter: UIViewController,
        sheet: OrderCancelRefundSheet,
        orderId: Int64,
        hospitalId: String?,
        remark: String,
        onSuccess: @escaping (Result) -> Void
    ) {
        resolveHospitalId(
            from: presenter,
            orderId: orderId,
            hospitalId: hospitalId
        ) { hid in
            sheet.setSubmitting(true)
            Task {
                do {
                    try await OrderService.shared.submitPendingShipCancelRefund(
                        orderId: orderId,
                        hospitalId: hid,
                        remark: remark
                    )
                    await MainActor.run {
                        sheet.setSubmitting(false)
                        sheet.dismiss(animated: true) {
                            notifyListRefresh()
                            showToast("已提交退款审核", on: presenter)
                            onSuccess(.refundSubmitted)
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
    }

    private static func resolveHospitalId(
        from presenter: UIViewController,
        orderId: Int64,
        hospitalId: String?,
        onResolved: @escaping (String) -> Void
    ) {
        if let hospitalId, !hospitalId.isEmpty {
            onResolved(hospitalId)
            return
        }
        Task {
            do {
                let detail = try await OrderService.shared.getAppOrderDetail(orderId: orderId)
                await MainActor.run {
                    guard let hid = OrderInsertOrEditContext.resolvedHospitalId(from: detail) else {
                        showToast("机构信息缺失", on: presenter)
                        return
                    }
                    onResolved(hid)
                }
            } catch {
                await MainActor.run {
                    showToast(error.localizedDescription, on: presenter)
                }
            }
        }
    }

    private static func notifyListRefresh() {
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
