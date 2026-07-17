import Foundation

// MARK: - 加购 / 立即购买
// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330718e0.md

/// `flag`：2 添加购物车；1 立即购买
enum ShoppingCartActionFlag: Int {
    case purchaseNow = 1
    case addToCart = 2
}

/// `POST /v1/shoppingCart/saveShoppingCartOrPurchase` 请求体 `SaveShoppingCartVO`
struct SaveShoppingCartRequest: Encodable {
    let hospitalId: Int64
    let packageId: Int64
    /// 服务类别 id（必传）
    let categoryServiceId: Int64
    let flag: Int
    let packageHospitalDetailList: [PackageHospitalDetailSubmitItem]

    var doctorId: Int64?
    var userId: Int64?
    var archiveId: Int64?
    var angetId: Int64?
    var parentId: Int64?
    var instruction: String?
    var couponTakeId: Int64?
    var orderChannel: Int?
    var authCode: String?
    var receiver: String?
    var phone: String?
    var address: String?

    enum CodingKeys: String, CodingKey {
        case hospitalId, doctorId, packageId, userId, archiveId
        case categoryServiceId, angetId, flag, parentId, instruction
        case couponTakeId, packageHospitalDetailList, orderChannel
        case authCode, receiver, phone, address
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(hospitalId, forKey: .hospitalId)
        try c.encode(packageId, forKey: .packageId)
        try c.encode(categoryServiceId, forKey: .categoryServiceId)
        try c.encode(flag, forKey: .flag)
        try c.encode(packageHospitalDetailList, forKey: .packageHospitalDetailList)
        try c.encodeIfPresent(doctorId, forKey: .doctorId)
        try c.encodeIfPresent(userId, forKey: .userId)
        try c.encodeIfPresent(archiveId, forKey: .archiveId)
        try c.encodeIfPresent(angetId, forKey: .angetId)
        try c.encodeIfPresent(parentId, forKey: .parentId)
        try c.encodeIfPresent(instruction, forKey: .instruction)
        try c.encodeIfPresent(couponTakeId, forKey: .couponTakeId)
        try c.encodeIfPresent(orderChannel, forKey: .orderChannel)
        try c.encodeIfPresent(authCode, forKey: .authCode)
        try c.encodeIfPresent(receiver, forKey: .receiver)
        try c.encodeIfPresent(phone, forKey: .phone)
        try c.encodeIfPresent(address, forKey: .address)
    }
}

/// 提交用明细（对齐 `PackageHospitalDetailBO`，仅编码有值字段）
struct PackageHospitalDetailSubmitItem: Encodable {
    let id: Int64
    var name: String?
    var quantity: Int?
    var price: Double?
    var billingType: Int?
    var checkType: Int?
    var defaultCheck: Int?
    var parentId: Int64?
    var packageDetailId: Int64?
    var commodityId: Int64?
    var imageUrl: String?
    var saleFlag: Int?
    var categoryId: Int64?
    var categoryName: String?
    var number: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, quantity, price, billingType, checkType, defaultCheck
        case parentId, packageDetailId, commodityId, imageUrl, saleFlag
        case categoryId, categoryName, number
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(quantity, forKey: .quantity)
        try c.encodeIfPresent(price, forKey: .price)
        try c.encodeIfPresent(billingType, forKey: .billingType)
        try c.encodeIfPresent(checkType, forKey: .checkType)
        try c.encodeIfPresent(defaultCheck, forKey: .defaultCheck)
        try c.encodeIfPresent(parentId, forKey: .parentId)
        try c.encodeIfPresent(packageDetailId, forKey: .packageDetailId)
        try c.encodeIfPresent(commodityId, forKey: .commodityId)
        try c.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try c.encodeIfPresent(saleFlag, forKey: .saleFlag)
        try c.encodeIfPresent(categoryId, forKey: .categoryId)
        try c.encodeIfPresent(categoryName, forKey: .categoryName)
        try c.encodeIfPresent(number, forKey: .number)
    }
}

extension ServicePackageComboItem {
    /// 转为加购/下单提交明细；无有效数字 id 时返回 nil
    func toSubmitItem() -> PackageHospitalDetailSubmitItem? {
        guard let id = Int64(detailId.trimmingCharacters(in: .whitespacesAndNewlines)), id > 0 else {
            return nil
        }
        return PackageHospitalDetailSubmitItem(
            id: id,
            name: name,
            quantity: quantityValue,
            price: priceValue,
            billingType: billingType,
            checkType: checkType,
            defaultCheck: defaultCheck ?? (defaultSelected ? 1 : 2),
            parentId: parentDetailId.flatMap { Int64($0) },
            packageDetailId: packageDetailId.flatMap { Int64($0) },
            commodityId: commodityId.flatMap { Int64($0) },
            imageUrl: imageUrl,
            saleFlag: saleFlag,
            categoryId: categoryId.flatMap { Int64($0) },
            categoryName: categoryName,
            number: groupNumber
        )
    }
}

