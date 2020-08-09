import Foundation
import ComposableArchitecture
import Networking

public struct Sreality: EstatesProvider {
    public typealias Region = String

    fileprivate static let regions: [String: Region] = [
        "Praha": "10"
//        "Brno": "14"
    ]

//    static func pozemkyUrl(with region: Region) -> URL {
//        return URL(string: "https://www.sreality.cz/api/cs/v2/estates?category_main_cb=3&category_type_cb=1&per_page=100&region_entity_id=\(region)&region_entity_type=municipality")!
//    }
    
    static func domyUrl(with region: Region) -> URL {
        return URL(string: "https://www.sreality.cz/api/cs/v2/estates?category_main_cb=4&category_sub_cb=28%7C30%7C38&category_type_cb=1&locality_region_id=\(region)&per_page=100&tms=1596919167754")!
    }

    public static func exploreEffects(region: Region) -> [Effect<Result<[Estate], Error>>] {
        let makeEffect: (URL, String) -> Effect<Result<[Estate], Error>> = { url, emoji in
            dataTask(with: url)
                .sync()
                .validate()
                .decode(as: Sreality.Response.self)
                .map { result in
                    switch result {
                    case .success(let response):
                        let estates = response._embedded.estates
                            .filter { $0.region_tip == 0 }
                            .map { Estate(title: "\(emoji) " + $0.title, url: $0.url) }
                        return .success(estates)
                    case .failure(let error):
                        return .failure(error)
                    }
                }
        }
        return [
            makeEffect(Sreality.domyUrl(with: Self.regions[region]!), "🏠"),
        ]

    }
}

// MARK: - Model

extension Sreality {

    struct Response: Decodable {
        let _embedded: Embedded

        struct Embedded: Decodable {
            let estates: [SrealityEstate]

            struct SrealityEstate: Decodable {
                let hash_id: Int
                let name: String
                let region_tip: Int
                var title: String { return name }
                var url: String { return "https://www.sreality.cz/detail/prodej/pozemek/bydleni/stochov-stochov-/\(hash_id)" }
            }
        }
    }
}

// MARK: - EstatesProvider

extension EstatesProvider where Self == Sreality {
    public static var providerName: String { "sreality" }
    
    public static var availableRegions: [String] {
        Array(Self.regions.keys)
    }

    public static func isRegionNameValid(_ region: String) -> Bool {
        Self.regions.keys.contains(region)
    }
}
