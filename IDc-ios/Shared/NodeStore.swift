import Foundation
import Combine

@MainActor
final class NodeStore: ObservableObject {
    @Published private(set) var nodes: [VlessNode] = []
    @Published var activeURI: String = ""
    @Published var statusMessage: String = "未连接"
    @Published var lastError: String = ""

    private let defaults = AppGroup.defaults

    init() {
        reload()
    }

    var activeNode: VlessNode? {
        nodes.first { $0.uri == activeURI }
    }

    func reload() {
        if let data = defaults.data(forKey: AppGroup.nodesKey),
           let list = try? JSONDecoder().decode([VlessNode].self, from: data) {
            nodes = list
        } else if let str = defaults.string(forKey: AppGroup.nodesKey),
                  let data = str.data(using: .utf8),
                  let list = try? JSONDecoder().decode([VlessNode].self, from: data) {
            nodes = list
        } else {
            nodes = []
        }
        activeURI = defaults.string(forKey: AppGroup.activeURIKey) ?? ""
        if activeURI.isEmpty, let first = nodes.first {
            activeURI = first.uri
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(nodes) {
            defaults.set(data, forKey: AppGroup.nodesKey)
        }
        defaults.set(activeURI, forKey: AppGroup.activeURIKey)
        // Also write JSON file into shared container for tunnel / debug.
        if let url = AppGroup.containerURL?.appendingPathComponent("nodes.json"),
           let data = try? JSONEncoder().encode(nodes) {
            try? data.write(to: url, options: .atomic)
        }
        if let url = AppGroup.containerURL?.appendingPathComponent("active_uri.txt") {
            try? activeURI.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    @discardableResult
    func add(uriRaw: String) throws -> VlessNode {
        let parsed = try VlessParser.parse(uriRaw)
        let node = VlessNode(remark: parsed.remark, uri: parsed.uri)
        if let idx = nodes.firstIndex(where: { $0.uri == node.uri }) {
            nodes[idx] = node
        } else if let idx = nodes.firstIndex(where: {
            (try? VlessParser.parse($0.uri))?.address == parsed.address &&
            (try? VlessParser.parse($0.uri))?.port == parsed.port &&
            (try? VlessParser.parse($0.uri))?.uuid == parsed.uuid
        }) {
            nodes[idx] = node
        } else {
            nodes.append(node)
        }
        activeURI = node.uri
        persist()
        return node
    }

    func setActive(_ node: VlessNode) {
        activeURI = node.uri
        persist()
    }

    func delete(_ node: VlessNode) {
        nodes.removeAll { $0.uri == node.uri }
        if activeURI == node.uri {
            activeURI = nodes.first?.uri ?? ""
        }
        persist()
    }

    func clearAll() {
        nodes = []
        activeURI = ""
        persist()
    }
}
