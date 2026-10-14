import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bir_omur/main.dart';

void main() {
  testWidgets('Uygulama açılıyor ve başlığı gösteriyor', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BirOmurApp()));
    await tester.pumpAndSettle();
    expect(find.text('Bir Ömür'), findsOneWidget);
  });
}
