# 依赖与许可证清单（IDCXray）

本应用为个人使用目的集成下列开源组件。分发前请自行复核各项目当前许可证全文。

| 组件 | 用途 | 许可证（据公开仓库常见声明） | 来源 |
|------|------|------------------------------|------|
| Flutter / Dart SDK | UI 框架 | BSD-style（Flutter） | flutter.dev |
| v2ray_box | Flutter 插件 + iOS PacketTunnel 样板 | MIT | https://github.com/pesaregorg/v2ray_box |
| Xray-core / libXray | 代理内核 | MPL-2.0（Xray-core） | https://github.com/XTLS/Xray-core / https://github.com/XTLS/libXray |
| sing-box / Libbox | 可选内核 | GPL-2.0 / GPL-3.0（以 sing-box 仓库为准） | https://github.com/SagerNet/sing-box |
| shared_preferences | 非敏感偏好 | BSD | pub.dev |
| flutter_secure_storage | 节点 URI 本地加密存储 | BSD | pub.dev |
| cupertino_icons | 图标字体 | MIT | pub.dev |

## 选用说明

- **v2ray_box（MIT）** 作为壳与隧道集成，避免从零实现 Network Extension。
- 默认推荐 **Xray-core** 路径，与多数 VLESS+REALITY+Vision 服务端一致。
- 若启用 **sing-box**，请注意其 GPL 义务：若你对外再分发修改过的二进制，通常需要提供对应源代码。

## 商标

未使用 V2Box 或其他商业客户端的商标与专有图标。应用名称为 **IDCXray**，图标为项目原创生成资源（`assets/idcxray-icon.png`）。
