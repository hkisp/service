import '../models/vless_node.dart';

/// Normalize transport: Xray `raw` equals `tcp`.
String normalizeVlessUri(String raw) {
  var l = raw.trim();
  // Strip accidental whitespace / newlines from paste.
  l = l.replaceAll(RegExp(r'\s+'), '');
  // Dart replaceAll does not expand $1 backrefs — use mapped replace.
  l = l.replaceAllMapped(
    RegExp(r'([?&])type=raw(?=&|#|$)'),
    (m) => '${m[1]}type=tcp',
  );
  return l;
}

/// Parse and validate a VLESS + REALITY (+ Vision) share link.
///
/// Required for this app's MVP:
/// address, port, uuid, security=reality, pbk, sid, sni (or serverName),
/// fp, flow, type (tcp/raw).
VlessNode parseVlessUri(String raw) {
  final link = normalizeVlessUri(raw);
  if (!link.toLowerCase().startsWith('vless://')) {
    throw VlessParseException(const [], message: '必须以 vless:// 开头');
  }

  final missing = <String>[];

  Uri uri;
  try {
    uri = Uri.parse(link);
  } catch (_) {
    throw VlessParseException(const [], message: '无法解析链接（URL 编码有误）');
  }

  if (uri.scheme.toLowerCase() != 'vless') {
    throw VlessParseException(const [], message: '必须以 vless:// 开头');
  }

  final uuid = uri.userInfo;
  if (uuid.isEmpty || !_looksLikeUuid(uuid)) {
    missing.add('uuid');
  }

  final address = uri.host;
  if (address.isEmpty) missing.add('address');

  final port = uri.hasPort ? uri.port : 0;
  if (port <= 0 || port > 65535) missing.add('port');

  final q = uri.queryParameters;
  String qp(String key, [String alt = '']) {
    final v = q[key] ?? (alt.isEmpty ? null : q[alt]);
    return (v ?? '').trim();
  }

  final security = qp('security').toLowerCase();
  if (security != 'reality') missing.add('security=reality');

  final pbk = qp('pbk');
  if (pbk.isEmpty) missing.add('pbk (REALITY 公钥)');

  final sid = qp('sid');
  if (sid.isEmpty) missing.add('sid (shortId)');

  final sni = qp('sni', 'serverName');
  if (sni.isEmpty) missing.add('sni / serverName');

  final fp = qp('fp');
  if (fp.isEmpty) missing.add('fp (fingerprint)');

  final flow = qp('flow');
  if (flow.isEmpty) missing.add('flow');
  // Accept vision flow; warn via missing if clearly wrong empty already handled.

  var type = qp('type').toLowerCase();
  if (type.isEmpty) {
    missing.add('type (tcp/raw)');
  } else if (type == 'raw') {
    type = 'tcp';
  }

  if (missing.isNotEmpty) {
    throw VlessParseException(missing);
  }

  var remark = '';
  if (uri.fragment.isNotEmpty) {
    try {
      remark = Uri.decodeComponent(uri.fragment);
    } catch (_) {
      remark = uri.fragment;
    }
  }

  // Rebuild normalized URI (type=tcp) keeping original query order-ish.
  final normalized = normalizeVlessUri(link);

  return VlessNode(
    uri: normalized,
    uuid: uuid,
    address: address,
    port: port,
    security: security,
    flow: flow,
    fingerprint: fp,
    sni: sni,
    publicKey: pbk,
    shortId: sid,
    transport: type,
    remark: remark,
  );
}

bool _looksLikeUuid(String s) {
  // Accept standard UUID or plain id strings used by some panels (≥8 chars).
  if (s.length < 8) return false;
  final uuidRe = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  if (uuidRe.hasMatch(s)) return true;
  return RegExp(r'^[0-9a-zA-Z\-_]{8,64}$').hasMatch(s);
}

/// Extract remark without full parse (best-effort).
String remarkFromUri(String link) {
  final i = link.indexOf('#');
  if (i < 0 || i == link.length - 1) return '';
  try {
    return Uri.decodeComponent(link.substring(i + 1));
  } catch (_) {
    return link.substring(i + 1);
  }
}
