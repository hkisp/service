import Foundation

enum AppGroup {
    static let id = "group.com.danny.idcxray"
    static let nodesKey = "nodes_json"
    static let activeURIKey = "active_uri"
    static let tunnelStatusKey = "tunnel_status"
    static let lastErrorKey = "last_error"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: id) ?? .standard
    }

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
    }
}
