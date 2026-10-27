import 'package:flutter_test/flutter_test.dart';
import 'package:idcxray/main.dart';

void main() {
  testWidgets('IDCXray app builds home brand', (tester) async {
    await tester.pumpWidget(const IdcXrayApp());
    // Allow async boot; plugin init may fail on Linux — brand still shows after boot or spinner.
    await tester.pump(const Duration(milliseconds: 100));
    // Either loading spinner or brand text is acceptable without iOS VPN stack.
    expect(find.text('IDCXray'), findsWidgets);
  }, skip: true); // Requires platform channels; covered by parser unit tests on Linux.
}
