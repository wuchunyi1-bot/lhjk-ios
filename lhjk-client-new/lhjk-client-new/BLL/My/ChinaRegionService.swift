import Foundation

// MARK: - 省市区数据

struct RegionSelection: Equatable {
    var province: String = ""
    var city: String = ""
    var district: String = ""

    var isEmpty: Bool {
        province.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 省 + 市
    var twoLevelDisplay: String {
        joined([province, city])
    }

    /// 省 + 市 + 区
    var threeLevelDisplay: String {
        joined([province, city, district])
    }

    private func joined(_ parts: [String]) -> String {
        parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

private struct ChinaRegionProvinceDTO: Decodable {
    let name: String
    let city: [ChinaRegionCityDTO]
}

private struct ChinaRegionCityDTO: Decodable {
    let name: String
    let area: [String]
}

// MARK: - 中国省市区本地数据

/// 读取 Bundle 内 `map.json`（省 / 市 / 区三级）
final class ChinaRegionService {

    static let shared = ChinaRegionService()

    private var provinces: [ChinaRegionProvinceDTO] = []
    private var isLoaded = false

    private init() {}

    func loadIfNeeded() {
        guard !isLoaded else { return }
        guard let url = Bundle.main.url(forResource: "map", withExtension: "json") else {
            print("[ChinaRegion] map.json not found in bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            provinces = try JSONDecoder().decode([ChinaRegionProvinceDTO].self, from: data)
            isLoaded = true
            print("[ChinaRegion] loaded provinces=\(provinces.count)")
        } catch {
            print("[ChinaRegion] decode failed: \(error.localizedDescription)")
        }
    }

    func provinceNames() -> [String] {
        loadIfNeeded()
        return provinces.map(\.name)
    }

    func cityNames(provinceIndex: Int) -> [String] {
        loadIfNeeded()
        guard provinces.indices.contains(provinceIndex) else { return [] }
        let names = provinces[provinceIndex].city.map(\.name)
        return names.isEmpty ? [""] : names
    }

    func districtNames(provinceIndex: Int, cityIndex: Int) -> [String] {
        loadIfNeeded()
        guard provinces.indices.contains(provinceIndex) else { return [""] }
        let cities = provinces[provinceIndex].city
        guard cities.indices.contains(cityIndex) else { return [""] }
        let names = cities[cityIndex].area
        return names.isEmpty ? [""] : names
    }

    func provinceIndex(for name: String?) -> Int {
        loadIfNeeded()
        let key = normalized(name)
        guard !key.isEmpty else { return 0 }
        return provinces.firstIndex { normalized($0.name) == key } ?? 0
    }

    func cityIndex(provinceIndex: Int, cityName: String?) -> Int {
        loadIfNeeded()
        let names = cityNames(provinceIndex: provinceIndex)
        let key = normalized(cityName)
        guard !key.isEmpty else { return 0 }
        return names.firstIndex { normalized($0) == key } ?? 0
    }

    func districtIndex(provinceIndex: Int, cityIndex: Int, districtName: String?) -> Int {
        loadIfNeeded()
        let names = districtNames(provinceIndex: provinceIndex, cityIndex: cityIndex)
        let key = normalized(districtName)
        guard !key.isEmpty else { return 0 }
        return names.firstIndex { normalized($0) == key } ?? 0
    }

    func selection(
        provinceIndex: Int,
        cityIndex: Int,
        districtIndex: Int,
        includeDistrict: Bool
    ) -> RegionSelection {
        loadIfNeeded()
        guard provinces.indices.contains(provinceIndex) else { return RegionSelection() }
        let province = provinces[provinceIndex]
        let cities = province.city
        let city = cities.indices.contains(cityIndex) ? cities[cityIndex] : cities.first
        let cityName = city?.name ?? ""
        let district: String
        if includeDistrict, let city {
            let areas = city.area
            district = areas.indices.contains(districtIndex) ? areas[districtIndex] : areas.first ?? ""
        } else {
            district = ""
        }
        return RegionSelection(province: province.name, city: cityName, district: district)
    }

    /// 把定位返回的省市区对齐到 `map.json` 的名称，用来回填「所在地区」。
    func matchedSelection(province: String, city: String, district: String, addressText: String) -> RegionSelection? {
        loadIfNeeded()
        guard !provinces.isEmpty else { return nil }
        guard let provinceDTO = best(provinces, name: \.name, hint: province, blob: addressText) else { return nil }
        let cityDTO = best(provinceDTO.city, name: \.name, hint: city, blob: addressText)
            ?? best(provinceDTO.city, name: \.name, hint: district, blob: "")
        let districtName = cityDTO.flatMap { best($0.area, name: { $0 }, hint: district, blob: addressText) } ?? ""
        let selection = RegionSelection(
            province: provinceDTO.name,
            city: cityDTO?.name ?? "",
            district: districtName
        )
        guard !selection.province.isEmpty else { return nil }
        return selection
    }

    private func best<T>(_ items: [T], name: (T) -> String, hint: String, blob: String) -> T? {
        let hintKey = regionKey(hint)
        if !hintKey.isEmpty {
            if let exact = items.first(where: { regionKey(name($0)) == hintKey }) { return exact }
            if let contained = items.first(where: { item in
                let key = regionKey(name(item))
                return key.count >= 2 && (hintKey.contains(key) || key.contains(hintKey))
            }) { return contained }
        }
        let text = blob.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        return items
            .sorted { name($0).count > name($1).count }
            .first { item in
                let official = name(item)
                let key = regionKey(official)
                return text.contains(official) || (key.count >= 2 && text.contains(key))
            }
    }

    /// 去掉「省 / 市 / 区」等后缀后再比较，兼容定位文案和本地数据。
    private func regionKey(_ value: String) -> String {
        var text = normalized(value)
        let suffixes = ["特别行政区", "维吾尔自治区", "回族自治区", "壮族自治区", "自治区", "自治州", "地区", "省", "市", "区", "县"]
        for suffix in suffixes where text.hasSuffix(suffix) && text.count > suffix.count {
            text.removeLast(suffix.count)
            break
        }
        return text
    }

    private func normalized(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
