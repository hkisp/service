import Foundation

struct VlessNode: Codable, Identifiable, Equatable {
    var id: String { uri }
    var remark: String
    var uri: String

    var displayName: String {
        let r = remark.trimmingCharacters(in: .whitespacesAndNewlines)
        if !r.isEmpty { return r }
        if let parsed = try? VlessParser.parse(uri) {
            return parsed.maskedHost
        }
        return "未命名节点"
    }
}

struct ParsedVless: Equatable {
    var uri: String
    var uuid: String
    var address: String
    var port: Int
    var security: String
    var flow: String
    var fingerprint: String
    var sni: String
    var publicKey: String
    var shortId: String
    var transport: String
    var remark: String
    var encryption: String

    var displayName: String {
        let r = remark.trimmingCharacters(in: .whitespacesAndNewlines)
        return r.isEmpty ? maskedHost : r
    }

    var maskedHost: String {
        let host = address
        if host.count <= 8 { return "\(host):\(port)" }
        let head = host.prefix(4)
        let tail = host.suffix(3)
        return "\(head)…\(tail):\(port)"
    }

    var protocolSummary: String {
        "VLESS · \(security.uppercased()) · Vision"
    }
}

enum VlessParseError: LocalizedError {
    case notVless
    case badURL
    case missing([String])

    var errorDescription: String? {
        switch self {
        case .notVless: return "必须以 vless:// 开头"
        case .badURL: return "无法解析链接（URL 编码有误）"
        case .missing(let fields):
            if fields.isEmpty { return "VLESS 链接无效" }
            return "缺少必要参数：\(fields.joined(separator: ", "))"
        }
    }
}
