import 'package:flutter_test/flutter_test.dart';
import 'package:idcxray/models/vless_node.dart';
import 'package:idcxray/services/vless_parser.dart';

void main() {
  const valid =
      'vless://11111111-2222-3333-4444-555555555555@example.com:443'
      '?encryption=none&flow=xtls-rprx-vision&type=tcp&security=reality'
      '&fp=chrome&sni=www.example.com&pbk=PUBLICKEYEXAMPLE&sid=abcd1234#demo-node';

  test('parses valid VLESS REALITY Vision URI', () {
    final n = parseVlessUri(valid);
    expect(n.address, 'example.com');
    expect(n.port, 443);
    expect(n.uuid, '11111111-2222-3333-4444-555555555555');
    expect(n.security, 'reality');
    expect(n.flow, 'xtls-rprx-vision');
    expect(n.fingerprint, 'chrome');
    expect(n.sni, 'www.example.com');
    expect(n.publicKey, 'PUBLICKEYEXAMPLE');
    expect(n.shortId, 'abcd1234');
    expect(n.transport, 'tcp');
    expect(n.remark, 'demo-node');
    expect(n.displayName, 'demo-node');
  });

  test('normalizes type=raw to tcp', () {
    final raw = valid.replaceFirst('type=tcp', 'type=raw');
    final n = parseVlessUri(raw);
    expect(n.transport, 'tcp');
    expect(n.uri.contains('type=tcp'), isTrue);
    expect(n.uri.contains('type=raw'), isFalse);
  });

  test('accepts serverName as sni alias', () {
    final alt = valid.replaceFirst('sni=www.example.com', 'serverName=cdn.example.com');
    final n = parseVlessUri(alt);
    expect(n.sni, 'cdn.example.com');
  });

  test('rejects non-vless scheme', () {
    expect(
      () => parseVlessUri('vmess://abc'),
      throwsA(isA<VlessParseException>()),
    );
  });

  test('reports missing reality fields', () {
    const incomplete =
        'vless://11111111-2222-3333-4444-555555555555@example.com:443'
        '?type=tcp&security=tls&flow=xtls-rprx-vision';
    try {
      parseVlessUri(incomplete);
      fail('expected throw');
    } on VlessParseException catch (e) {
      expect(e.missingFields, contains('security=reality'));
      expect(e.missingFields, contains('pbk (REALITY 公钥)'));
      expect(e.missingFields, contains('sid (shortId)'));
      expect(e.missingFields, contains('sni / serverName'));
      expect(e.missingFields, contains('fp (fingerprint)'));
    }
  });

  test('rejects missing uuid/host/port', () {
    expect(
      () => parseVlessUri('vless://@/:0'),
      throwsA(isA<VlessParseException>()),
    );
  });

  test('masks host for display', () {
    final n = parseVlessUri(valid);
    expect(n.maskedHost.contains('example'), isFalse);
    expect(n.maskedHost.contains('…'), isTrue);
    expect(n.redactedUri.contains('1111'), isTrue);
    expect(n.redactedUri.contains('11111111-2222-3333-4444-555555555555'), isFalse);
  });

  test('trims whitespace from paste', () {
    final n = parseVlessUri('  $valid \n');
    expect(n.address, 'example.com');
  });
}
