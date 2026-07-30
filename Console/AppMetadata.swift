import Foundation

struct AppMetadata: Decodable {
    let name: String
    let shortName: String
    let description: String
    let themeColor: String

    static let current: AppMetadata = {
        guard let url = Bundle.main.url(forResource: "app-metadata", withExtension: "json"),
              let metadata = try? Data(contentsOf: url),
              let appMetadata = try? JSONDecoder().decode(AppMetadata.self, from: metadata) else {
            preconditionFailure("Unable to load app-metadata.json")
        }

        return appMetadata
    }()

    enum CodingKeys: String, CodingKey {
        case name
        case shortName = "short_name"
        case description
        case themeColor = "theme_color"
    }
}
