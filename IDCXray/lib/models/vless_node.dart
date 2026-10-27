/// Parsed VLESS node. Secrets stay in memory / secure storage; never log [uri].
class VlessNode {
  const VlessNode({
    required this.uri,
    required this.uuid,
    required this.address,
    required this.port,
    required this.security,
    required this.flow,
    required this.fingerprint,
    required this.sni,
    required this.publicKey,
    required this.shortId,
    required this.transport,
    required this.remark,
  });

  final String uri;
  final String uuid;
  final String address;
  final int port;
  final String security;
  final String flow;
  final String fingerprint;
  final String sni;
  final String publicKey;
  final String shortId;
  final String transport;
  final String remark;

  /// Display name for UI (remark, or host masked).
  String get displayName {
    if (remark.trim().isNotEmpty) return remark.trim();
    return maskedHost;
  }

  /// Host with middle digits redacted for home screen.
  String get maskedHost {
    final host = address;
    if (host.length <= 8) return '$host:$port';
    final head = host.substring(0, 4);
    final tail = host.substring(host.length - 3);
    return '$head…$tail:$port';
  }

  String get protocolSummary => 'VLESS · ${security.toUpperCase()} · Vision';

  /// URI safe for UI text fields with UUID/pbk shortened.
  String get redactedUri {
    var s = uri;
    if (uuid.length > 8) {
      s = s.replaceFirst(uuid, '${uuid.substring(0, 4)}…${uuid.substring(uuid.length - 4)}');
    }
    if (publicKey.length > 10) {
      s = s.replaceFirst(
        publicKey,
        '${publicKey.substring(0, 4)}…${publicKey.substring(publicKey.length - 4)}',
      );
    }
    return s;
  }
}

/// Thrown when a VLESS URI is missing required fields or malformed.
class VlessParseException implements Exception {
  VlessParseException(this.missingFields, {this.message});

  final List<String> missingFields;
  final String? message;

  @override
  String toString() {
    if (message != null) return message!;
    if (missingFields.isEmpty) return 'VLESS 链接无效';
    return '缺少必要参数：${missingFields.join(', ')}';
  }
}
