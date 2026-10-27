#!/usr/bin/env bash
# 用法: bash scripts/set_bundle_id.sh com.yourname.myvpn
# 一次性把 iOS 主 App / PacketTunnel 扩展 / App Group 的标识全部改掉。
set -euo pipefail
NEW="${1:?用法: bash scripts/set_bundle_id.sh com.yourname.myvpn}"
cd "$(dirname "$0")/.."
OLD=$(grep -m1 -o 'PRODUCT_BUNDLE_IDENTIFIER = [^;]*PacketTunnel' ios/Runner.xcodeproj/project.pbxproj | sed 's/PRODUCT_BUNDLE_IDENTIFIER = //; s/\.PacketTunnel$//')
[ -n "$OLD" ] || { echo "找不到当前 bundle id"; exit 1; }
echo "把 $OLD 改成 $NEW"
FILES="ios/Runner.xcodeproj/project.pbxproj ios/Runner/Runner.entitlements ios/PacketTunnel/PacketTunnel.entitlements"
for f in $FILES; do
  sed -i.bak "s/${OLD//./\\.}/$NEW/g" "$f" && rm -f "$f.bak"
done
echo "完成。主 App: $NEW  扩展: $NEW.PacketTunnel  App Group: group.$NEW"
