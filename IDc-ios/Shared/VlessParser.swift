import Foundation

enum VlessParser {
    static func normalize(_ raw: String) -> String {
        var l = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        l = l.replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
        // type=raw → type=tcp
        if let re = try? NSRegularExpression(pattern: #"([?&])type=raw(?=&|#|$)"#) {
            let range = NSRange(l.startIndex..., in: l)
            l = re.stringByReplacingMatches(in: l, range: range, withTemplate: "$1type=tcp")
        }
        return l
    }

    static func parse(_ raw: String) throws -> ParsedVless {
        let link = normalize(raw)
        guard link.lowercased().hasPrefix("vless://") else { throw VlessParseError.notVless }

        guard let uri = URL(string: link) else { throw VlessParseError.badURL }
        guard uri.scheme?.lowercased() == "vless" else { throw VlessParseError.notVless }

        var missing: [String] = []

        let uuid = uri.user ?? ""
        if uuid.count < 8 { missing.append("uuid") }

        let address = uri.host ?? ""
        if address.isEmpty { missing.append("address") }

        let port = uri.port ?? 0
        if port <= 0 || port > 65535 { missing.append("port") }

        let items = URLComponents(string: link)?.queryItems ?? []
        func qp(_ key: String, alt: String? = nil) -> String {
            if let v = items.first(where: { $0.name == key })?.value?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty {
                return v
            }
            if let alt, let v = items.first(where: { $0.name == alt })?.value?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty {
                return v
            }
            return ""
        }

        let security = qp("security").lowercased()
        if security != "reality" { missing.append("security=reality") }

        let pbk = qp("pbk")
        if pbk.isEmpty { missing.append("pbk (REALITY 公钥)") }

        let sid = qp("sid")
        if sid.isEmpty { missing.append("sid (shortId)") }

        let sni = qp("sni", alt: "serverName")
        if sni.isEmpty { missing.append("sni / serverName") }

        let fp = qp("fp")
        if fp.isEmpty { missing.append("fp (fingerprint)") }

        let flow = qp("flow")
        if flow.isEmpty { missing.append("flow") }

        var type = qp("type").lowercased()
        if type.isEmpty {
            missing.append("type (tcp/raw)")
        } else if type == "raw" {
            type = "tcp"
        }

        if !missing.isEmpty { throw VlessParseError.missing(missing) }

        var remark = ""
        if let frag = uri.fragment, !frag.isEmpty {
            remark = frag.removingPercentEncoding ?? frag
        }

        let encryption = qp("encryption").isEmpty ? "none" : qp("encryption")

        return ParsedVless(
            uri: normalize(link),
            uuid: uuid,
            address: address,
            port: port,
            security: security,
            flow: flow,
            fingerprint: fp,
            sni: sni,
            publicKey: pbk,
            shortId: sid,
            transport: type,
            remark: remark,
            encryption: encryption
        )
    }
}
