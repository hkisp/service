import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/vless_node.dart';
import '../services/config_store.dart';
import '../services/vless_parser.dart';
import '../theme/app_theme.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({
    super.key,
    required this.store,
    this.current,
    required this.onChanged,
  });

  final ConfigStore store;
  final VlessNode? current;
  final ValueChanged<VlessNode?> onChanged;

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  late final TextEditingController _ctrl;
  String? _error;
  VlessNode? _preview;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.current == null ? '' : '',
    );
    // Do not prefill full secret URI into the text field by default.
    _preview = widget.current;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _import(String raw) async {
    setState(() {
      _error = null;
      _preview = null;
    });
    try {
      final node = parseVlessUri(raw);
      await widget.store.saveNode(node);
      setState(() {
        _preview = node;
        _ctrl.clear();
      });
      widget.onChanged(node);
      _snack('已保存：${node.displayName}');
    } on VlessParseException catch (e) {
      setState(() => _error = e.toString());
    } catch (e) {
      setState(() => _error = '导入失败');
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      _snack('剪贴板是空的');
      return;
    }
    _ctrl.text = text;
    await _import(text);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除节点？'),
        content: const Text('将从本机删除已保存的配置，不会上传到任何服务器。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    await widget.store.clearNode();
    setState(() {
      _preview = null;
      _ctrl.clear();
      _error = null;
    });
    widget.onChanged(null);
    _snack('已删除节点');
  }

  @override
  Widget build(BuildContext context) {
    final node = _preview;
    return Scaffold(
      appBar: AppBar(title: const Text('配置管理')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (node != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.dns, color: IdcColors.cyan),
                title: Text(node.displayName),
                subtitle: Text(
                  '${node.maskedHost}\n${node.protocolSummary}\nfp=${node.fingerprint}  flow=${node.flow}',
                ),
                isThreeLine: true,
              ),
            )
          else
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline, color: IdcColors.muted),
                title: Text('尚未导入节点'),
                subtitle: Text('粘贴你的 vless:// 链接（含 REALITY 参数）'),
              ),
            ),
          const SizedBox(height: 20),
          const Text('导入 VLESS URI', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            minLines: 4,
            maxLines: 8,
            obscureText: false,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            decoration: const InputDecoration(
              hintText:
                  'vless://YOUR_UUID@example.com:443?encryption=none&flow=xtls-rprx-vision&type=tcp&security=reality&fp=chrome&sni=www.example.com&pbk=YOUR_PUBLIC_KEY&sid=YOUR_SHORT_ID#备注名',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: IdcColors.danger)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _import(_ctrl.text),
                icon: const Icon(Icons.save),
                label: const Text('保存'),
              ),
              OutlinedButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.content_paste),
                label: const Text('从剪贴板粘贴'),
              ),
              if (node != null)
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, color: IdcColors.danger),
                  label: const Text('删除', style: TextStyle(color: IdcColors.danger)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '隐私说明：链接仅保存在本机（优先系统安全存储）。应用不会上传节点配置，也不会在日志中打印完整 URI。',
            style: TextStyle(color: IdcColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
