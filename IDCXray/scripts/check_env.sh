#!/usr/bin/env bash
# Report what is available for building IDCXray (especially on Mac).
set -u
cd "$(dirname "$0")/.."
echo "=== IDCXray 环境检查 ==="
echo "日期: $(date)"
echo "系统: $(uname -a)"
echo

ok() { echo "[OK] $1"; }
miss() { echo "[缺失] $1"; }
warn() { echo "[注意] $1"; }

have() { command -v "$1" >/dev/null 2>&1; }

have git && ok "git $(git --version 2>/dev/null | head -1)" || miss "git"
have flutter && ok "flutter $(flutter --version 2>/dev/null | head -1)" || miss "flutter (https://flutter.dev)"
have dart && ok "dart $(dart --version 2>/dev/null)" || warn "dart (通常随 Flutter)"
have go && ok "go $(go version 2>/dev/null)" || miss "go (编译 LibXray / Libbox 需要)"
have jq && ok "jq" || miss "jq"
have python3 && ok "python3" || miss "python3"
have pod && ok "pod $(pod --version 2>/dev/null)" || miss "CocoaPods (pod) — 仅 macOS"
have xcodebuild && ok "xcodebuild $(xcodebuild -version 2>/dev/null | head -1)" || miss "Xcode / xcodebuild — 仅 macOS"
have gomobile && ok "gomobile" || warn "gomobile (首次编译内核时会安装到 GOPATH/bin)"

echo
if [[ "$(uname -s)" != "Darwin" ]]; then
  warn "当前不是 macOS：无法在此签名、编译 iOS、导出 IPA 或装到 iPhone。"
  warn "请在 Mac 或云端 Mac 上继续：见 README_中文.md"
else
  ok "macOS — 可继续编译内核与 Xcode 签名"
fi

echo
echo "项目文件:"
[[ -f pubspec.yaml ]] && ok "pubspec.yaml" || miss "pubspec.yaml"
[[ -d ios/PacketTunnel ]] && ok "ios/PacketTunnel" || miss "ios/PacketTunnel"
[[ -f ios/Frameworks/LibXray.xcframework/Info.plist ]] && ok "LibXray.xcframework" || warn "尚未编译 LibXray（bash scripts/build_ios_libxray.sh）"
[[ -f ios/Frameworks/Libbox.xcframework/Info.plist ]] && ok "Libbox.xcframework" || warn "尚未编译 Libbox（bash scripts/build_ios_libsingbox.sh）"
echo
echo "完成。"