// MARK: - 查询购物车列表
// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330722e0.md

/// `GET /v1/shoppingCart/getShoppingCartList` → `data` 分页
struct PaginatedShoppingCartData: Decodable {
    let totalRecords: Int?
    let pageSize: Int?
    let totalPages: Int?
    let currentPage: Int?
    let records: [ShoppingCartListBO]?

    enum CodingKeys: String, CodingKey {
        case totalRecords = "totalCount"
        case pageSize
        case totalPages = "totalPage"
        case currentPage = "currPage"
        case records = "list"
        case totalRecordsCN = "总记录数"
        case pageSizeCN = "每页记录数"
        case totalPagesCN = "总页数"
        case currentPageCN = "当前页数"
        case recordsCN = "数据集合"
    }

    init(
        totalRecords: Int? = nil,
        pageSize: Int? = nil,
        totalPages: Int? = nil,
        currentPage: Int? = nil,
        records: [ShoppingCartListBO]? = nil
    ) {
        self.totalRecords = totalRecords
        self.pageSize = pageSize
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.records = records
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalRecords = (try? c.decodeIfPresent(Int.self, forKey: .totalRecords))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .totalRecordsCN))
        pageSize = (try? c.decodeIfPresent(Int.self, forKey: .pageSize))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .pageSizeCN))
        totalPages = (try? c.decodeIfPresent(Int.self, forKey: .totalPages))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .totalPagesCN))
        currentPage = (try? c.decodeIfPresent(Int.self, forKey: .currentPage))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .currentPageCN))
        records = (try? c.decodeIfPresent([ShoppingCartListBO].self, forKey: .records))
            ?? (try? c.decodeIfPresent([ShoppingCartListBO].self, forKey: .recordsCN))
    }
}

/// 购物车列表行 `ShoppingCartListBO`
struct ShoppingCartListBO: Decodable {
    let packageId: String
    let packageName: String?
    let hospitalId: String?
    let hospitalName: String?
    let totalQuantity: Int?
    let totalPrice: Double?
    let introduction: String?
    let userId: String?
    let username: String?
    let mobile: String?
    let serialNumber: Int?
    let createTime: String?
    let status: Int?
    let imgUrl: String?
    let type: Int?
    let orderId: String?
    let categoryServiceId: String?

    private enum CodingKeys: String, CodingKey {
        case packageId, packageName, hospitalId, hospitalName
        case totalQuantity, totalPrice, introduction
        case userId, username, mobile, serialNumber, createTime
        case status, imgUrl, type, orderId, categoryServiceId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        packageId = HospitalPackageID.decode(c, key: .packageId)
        packageName = try c.decodeIfPresent(String.self, forKey: .packageName)
        hospitalId = HospitalPackageID.decodeOptional(c, key: .hospitalId)
        hospitalName = try c.decodeIfPresent(String.self, forKey: .hospitalName)
        totalQuantity = HospitalPackageInt.decodeIfPresent(c, key: .totalQuantity)
        totalPrice = try c.decodeIfPresent(Double.self, forKey: .totalPrice)
        introduction = try c.decodeIfPresent(String.self, forKey: .introduction)
        userId = HospitalPackageID.decodeOptional(c, key: .userId)
        username = try c.decodeIfPresent(String.self, forKey: .username)
        mobile = try c.decodeIfPresent(String.self, forKey: .mobile)
        serialNumber = HospitalPackageInt.decodeIfPresent(c, key: .serialNumber)
        createTime = try c.decodeIfPresent(String.self, forKey: .createTime)
        status = HospitalPackageInt.decodeIfPresent(c, key: .status)
        imgUrl = try c.decodeIfPresent(String.self, forKey: .imgUrl)
        type = HospitalPackageInt.decodeIfPresent(c, key: .type)
        orderId = HospitalPackageID.decodeOptional(c, key: .orderId)
        categoryServiceId = HospitalPackageID.decodeOptional(c, key: .categoryServiceId)
    }

    /// 列表行稳定 id（勾选 / 临时删除）
    var lineId: String {
        let serial = serialNumber.map(String.init) ?? ""
        return "\(packageId)_\(hospitalId ?? "")_\(serial)"
    }
}
