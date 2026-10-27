# IDCXray

个人用 iPhone VPN / 代理客户端（极简版）。

- 协议目标：**VLESS + REALITY + Vision**（`xtls-rprx-vision`）
- UI 壳：**Flutter**
- 隧道与内核集成：[v2ray_box](https://github.com/pesaregorg/v2ray_box)（MIT）→ **Xray-core** / **sing-box** + iOS **Packet Tunnel**
- 默认 Bundle ID：`com.idcxray.app`（扩展 `com.idcxray.app.PacketTunnel`，App Group `group.com.idcxray.app`）

## 当前交付状态（请勿混淆）

| 阶段 | 状态 |
|------|------|
| 源代码已生成 | ✅ |
| Linux 上 Dart 分析 / 单元测试 | ✅（见 `TEST_REPORT.md`） |
| 在 macOS 上编译成功 | ❌ 本构建环境是 Linux，无 Xcode |
| 签名完成 / IPA 已生成 | ❌ |
| 真机安装 / 真机 VPN 验证 | ❌ |

**本仓库不会提供已签名 IPA。** 完整 VPN 必须通过你自己的 Apple 开发者账号签名后，用 Xcode 装到你的 iPhone。

## 你需要准备什么

1. **付费 Apple Developer Program**（约 **99 美元/年**）  
   Network Extension（Packet Tunnel）无法用免费个人账号稳定分发。未付费前无法在真机上跑完整 VPN。
2. **一台 Mac**（或你确认付费后的云端 Mac），安装：
   - Xcode（含 iOS SDK）
   - Flutter
   - CocoaPods
   - Go、jq、python3、git
3. **真机 iPhone**（模拟器不能测系统 VPN）
4. 你自己的 **VLESS REALITY** 节点链接（**不要**把真实 UUID/密钥提交到公开仓库）

## 在 Mac 上安装步骤

```bash
# 0) 环境自检
bash scripts/check_env.sh

# 1)（可选）改成你自己的 Bundle ID
bash scripts/set_bundle_id.sh com.你的名字.idcxray

# 2) 拉依赖
flutter pub get

# 3) 编译内核（约 10–30 分钟，需网络）
bash scripts/build_ios_libxray.sh
bash scripts/build_ios_libsingbox.sh

# 4) CocoaPods
cd ios && pod install && cd ..

# 5) 用 Xcode 打开工作区（注意是 .xcworkspace）
open ios/Runner.xcworkspace
```

在 Xcode 中：

1. 选中 **Runner** 与 **PacketTunnel** 两个 Target，Signing & Capabilities → 勾选你的 **Team**（付费账号）。
2. 确认 Capabilities：**Network Extensions**（Packet Tunnel）、**App Groups**（`group.<你的bundle>`）。
3. 用数据线连接 iPhone，选择真机，点 Run。
4. 首次连接时，系统会提示「添加 VPN 配置」，点允许。

## 导入节点

App 内打开「配置管理」，粘贴形如：

```text
vless://YOUR_UUID@example.com:443?encryption=none&flow=xtls-rprx-vision&type=tcp&security=reality&fp=chrome&sni=www.example.com&pbk=YOUR_PUBLIC_KEY&sid=YOUR_SHORT_ID#备注名
```

`type=raw` 会自动当成 `tcp`。缺少 `pbk` / `sid` / `sni` / `fp` / `flow` / `security=reality` 时会明确提示缺哪些字段。

## 隐私

- 不上传节点配置
- 无分析 / 广告 SDK
- 完整 URI 优先写入系统安全存储；日志会脱敏

## 文档索引

- `ARCHITECTURE.md` — 流量如何进入 Packet Tunnel / Xray
- `LICENSE_NOTICE.md` — 依赖与许可证
- `TEST_REPORT.md` — 已测 / 未测项
- `阶段报告.md` — 阶段 1–8 诚实记录

## 云端 Mac（未代购）

若只有 iPhone、没有 Mac，可自行评估：MacStadium、AWS EC2 Mac、GitHub-hosted macOS runners、或按小时租用的云 Mac。**任何产生费用的服务须你本人确认后再开通**；本交付物只提供可复现脚本，不会代下单。
