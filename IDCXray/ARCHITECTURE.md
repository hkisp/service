# IDCXray 架构说明

## 技术选型

| 层 | 选择 | 理由 |
|----|------|------|
| UI | Flutter + Material 3（深色科技风） | 快速做出配置页与状态机；单人维护成本低 |
| iOS VPN | `NEPacketTunnelProvider`（Packet Tunnel） | 系统级 VPN，非假 UI |
| 插件 | [v2ray_box](https://github.com/pesaregorg/v2ray_box) MIT | 已有 Flutter API + iOS 扩展样板，支持 VLESS / REALITY / Vision |
| 内核 | LibXray（Xray-core）为主，Libbox（sing-box）可选 | 与常见 VLESS+REALITY 服务端一致 |
| 对照方案 | sing-box-for-apple | 更「原生」，但 GPL-3，二次分发需开源；本个人项目未强制采用 |

**注意：** 仅「核心能解析配置」≠「已实现 iOS 隧道」。本项目通过 Packet Tunnel 扩展真正创建 `utun` 并把流量交给内核。

## 数据流（iOS）

```
┌─────────────┐   保存 URI（Secure Storage）    ┌──────────────────┐
│  IDCXray App │ ─────────────────────────────► │ 本地安全存储 /     │
│  (Flutter)   │   connect(uri) via v2ray_box   │ App Group 容器    │
└──────┬───────┘                                └─────────┬────────┘
       │ start VPN / 传递 Config + CoreEngine             │
       ▼                                                  │
┌──────────────────────┐                                  │
│ PacketTunnel.appex   │◄─────────────────────────────────┘
│ NEPacketTunnelProvider│
│ PacketTunnelProvider │
└──────────┬───────────┘
           │ 1) setTunnelNetworkSettings → 系统创建 utun
           │ 2) 启动 LibXray 或 Libbox
           ▼
   设备 IP 包进入 utun
           │
           ▼
   内核出站：VLESS + REALITY + Vision → 远程节点
```

### Xray 路径（默认）

1. App 调用插件 `connect`，由插件启动 Packet Tunnel，并在 `options` 中传入 JSON 配置与 `CoreEngine=xray`。
2. `PacketTunnelProvider.startXrayTunnel`：
   - 准备工作目录（App Group 共享容器）
   - 给配置补上本地 `socks`/`http` inbound（供系统代理设置使用）
   - `setTunnelNetworkSettings`：IPv4 默认路由 + DNS（1.1.1.1 / 8.8.8.8）+ 可选 HTTP 代理指向本地 inbound
   - `LibXrayRunXrayFromJSON` 运行核心
3. 系统把匹配路由的流量送入隧道；核心按 outbound 建立 VLESS REALITY 连接。

### sing-box 路径

1. `LibboxSetup` + `LibboxNewCommandServer` + `startOrReloadService`
2. `TunnelPlatformInterface.openTun` 向系统申请 tun fd，并写入 DNS / 路由
3. Libbox 在扩展进程内读写 tun

## App ↔ Extension

- **Entitlements**：双方均需 `packet-tunnel-provider` 与同一个 App Group。
- **配置传递**：连接参数通过启动 Tunnel 的 options / App Group 文件传递；Flutter 层不把完整 URI 打到普通日志。
- **状态**：插件 `watchStatus()` / `watchStats()` 反映真实 VPN 状态；UI **禁止**在未收到 `started` 时显示「已连接」。

## Android（次要）

`AndroidManifest` 已按插件要求注册 `VPNService` / `ProxyService` 与前台服务权限。本阶段目标设备是 iPhone，Android 未做深度验证。

## 安全边界

- 节点 URI：优先 `flutter_secure_storage`；失败时回退到本机 `SharedPreferences`（仍不上传）。
- 无遥测、无远程下发配置通道。
- 无法、也不会绕过 iOS VPN 授权对话框。
