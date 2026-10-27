# MyVPN：自己的 iPhone 翻墙 App（一个节点 + 连接按钮）

这个工程基于 Flutter 插件 **v2ray_box**（https://github.com/pesaregorg/v2ray_box，MIT 许可，
固定在提交 `bc194f6`），内核用 Xray-core，iOS 上通过 Packet Tunnel 网络扩展（Network Extension）实现全局 VPN。

App 界面：
- 预置节点 `gcp-38501`（34.83.155.49:38501，VLESS + REALITY + Vision）
- 一个大的 **连接 / 断开** 按钮和连接状态
- 一个输入框：粘贴新的 `vless://` 链接后点「保存」即可替换节点（保存在手机本地）；「恢复预置节点」可以改回来
- 链接里的 `type=raw` 会自动换成等价的 `type=tcp`

> 已经在 Linux 上完成：建工程、写界面、按插件示例配好 iOS 工程（PacketTunnel 扩展 target、App Group、entitlements、Podfile、Info.plist）和 Android 配置，`flutter analyze` 无问题、单元测试通过。
> **iOS 只能在 Mac 上编译**，下面这些步骤需要在你的 MacBook 上做。

---

## 一、Mac 上要装的东西

1. **Xcode**（App Store 安装，最新版即可，要求 iOS 15 以上的手机）。装完打开一次，同意协议，
   然后在终端运行：
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   xcodebuild -runFirstLaunch
   ```
2. **Homebrew**（https://brew.sh），再用它装其它工具：
   ```bash
   brew install --cask flutter      # Flutter SDK（stable）
   brew install cocoapods go jq     # CocoaPods（建议 1.16.2 及以上）、Go、jq（编译内核用）
   ```
   Python3 和 git 在 Mac 上自带（第一次用会提示装命令行工具，点安装即可）。
3. 检查环境：
   ```bash
   flutter doctor
   ```
   Xcode 和 CocoaPods 两项打勾就行（Android 那项可以不管）。

## 二、Apple 开发者账号（必须付费，99 美元/年）

VPN 类 App 需要 **Network Extension** 权限，免费 Apple ID 拿不到，所以必须加入
Apple Developer Program：https://developer.apple.com/programs/

### 1. 先选一个唯一的 Bundle ID
工程默认是 `com.myvpn.myvpn`，**建议改成你自己的**，例如 `com.danny.myvpn`（全球唯一，不能和别人重复）。
在工程根目录运行一次即可全部改好：
```bash
bash scripts/set_bundle_id.sh com.danny.myvpn
```
插件有固定的命名规则（代码里写死的，不要改）：

| 用途 | 标识 |
|---|---|
| 主 App | `com.danny.myvpn` |
| VPN 扩展 | `com.danny.myvpn.PacketTunnel` |
| App Group | `group.com.danny.myvpn` |

### 2. 在开发者网站上注册（https://developer.apple.com/account/resources）
> 如果你在 Xcode 里勾选了「Automatically manage signing」，Xcode 通常会自动创建这些。
> 自动失败时再按下面手动做。

1. **Identifiers → + → App Groups**：Identifier 填 `group.com.danny.myvpn`。
2. **Identifiers → + → App IDs → App**：
   - Bundle ID（Explicit）：`com.danny.myvpn`
   - Capabilities 勾选 **App Groups**（点 Configure 选上一步的 group）和 **Network Extensions**
3. 再建一个 App ID：`com.danny.myvpn.PacketTunnel`，同样勾选 **App Groups**（同一个 group）和 **Network Extensions**。
4. **Devices**：把你的 iPhone 加进去（用 Xcode 连手机时一般会自动注册）。

## 三、在 Mac 上编译

把 `myvpn-app.zip` 解压，比如放到 `~/myvpn-app`，然后：

```bash
cd ~/myvpn-app
flutter pub get

# 1) 编译 iOS 内核（第一次要下载源码并编译，可能要 10～30 分钟）
bash scripts/build_ios_libxray.sh      # 生成 ios/Frameworks/LibXray.xcframework
bash scripts/build_ios_libsingbox.sh   # 生成 ios/Frameworks/Libbox.xcframework（插件本体也要用到，必须编）

# 2) 安装 CocoaPods 依赖
cd ios
pod install
cd ..

