import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:v2ray_box/v2ray_box.dart';

import '../models/vless_node.dart';

/// Maps plugin [VpnStatus] to Chinese UI labels. Never invents Connected.
enum ConnPhase {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

extension ConnPhaseLabel on ConnPhase {
  String get labelZh {
    switch (this) {
      case ConnPhase.disconnected:
        return '未连接';
      case ConnPhase.connecting:
        return '连接中';
      case ConnPhase.connected:
        return '已连接';
      case ConnPhase.disconnecting:
        return '断开中';
      case ConnPhase.error:
        return '错误';
    }
  }
}

ConnPhase phaseFromVpnStatus(VpnStatus s, {bool hadError = false}) {
  if (hadError && s == VpnStatus.stopped) return ConnPhase.error;
  switch (s) {
    case VpnStatus.started:
      return ConnPhase.connected;
    case VpnStatus.starting:
      return ConnPhase.connecting;
    case VpnStatus.stopping:
      return ConnPhase.disconnecting;
    case VpnStatus.stopped:
      return ConnPhase.disconnected;
  }
}

/// Thin wrapper around [V2rayBox]. Status comes only from plugin streams.
class VpnController extends ChangeNotifier {
  VpnController({V2rayBox? box}) : _box = box ?? V2rayBox();

  final V2rayBox _box;
  StreamSubscription<VpnStatus>? _statusSub;
  StreamSubscription<VpnStats>? _statsSub;
  Timer? _durationTimer;

  VpnStatus _raw = VpnStatus.stopped;
  bool _hadError = false;
  String? _lastError;
  String _traffic = '';
  DateTime? _connectedAt;
  Duration _duration = Duration.zero;
  bool _ready = false;
  String? _initError;

  bool get ready => _ready;
  String? get initError => _initError;
  String? get lastError => _lastError;
  String get traffic => _traffic;
  Duration get duration => _duration;
  VpnStatus get rawStatus => _raw;

  ConnPhase get phase => phaseFromVpnStatus(_raw, hadError: _hadError);

  Future<void> initialize({String coreEngine = 'xray'}) async {
    try {
      await _box.initialize(notificationStopButtonText: '断开');
      await _box.setCoreEngine(coreEngine);
      await _box.setServiceMode(VpnMode.vpn);
      _statusSub = _box.watchStatus().listen((s) {
        _raw = s;
        if (s == VpnStatus.started) {
          _hadError = false;
          _lastError = null;
          _connectedAt ??= DateTime.now();
          _ensureDurationTimer();
        } else if (s == VpnStatus.stopped) {
          _connectedAt = null;
          _duration = Duration.zero;
          _durationTimer?.cancel();
          _durationTimer = null;
          _traffic = '';
        }
        notifyListeners();
      });
      _statsSub = _box.watchStats().listen((s) {
        _traffic = '↑ ${s.formattedUplink}   ↓ ${s.formattedDownlink}';
        notifyListeners();
      });
    } catch (e) {
      _initError = '$e';
    }
    _ready = true;
    notifyListeners();
  }

  void _ensureDurationTimer() {
    _durationTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      final start = _connectedAt;
      if (start != null) {
        _duration = DateTime.now().difference(start);
        notifyListeners();
      }
    });
  }

  Future<String?> connect(VlessNode node) async {
    if (_raw == VpnStatus.starting || _raw == VpnStatus.stopping) {
      return '请等待当前操作完成';
    }
    _hadError = false;
    _lastError = null;
    notifyListeners();

    try {
      if (!await _box.checkVpnPermission()) {
        final granted = await _box.requestVpnPermission();
        if (!granted) {
          _hadError = true;
          _lastError = '需要允许添加 VPN 配置才能连接';
          notifyListeners();
          return _lastError;
        }
      }

      final err = await _box.parseConfig(node.uri);
      if (err.isNotEmpty) {
        _hadError = true;
        _lastError = '节点配置有误：$err';
        notifyListeners();
        return _lastError;
      }

      final ok = await _box.connect(node.uri, name: node.displayName);
      if (!ok) {
        _hadError = true;
        _lastError = '连接失败';
        notifyListeners();
        return _lastError;
      }
      return null;
    } catch (e) {
      _hadError = true;
      // Never include full URI in error surfaces.
      _lastError = '连接失败：${_sanitizeError('$e')}';
      notifyListeners();
      return _lastError;
    }
  }

  Future<String?> disconnect() async {
    try {
      await _box.disconnect();
      return null;
    } catch (e) {
      _lastError = '断开失败：${_sanitizeError('$e')}';
      notifyListeners();
      return _lastError;
    }
  }

  Future<void> setCoreEngine(String engine) async {
    await _box.setCoreEngine(engine);
  }

  String _sanitizeError(String e) {
    // Strip vless:// payloads if any leaked into exceptions.
    return e.replaceAll(RegExp(r'vless://' r'[^\s]+'), 'vless://***');
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _statsSub?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (h > 0) return '$h:$m:$s';
  return '$m:$s';
}
