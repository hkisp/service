import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: NodeStore
    @EnvironmentObject var vpn: VPNManager

    @State private var pasteText = ""
    @State private var alertMessage: String?
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusHeader
                Divider().overlay(Color.white.opacity(0.08))
                nodeList
                Divider().overlay(Color.white.opacity(0.08))
                pasteBar
                actionBar
            }
            .background(Color(red: 0.07, green: 0.08, blue: 0.10).ignoresSafeArea())
            .navigationTitle("IDc")
            .navigationBarTitleDisplayMode(.inline)
            .alert("提示", isPresented: $showAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private var statusHeader: some View {
        VStack(spacing: 10) {
            Text(vpn.phase.labelZh)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(statusColor)

            if let node = store.activeNode {
                Text(node.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                if let parsed = try? VlessParser.parse(node.uri) {
                    Text("\(parsed.maskedHost) · \(parsed.protocolSummary)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("未配置节点")
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await vpn.toggle(activeURI: store.activeURI) }
            } label: {
                Text(vpn.phase == .connected || vpn.phase == .connecting ? "断开" : "连接")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(vpn.phase == .connected ? Color.red.opacity(0.85) : Color.cyan.opacity(0.9))
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .disabled(vpn.phase == .disconnecting)

            if let err = vpn.lastError, !err.isEmpty {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Text(vpn.stubNote)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 16)
    }

    private var statusColor: Color {
        switch vpn.phase {
        case .connected: return .green
        case .connecting, .disconnecting: return .orange
        case .error: return .red
        case .disconnected: return .secondary
        }
    }

    private var nodeList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("节点列表")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 12)

            if store.nodes.isEmpty {
                Text("暂无节点。粘贴 vless:// 后点「添加」。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                List {
                    ForEach(store.nodes) { node in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(node.displayName)
                                    .foregroundStyle(.white)
                                if let p = try? VlessParser.parse(node.uri) {
                                    Text(p.maskedHost)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if node.uri == store.activeURI {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.cyan)
                            }
                        }
                        .contentShape(Rectangle())
                        .listRowBackground(Color.white.opacity(0.04))
                        .onTapGesture {
                            store.setActive(node)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.delete(node)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var pasteBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("粘贴 vless://")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("vless://uuid@host:port?…#备注", text: $pasteText, axis: .vertical)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(.footnote, design: .monospaced))
                .padding(10)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .lineLimit(3...6)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            btn("添加") { addFromPaste() }
            btn("切换") { switchSelected() }
            btn("删除", danger: true) { deleteActive() }
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }

    private func btn(_ title: String, danger: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(danger ? Color.red.opacity(0.25) : Color.white.opacity(0.1))
                .foregroundStyle(danger ? Color.red : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func addFromPaste() {
        do {
            let node = try store.add(uriRaw: pasteText)
            pasteText = ""
            alertMessage = "已添加：\(node.displayName)"
            showAlert = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func switchSelected() {
        guard let node = store.activeNode else {
            alertMessage = "请先在列表中点选一个节点"
            showAlert = true
            return
        }
        store.setActive(node)
        alertMessage = "已切换到：\(node.displayName)"
        showAlert = true
        if vpn.phase == .connected {
            Task {
                await vpn.disconnect()
                await vpn.connect(activeURI: store.activeURI)
            }
        }
    }

    private func deleteActive() {
        guard let node = store.activeNode else {
            alertMessage = "没有可删除的节点"
            showAlert = true
            return
        }
        store.delete(node)
        alertMessage = "已删除：\(node.displayName)"
        showAlert = true
    }
}

#Preview {
    ContentView()
        .environmentObject(NodeStore())
        .environmentObject(VPNManager())
        .preferredColorScheme(.dark)
}