# 3) 用 Xcode 打开（一定要打开 .xcworkspace，不是 .xcodeproj）
open ios/Runner.xcworkspace
```

> 如果 `pod install` 提示找不到 `.flutter-plugins-dependencies`，先在根目录运行 `flutter pub get`。
> 如果提示 Libbox.xcframework 缺失，说明第 1 步没成功，先把内核编译出来。

## 四、Xcode 里的设置（图形界面操作）

工程里已经**预先建好了 PacketTunnel 扩展 target**，正常情况下只需要设签名：

1. 左边点最上面的蓝色 **Runner** 项目 → 中间 TARGETS 列表。
2. 选 **Runner** → **Signing & Capabilities**：
   - 勾选 **Automatically manage signing**
   - **Team** 选你的付费开发者账号
   - 确认 Bundle Identifier 是 `com.danny.myvpn`
   - 下面应能看到 **App Groups**（`group.com.danny.myvpn` 已勾选）和 **Network Extensions**（Packet Tunnel 已勾选）。
     如果没有：点左上角 **+ Capability** 分别添加 App Groups、Network Extensions，并勾选对应项。
3. 选 **PacketTunnel** target，做同样的事：同一个 Team，Bundle ID 为 `com.danny.myvpn.PacketTunnel`，
   App Groups 勾选同一个 group，Network Extensions 勾选 **Packet Tunnel**。
4. 仍在 **PacketTunnel** target → **General → Frameworks and Libraries**，确认有这 4 个：
   `Libbox.xcframework`、`LibXray.xcframework`、`NetworkExtension.framework`、`UIKit.framework`。
   缺了就点 **+** → Add Other → Add Files，选 `ios/Frameworks/` 里的文件。
5. 两个 target 的 **Minimum Deployments** 都是 iOS 15.6（已设好）。

### （备用）如果 PacketTunnel target 不见了，手动新建
1. Xcode 菜单 **File → New → Target… → iOS → Network Extension**，Product Name 填 `PacketTunnel`，
   Provider Type 选 **Packet Tunnel**，Embed in Application 选 **Runner**，语言 Swift。
2. 删掉 Xcode 自动生成的 `PacketTunnelProvider.swift`、`Info.plist`、`.entitlements`，
   改用本工程 `ios/PacketTunnel/` 目录下的同名三个文件（拖进 PacketTunnel 组，Target Membership 只勾 PacketTunnel）。
3. PacketTunnel target → Build Settings：
   `Info.plist File` = `PacketTunnel/Info.plist`，`Code Signing Entitlements` = `PacketTunnel/PacketTunnel.entitlements`，
   `iOS Deployment Target` = 15.6，Bundle ID = `com.danny.myvpn.PacketTunnel`。
4. 按上面第 3、4 步加 Capabilities 和 Frameworks（Libbox / LibXray 选 “Embed & Sign”）。
5. Runner target → Build Phases 里确认有 “Embed Foundation Extensions”，里面有 PacketTunnel.appex。

## 五、装到 iPhone 上运行

1. 用数据线把 iPhone 连到 Mac，手机上点「信任此电脑」。
2. iPhone 打开 **设置 → 隐私与安全性 → 开发者模式**，打开并重启手机（iOS 16 以上才有这个开关）。
3. Xcode 顶部设备选择你的 iPhone，点 ▶︎ 运行；或者在终端：
   ```bash
   flutter run --release
   ```
4. 第一次打开 App 点 **连接**，会弹出「“MyVPN” 想添加 VPN 配置」，点 **允许** 并输入手机密码。
5. 状态变成「已连接」，状态栏出现 VPN 图标就成功了。可以用 Safari 打开 ip138 / ipinfo.io 看出口 IP 是不是 34.83.155.49。

> **VPN 不能在 iOS 模拟器里测试**，必须用真机。
> 用开发证书装的 App 只要开发者会员有效就能一直用；会员到期后需要续费并重新安装。

## 六、常见问题

- **点连接没反应 / 立刻断开**：多半是签名或权限问题。检查两个 target 用的是同一个 Team、同一个 App Group，
  且都加了 Network Extensions（Packet Tunnel）。在 Mac 上打开「控制台」App，选你的 iPhone，搜 `PacketTunnel` 看日志。
- **内核编译失败**：`build_ios_*.sh` 默认拉 libXray / sing-box 的最新源码。如果最新版和插件的 Swift 代码不兼容，
  可以指定版本，例如 `bash scripts/build_ios_libsingbox.sh --singbox-ref v1.12.22`（插件文档里提到的版本），
  具体参数看 `scripts/README.md`。
- **想换节点**：在 App 里粘贴新的 `vless://` 链接点保存，断开后重新连接。
- **Android**：工程也配好了 Android（需要先运行 `scripts/build_android_libxray.sh` 编译内核，再 `flutter run`）。
