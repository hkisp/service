# iOS 代理内核（需在 macOS 编译）

在 Mac 上于项目根目录执行：

```bash
bash scripts/build_ios_libxray.sh
bash scripts/build_ios_libsingbox.sh
```

完成后本目录应出现：

- `LibXray.xcframework`
- `Libbox.xcframework`

二者都需要。`pod install` 时 Podfile 会把它们软链到 `v2ray_box` 插件的 Frameworks 目录。

Linux 环境无法执行这些脚本（缺少 xcodebuild）。
