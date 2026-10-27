import 'package:flutter_test/flutter_test.dart';
import 'package:myvpn/main.dart';

void main() {
  test('type=raw is normalized to type=tcp', () {
    const raw =
        'vless://u@1.2.3.4:443?flow=xtls-rprx-vision&type=raw&security=reality#n';
    expect(normalizeLink(raw), contains('type=tcp'));
    expect(normalizeLink(raw), isNot(contains('type=raw')));
  });

  test('preset link name and server', () {
    expect(linkName(kPresetLink), 'gcp-38501');
    expect(linkServer(kPresetLink), '34.83.155.49:38501');
  });
}
