import Foundation
import NetworkExtension
import Combine

enum ConnPhase: String {
    case disconnected, connecting, connected, disconnecting, error

    var labelZh: String {
        switch self {
        case .disconnected: return "未连接"
        case .connecting: return "连接中…"
        case .connected: return "已连接"
        case .disconnecting: return "断开中…"
        case .error: return "出错"
        }
    }
}

@MainActor
final class VPNManager: ObservableObject {
    @Published var phase: ConnPhase = .disconnected
    @Published var lastError: String?
    @Published var stubNote: String = "隧道内核尚未链接（当前为 stub）"

    private var manager: NETunnelProviderManager?
    private var statusObserver: NSObjectProtocol?

    init() {
        Task { await refresh() }
    }

    deinit {
        if let statusObserver {
            NotificationCenter.default.removeObserver(statusObserver)
        }
    }

    func refresh() async {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            if let existing = managers.first(where: {
                ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == "com.danny.idcxray.tunnel"
            }) {
                manager = existing
            } else if let first = managers.first {
                manager = first
            } else {
                let m = NETunnelProviderManager()
                let proto = NETunnelProviderProtocol()
                proto.providerBundleIdentifier = "com.danny.idcxray.tunnel"
                proto.serverAddress = "IDc"
                m.protocolConfiguration = proto
                m.localizedDescription = "IDc"
                m.isEnabled = true
                manager = m
            }
            observeStatus()
            syncPhase()
        } catch {
            lastError = error.localizedDescription
            phase = .error
        }
    }

    private func observeStatus() {
        if let statusObserver {
            NotificationCenter.default.removeObserver(statusObserver)
        }
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: manager?.connection,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.syncPhase() }
        }
    }

    private func syncPhase() {
        guard let status = manager?.connection.status else {
            phase = .disconnected
            return
        }
        switch status {
        case .connected: phase = .connected
        case .connecting, .reasserting: phase = .connecting
        case .disconnecting: phase = .disconnecting
        case .disconnected, .invalid: phase = .disconnected
        @unknown default: phase = .disconnected
        }
    }

    func connect(activeURI: String) async {
        lastError = nil
        guard !activeURI.isEmpty else {
            lastError = "请先选择或添加节点"
            phase = .error
            return
        }
        await refresh()
        guard let manager else {
            lastError = "无法创建 VPN 配置（需付费开发者账号启用 Network Extension）"
            phase = .error
            return
        }
        do {
            if let proto = manager.protocolConfiguration as? NETunnelProviderProtocol {
                proto.providerConfiguration = ["active_uri": activeURI]
                manager.protocolConfiguration = proto
            }
            manager.isEnabled = true
            try await manager.saveToPreferences()
            try await manager.loadFromPreferences()
            observeStatus()
            phase = .connecting
            try manager.connection.startVPNTunnel(options: ["active_uri": activeURI as NSString])
            // Stub tunnel will report connected quickly if extension loads.
            stubNote = "已请求启动隧道。未链接 Xray 内核时，扩展仅记录配置并模拟连接。"
        } catch {
            lastError = error.localizedDescription
            phase = .error
        }
    }

    func disconnect() async {
        manager?.connection.stopVPNTunnel()
        phase = .disconnecting
        try? await Task.sleep(nanoseconds: 300_000_000)
        syncPhase()
    }

    func toggle(activeURI: String) async {
        switch phase {
        case .connected, .connecting:
            await disconnect()
        default:
            await connect(activeURI: activeURI)
        }
    }
}
