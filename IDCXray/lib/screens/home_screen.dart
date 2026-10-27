import 'package:flutter/material.dart';

import '../models/vless_node.dart';
import '../services/config_store.dart';
import '../services/vpn_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/connect_button.dart';
import 'config_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ConfigStore _store = ConfigStore();
  final VpnController _vpn = VpnController();

  VlessNode? _node;
  String _core = 'xray';
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    _core = await _store.loadCoreEngine();
    _node = await _store.loadNode();
    await _vpn.initialize(coreEngine: _core);
    _vpn.addListener(_onVpn);
    if (mounted) setState(() => _booting = false);
  }

  void _onVpn() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vpn.removeListener(_onVpn);
    _vpn.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _toggle() async {
    final phase = _vpn.phase;
    if (phase == ConnPhase.connecting || phase == ConnPhase.disconnecting) {
      return;
    }
    if (phase == ConnPhase.connected) {
      final err = await _vpn.disconnect();
      if (err != null) _snack(err);
      return;
    }
    final node = _node;
    if (node == null) {
      _snack('请先在「配置管理」导入节点');
      await _openConfig();
      return;
    }
    final err = await _vpn.connect(node);
    if (err != null) _snack(err);
  }

  Future<void> _openConfig() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfigScreen(
          store: _store,
          current: _node,
          onChanged: (n) => setState(() => _node = n),
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          store: _store,
          coreEngine: _core,
          onCoreChanged: (e) async {
            setState(() => _core = e);
            await _vpn.setCoreEngine(e);
          },
        ),
      ),
    );
  }

  Color _statusColor(ConnPhase p) {
    switch (p) {
      case ConnPhase.connected:
        return IdcColors.ok;
      case ConnPhase.connecting:
      case ConnPhase.disconnecting:
        return IdcColors.warn;
      case ConnPhase.error:
        return IdcColors.danger;
      case ConnPhase.disconnected:
        return IdcColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booting || !_vpn.ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: IdcColors.cyan)),
      );
    }

    final phase = _vpn.phase;
    final node = _node;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: '配置管理',
                    onPressed: _openConfig,
                    icon: const Icon(Icons.tune, color: IdcColors.cyan),
                  ),
                  const Expanded(
                    child: Text(
                      'IDCXray',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: IdcColors.text,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '设置',
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings_outlined, color: IdcColors.muted),
                  ),
                ],
              ),
            ),
            if (_vpn.initError != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: const Color(0xFF3F1D1D),
                  child: ListTile(
                    leading: const Icon(Icons.error_outline, color: IdcColors.danger),
                    title: Text('初始化失败：${_vpn.initError}'),
                  ),
                ),
              ),
            const Spacer(flex: 2),
            ConnectButton(phase: phase, onPressed: _toggle),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 10, color: _statusColor(phase)),
                const SizedBox(width: 8),
                Text(
                  phase.labelZh,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              node?.displayName ?? '未配置节点',
              style: TextStyle(
                color: node == null ? IdcColors.muted : IdcColors.text,
                fontSize: 16,
              ),
            ),
            if (node != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${node.maskedHost} · ${node.protocolSummary}',
                  style: const TextStyle(color: IdcColors.muted, fontSize: 12),
                ),
              ),
            if (phase == ConnPhase.connected) ...[
              const SizedBox(height: 12),
              Text(
                formatDuration(_vpn.duration),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: IdcColors.cyan,
                ),
              ),
              if (_vpn.traffic.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_vpn.traffic, style: const TextStyle(color: IdcColors.muted)),
                ),
            ],
            if (phase == ConnPhase.error && _vpn.lastError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(
                  _vpn.lastError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: IdcColors.danger, fontSize: 13),
                ),
              ),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TextButton.icon(
                onPressed: _openConfig,
                icon: const Icon(Icons.add_link),
                label: Text(node == null ? '导入节点配置' : '管理节点配置'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
