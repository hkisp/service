# IDCXray 构建脚本

| 脚本 | 说明 |
|------|------|
| `check_env.sh` | 检查本机是否具备 Flutter / Xcode / Go 等 |
| `set_bundle_id.sh` | 修改 Bundle ID 与 App Group |
| `build_ios_libxray.sh` | 在 **macOS** 编译 `LibXray.xcframework` |
| `build_ios_libsingbox.sh` | 在 **macOS** 编译 `Libbox.xcframework` |
| `build_android_*.sh` | Android AAR（次要） |
| `build_macos_*.sh` | macOS 桌面（可选） |

iOS 内核编译必须在 Mac 上运行（需要 `xcodebuild`）。Linux 上只能生成源码与跑 Dart 单元测试。
