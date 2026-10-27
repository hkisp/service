# IDc（个人用 iPhone 客户端）

显示名：**IDc**  
工程：`IDc.xcodeproj`  
Bundle ID：`com.danny.idcxray` / 扩展 `com.danny.idcxray.tunnel`  
App Group：`group.com.danny.idcxray`

个人自用，不给别人装。协议目标：VLESS + REALITY + Vision（粘贴 `vless://`）。

## 已完成 / 仍是 stub

| 模块 | 状态 |
|------|------|
| SwiftUI 节点列表（添加 / 切换 / 删除 / 连接） | ✅ |
| VLESS URI 解析 + Xray JSON 生成 | ✅ |
| App Group 持久化 `nodes.json` | ✅ |
| Packet Tunnel 扩展脚手架 | ✅（stub） |
| 真正 Xray / LibXray 内核 | ❌ 未链接，扩展只写配置并报告「已连接」，**不转发真实流量** |

## 用 Xcode 打开

```bash
open ~/Desktop/IDc/IDc.xcodeproj
```

## 加 Apple ID（免费也可先看 UI）

1. Xcode → Settings → Accounts → 点「+」→ Apple ID 登录。
2. 选中工程里 **IDc** 与 **IDcTunnel** 两个 Target → Signing & Capabilities → Team 选你的个人团队。
3. 若提示 Bundle ID 不可用，可改成 `com.你的名字.idcxray`（扩展同步改 `.tunnel`，App Group 也要一致）。

### 免费 Apple ID vs 付费 Developer（约 99 美元/年）

| | 免费 | 付费 |
|--|------|------|
| 装到自己 iPhone | 可以（约每 7 天重签） | 可以 |
| Network Extension（系统 VPN） | **基本不可用** | 需要，并在开发者后台开 Network Extensions |
| 长期自己用 VPN | 不够 | 需要 |

**结论：** 现在可以先在模拟器里看界面、试解析节点；真机系统 VPN 要等付费账号并勾选 Network Extension + App Groups。

## 模拟器编译（不签名）

```bash
cd ~/Desktop/IDc
xcodebuild -project IDc.xcodeproj -scheme IDc \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build
```

若本机没有 iPhone 16，把 `name=` 改成 `xcrun simctl list devices available` 里任意 iPhone。

## 真机（付费账号后）

1. Signing 选付费 Team；两个 Target 都打开：
   - Network Extensions → Packet Tunnel
   - App Groups → `group.com.danny.idcxray`
2. 用线连 iPhone，选真机，Run。
3. 首次点「连接」时允许「添加 VPN 配置」。

## 导入节点

在 App 底部粘贴完整 `vless://…` 链接，点「添加」。列表点选节点后点「切换」或「连接」。  
工程自带空的 `Shared/nodes.json`（`[]`），**不要**把真实 UUID / 公钥提交到公开仓库。

## 下一步（让 VPN 真能上网）

1. 付费加入 Apple Developer Program。
2. 将 LibXray / XrayKit（或 sing-box）编进 `IDcTunnel`。
3. 在 `PacketTunnelProvider` 里用生成的 JSON 启动内核，并配置 TUN / hev-socks5。
