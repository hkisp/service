import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2ray_box/v2ray_box.dart';

/// 预置节点（Google Cloud 美西，VLESS + REALITY + Vision）。
/// 服务端用的是 Xray 的 `raw` 传输，等同于 `tcp`，这里写成 `type=tcp`
/// 以兼容插件里的 sing-box / Xray 解析器。
const String kPresetLink =
    'vless://eae04e9d-d13f-431e-863b-0b0aaf5f67a5@34.83.155.49:38501'
    '?encryption=none&flow=xtls-rprx-vision&type=tcp&headerType=none'
    '&security=reality&fp=chrome&sni=swdist.apple.com'
    '&pbk=QZETr5Q1GWKaSeoPnNM4_l1sjAmrPnQqo_gPYt10QUY'
    '&sid=59afe83759eacc15#gcp-38501';

const String _prefsKey = 'node_link';

/// 把 `type=raw` 统一换成 `type=tcp`（两者在 Xray 里是同一种传输）。
String normalizeLink(String link) {
  var l = link.trim();
  l = l.replaceAll(RegExp(r'([?&])type=raw(?=&|#|$)'), r'$1type=tcp');
  return l;
}

/// 取链接 # 后面的备注名。
String linkName(String link) {
  final i = link.indexOf('#');
  if (i < 0 || i == link.length - 1) return '我的节点';
  try {
    return Uri.decodeComponent(link.substring(i + 1));
  } catch (_) {
    return link.substring(i + 1);
  }
}

/// 取 host:port 用于显示。
String linkServer(String link) {
  final m = RegExp(r'@([^?#/]+)').firstMatch(link);
  return m?.group(1) ?? '';
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyVpnApp());
}

class MyVpnApp extends StatelessWidget {
  const MyVpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyVPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final V2rayBox _box = V2rayBox();
  final TextEditingController _linkCtrl = TextEditingController();

  StreamSubscription<VpnStatus>? _statusSub;
  StreamSubscription<VpnStats>? _statsSub;

  VpnStatus _status = VpnStatus.stopped;
  String _link = kPresetLink;
  String _traffic = '';
  bool _ready = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.isNotEmpty) _link = saved;
    _linkCtrl.text = _link;

    try {
      await _box.initialize(notificationStopButtonText: '断开');
      // 只打包 Xray 内核也可以；默认用 Xray-core（与服务端一致）。
      await _box.setCoreEngine('xray');
      await _box.setServiceMode(VpnMode.vpn);
      _statusSub = _box.watchStatus().listen((s) {
        if (mounted) setState(() => _status = s);
      });
      _statsSub = _box.watchStats().listen((s) {
        if (mounted) {
          setState(() => _traffic =
              '↑ ${s.formattedUplink}   ↓ ${s.formattedDownlink}');
        }
      });
    } catch (e) {
      _initError = '$e';
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _statsSub?.cancel();
    _linkCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _saveLink(String raw) async {
    final link = normalizeLink(raw);
    if (!link.startsWith('vless://') || !_box.isValidConfigLink(link)) {
      _snack('链接格式不对，请粘贴完整的 vless:// 链接');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, link);
    setState(() {
      _link = link;
      _linkCtrl.text = link;
    });
    _snack('已保存节点：${linkName(link)}');
    if (_status == VpnStatus.started) {
      _snack('节点已更换，请断开后重新连接');
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      _snack('剪贴板是空的');
      return;
    }
    _linkCtrl.text = text;
    await _saveLink(text);
  }

  Future<void> _resetPreset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    setState(() {
      _link = kPresetLink;
      _linkCtrl.text = kPresetLink;
    });
    _snack('已恢复预置节点');
  }

  Future<void> _toggle() async {
    if (_status == VpnStatus.starting || _status == VpnStatus.stopping) return;

    if (_status == VpnStatus.started) {
      setState(() => _status = VpnStatus.stopping);
      try {
        await _box.disconnect();
      } catch (e) {
        _snack('断开失败：$e');
      }
      return;
    }

    setState(() => _status = VpnStatus.starting);
    try {
      final link = normalizeLink(_link);
      if (!await _box.checkVpnPermission()) {
        final granted = await _box.requestVpnPermission();
        if (!granted) {
          setState(() => _status = VpnStatus.stopped);
          _snack('需要允许添加 VPN 配置才能连接');
          return;
        }
      }
      final err = await _box.parseConfig(link);
      if (err.isNotEmpty) {
        setState(() => _status = VpnStatus.stopped);
        _snack('节点配置有误：$err');
        return;
      }
      final ok = await _box.connect(link, name: linkName(link));
      if (!ok && mounted) {
        setState(() => _status = VpnStatus.stopped);
        _snack('连接失败');
      }
    } catch (e) {
      if (mounted) setState(() => _status = VpnStatus.stopped);
      _snack('连接失败：$e');
    }
  }

  ({String text, Color color}) get _statusView {
    switch (_status) {
      case VpnStatus.started:
        return (text: '已连接', color: Colors.green);
      case VpnStatus.starting:
        return (text: '正在连接…', color: Colors.orange);
      case VpnStatus.stopping:
        return (text: '正在断开…', color: Colors.orange);
      case VpnStatus.stopped:
        return (text: '未连接', color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sv = _statusView;
    final connected = _status == VpnStatus.started;
    final busy =
        _status == VpnStatus.starting || _status == VpnStatus.stopping;

    return Scaffold(
      appBar: AppBar(title: const Text('MyVPN')),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_initError != null)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('初始化失败：$_initError'),
                      ),
                    ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.dns),
                      title: Text(linkName(_link)),
                      subtitle: Text('${linkServer(_link)}\nVLESS · REALITY · Vision'),
                      isThreeLine: true,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: ElevatedButton(
                        onPressed: busy ? null : _toggle,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor:
                              connected ? Colors.red.shade400 : Colors.indigo,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        child: busy
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(connected ? '断开' : '连接'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 12, color: sv.color),
                        const SizedBox(width: 8),
                        Text('状态：${sv.text}',
                            style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                  if (connected && _traffic.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Center(child: Text(_traffic)),
                  ],
                  const SizedBox(height: 36),
                  const Text('节点链接（粘贴新的 vless:// 链接可替换）',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _linkCtrl,
                    minLines: 3,
                    maxLines: 6,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'vless://...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _saveLink(_linkCtrl.text),
                        icon: const Icon(Icons.save),
                        label: const Text('保存'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pasteFromClipboard,
                        icon: const Icon(Icons.content_paste),
                        label: const Text('从剪贴板粘贴'),
                      ),
                      TextButton(
                        onPressed: _resetPreset,
                        child: const Text('恢复预置节点'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
