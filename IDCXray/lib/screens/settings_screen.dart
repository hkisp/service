import 'package:flutter/material.dart';

import '../services/config_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.store,
    required this.coreEngine,
    required this.onCoreChanged,
  });

  final ConfigStore store;
  final String coreEngine;
  final ValueChanged<String> onCoreChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _engine;

  @override
  void initState() {
    super.initState();
    _engine = widget.coreEngine;
  }

  Future<void> _setEngine(String v) async {
    setState(() => _engine = v);
    await widget.store.saveCoreEngine(v);
    widget.onCoreChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('代理内核'),
            subtitle: Text('与服务端一致时优先选 Xray-core'),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'xray',
                label: Text('Xray-core'),
                icon: Icon(Icons.bolt),
              ),
              ButtonSegment(
                value: 'singbox',
                label: Text('sing-box'),
                icon: Icon(Icons.hub_outlined),
              ),
            ],
            selected: {_engine},
            onSelectionChanged: (s) {
              if (s.isEmpty) return;
              _setEngine(s.first);
            },
          ),
          const SizedBox(height: 24),
          const Divider(),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('关于 IDCXray'),
            subtitle: Text(
              '个人用极简 VPN 客户端\n'
              '协议：VLESS + REALITY + Vision\n'
              '内核：Xray-core / sing-box（via v2ray_box）\n'
              '版本：1.0.0',
            ),
            isThreeLine: true,
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('隐私'),
            subtitle: Text('无分析 SDK、无远程控制、不上传配置。'),
          ),
        ],
      ),
    );
  }
}
