# IDCXray 测试报告

测试环境：Linux（无 macOS / Xcode / 真机签名）。时间以构建机本地时区 Asia/Shanghai 为准。

## 已在 Linux 验证

| # | 项目 | 结果 |
|---|------|------|
| 1 | `flutter pub get` | 通过（0 issues） |
| 2 | `flutter analyze` | 通过（8/8） |
| 3 | VLESS URI 解析：合法链接 | 单元测试 |
| 4 | 非法 / 缺字段拒绝并列出缺失项 | 单元测试 |
| 5 | `type=raw` → `tcp` 规范化 | 单元测试 |
| 6 | 显示脱敏（maskedHost / redactedUri） | 单元测试 |
| 7 | 源码中无真实节点 UUID/密钥硬编码 | 人工检查通过 |
| 8 | Bundle ID / App Group / DisplayName 为 IDCXray | 人工检查通过 |

## 未验证（缺 Mac / 开发者账号 / 真机）

| # | 项目 | 原因 |
|---|------|------|
| 1 | App 真机启动 | 无签名 IPA |
| 2 | VPN 隧道启动 / 断开 | 需 Network Extension + 付费 Team |
| 3 | 连接状态是否与系统 VPN 一致 | 需真机 |
| 4 | DNS / 上网是否正常 | 需真机 + 真实节点 |
| 5 | App 杀进程后配置恢复（secure storage on iOS） | 需真机 |
| 6 | 网络切换（Wi-Fi ↔ 蜂窝） | 需真机 |
| 7 | `LibXray` / `Libbox` xcframework 编译 | 需 macOS `xcodebuild` |
| 8 | Xcode 签名 / Archive / IPA | 需付费 Apple Developer |

**结论：** 静态分析与解析器测试不能替代真实 VPN 连接测试。到「可在本人 iPhone 上连上节点」为止，仍须完成 Mac 编译 + 付费签名 + 真机验证。


最后跑测时间：2026-10-27 14:26 Asia/Shanghai
