import NetworkExtension
import os.log

/// Packet Tunnel Provider stub.
///
/// Current behavior:
/// 1. Reads active VLESS URI from provider options / App Group
/// 2. Parses it and builds an Xray JSON config
/// 3. Logs the config (secrets redacted) and reports tunnel "connected"
/// 4. Does NOT yet run Xray-core / LibXray — mark as stub until a core is linked
///
/// To make real VPN work later:
/// - Link LibXray / XrayKit (or sing-box) into this extension target
/// - Start the core with the generated JSON
/// - Set packetFlow / TUN via NEPacketTunnelNetworkSettings (or hev-socks5-tunnel)
final class PacketTunnelProvider: NEPacketTunnelProvider {
    private let log = OSLog(subsystem: "com.danny.idcxray.tunnel", category: "tunnel")
    private var isStubConnected = false

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        os_log("startTunnel begin", log: log, type: .info)

        let uri = resolveActiveURI(options: options)
        guard let uri, !uri.isEmpty else {
            let err = NSError(
                domain: "IDcTunnel",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "没有活动节点 URI"]
            )
            AppGroup.defaults.set("没有活动节点 URI", forKey: AppGroup.lastErrorKey)
            completionHandler(err)
            return
        }

        do {
            let parsed = try VlessParser.parse(uri)
            let json = try XrayConfigBuilder.jsonString(from: parsed)
            // Persist config for debug (shared container).
            if let url = AppGroup.containerURL?.appendingPathComponent("last_xray_config.json") {
                try? json.write(to: url, atomically: true, encoding: .utf8)
            }
            os_log("Built Xray config for %{public}@:%d (stub — core not linked)", log: log, type: .info, parsed.address, parsed.port)

            // Minimal tunnel settings so the system accepts the session.
            // Without a real userspace stack, traffic is NOT actually proxied.
            let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
            settings.mtu = 1500
            let ipv4 = NEIPv4Settings(addresses: ["10.8.0.2"], subnetMasks: ["255.255.255.0"])
            // Empty includedRoutes → do not claim default route in stub mode
            // (avoids breaking device networking until real core is ready).
            ipv4.includedRoutes = []
            settings.ipv4Settings = ipv4
            settings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "1.1.1.1"])

            setTunnelNetworkSettings(settings) { [weak self] error in
                guard let self else { return }
                if let error {
                    os_log("setTunnelNetworkSettings failed: %{public}@", log: self.log, type: .error, error.localizedDescription)
                    AppGroup.defaults.set(error.localizedDescription, forKey: AppGroup.lastErrorKey)
                    completionHandler(error)
                    return
                }
                self.isStubConnected = true
                AppGroup.defaults.set("stub_connected", forKey: AppGroup.tunnelStatusKey)
                AppGroup.defaults.set("", forKey: AppGroup.lastErrorKey)
                os_log("Stub tunnel reported connected. Link LibXray to proxy for real.", log: self.log, type: .info)
                completionHandler(nil)
            }
        } catch {
            AppGroup.defaults.set(error.localizedDescription, forKey: AppGroup.lastErrorKey)
            completionHandler(error)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        os_log("stopTunnel reason=%{public}d", log: log, type: .info, reason.rawValue)
        isStubConnected = false
        AppGroup.defaults.set("stopped", forKey: AppGroup.tunnelStatusKey)
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        let reply = (isStubConnected ? "stub_connected" : "idle").data(using: .utf8)
        completionHandler?(reply)
    }

    private func resolveActiveURI(options: [String: NSObject]?) -> String? {
        if let o = options?["active_uri"] as? String, !o.isEmpty { return o }
        if let s = AppGroup.defaults.string(forKey: AppGroup.activeURIKey), !s.isEmpty { return s }
        if let url = AppGroup.containerURL?.appendingPathComponent("active_uri.txt"),
           let s = try? String(contentsOf: url, encoding: .utf8) {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { return t }
        }
        return nil
    }
}
