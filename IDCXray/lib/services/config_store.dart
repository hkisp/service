import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vless_node.dart';
import 'vless_parser.dart';

/// Local persistence. Full URI goes to secure storage; prefs hold non-secrets.
class ConfigStore {
  ConfigStore({
    FlutterSecureStorage? secure,
    SharedPreferences? prefs,
  })  : _secure = secure ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ),
        _prefsOverride = prefs;

  static const _uriKey = 'idcxray_node_uri';
  static const _coreKey = 'idcxray_core_engine'; // xray | singbox
  static const _hasNodeKey = 'idcxray_has_node';

  final FlutterSecureStorage _secure;
  final SharedPreferences? _prefsOverride;
  SharedPreferences? _prefs;

  Future<SharedPreferences> _sp() async {
    return _prefsOverride ?? (_prefs ??= await SharedPreferences.getInstance());
  }

  /// Load saved node, or null if none.
  Future<VlessNode?> loadNode() async {
    final prefs = await _sp();
    final has = prefs.getBool(_hasNodeKey) ?? false;
    if (!has) return null;

    String? uri;
    try {
      uri = await _secure.read(key: _uriKey);
    } catch (_) {
      // Fallback if secure storage unavailable (e.g. some Linux test envs).
      uri = prefs.getString('${_uriKey}_fallback');
    }
    if (uri == null || uri.isEmpty) return null;
    try {
      return parseVlessUri(uri);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveNode(VlessNode node) async {
    final prefs = await _sp();
    try {
      await _secure.write(key: _uriKey, value: node.uri);
      await prefs.remove('${_uriKey}_fallback');
    } catch (_) {
      // Last resort local fallback — still device-local, not uploaded.
      await prefs.setString('${_uriKey}_fallback', node.uri);
    }
    await prefs.setBool(_hasNodeKey, true);
    // Store only non-sensitive display helpers.
    await prefs.setString('idcxray_node_remark', node.remark);
    await prefs.setString('idcxray_node_host_mask', node.maskedHost);
  }

  Future<void> clearNode() async {
    final prefs = await _sp();
    try {
      await _secure.delete(key: _uriKey);
    } catch (_) {}
    await prefs.remove('${_uriKey}_fallback');
    await prefs.setBool(_hasNodeKey, false);
    await prefs.remove('idcxray_node_remark');
    await prefs.remove('idcxray_node_host_mask');
  }

  Future<String> loadCoreEngine() async {
    final prefs = await _sp();
    final v = prefs.getString(_coreKey) ?? 'xray';
    return (v == 'singbox') ? 'singbox' : 'xray';
  }

  Future<void> saveCoreEngine(String engine) async {
    final prefs = await _sp();
    await prefs.setString(_coreKey, engine == 'singbox' ? 'singbox' : 'xray');
  }
}
