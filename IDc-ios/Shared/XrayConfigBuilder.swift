import Foundation

/// Builds an Xray-core JSON config from a parsed VLESS+REALITY node.
/// Used by the tunnel (when a real core is linked) and for debugging in the app.
enum XrayConfigBuilder {
    static func build(from node: ParsedVless, socksPort: Int = 10808, httpPort: Int = 10809) -> [String: Any] {
        let outbound: [String: Any] = [
            "tag": "proxy",
            "protocol": "vless",
            "settings": [
                "vnext": [[
                    "address": node.address,
                    "port": node.port,
                    "users": [[
                        "id": node.uuid,
                        "encryption": node.encryption.isEmpty ? "none" : node.encryption,
                        "flow": node.flow
                    ]]
                ]]
            ],
            "streamSettings": [
                "network": node.transport.isEmpty ? "tcp" : node.transport,
                "security": "reality",
                "realitySettings": [
                    "serverName": node.sni,
                    "fingerprint": node.fingerprint,
                    "publicKey": node.publicKey,
                    "shortId": node.shortId,
                    "spiderX": ""
                ]
            ]
        ]

        return [
            "log": ["loglevel": "warning"],
            "inbounds": [
                [
                    "tag": "socks-in",
                    "listen": "127.0.0.1",
                    "port": socksPort,
                    "protocol": "socks",
                    "settings": ["udp": true]
                ],
                [
                    "tag": "http-in",
                    "listen": "127.0.0.1",
                    "port": httpPort,
                    "protocol": "http"
                ]
            ],
            "outbounds": [
                outbound,
                ["tag": "direct", "protocol": "freedom"],
                ["tag": "block", "protocol": "blackhole"]
            ],
            "routing": [
                "domainStrategy": "AsIs",
                "rules": [
                    ["type": "field", "outboundTag": "direct", "ip": ["geoip:private"]]
                ]
            ]
        ]
    }

    static func jsonString(from node: ParsedVless) throws -> String {
        let obj = build(from: node)
        let data = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
