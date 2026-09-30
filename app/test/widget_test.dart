import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ibis/app.dart';

void main() {
  testWidgets('the root widget sets its title from the localizations', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: IbisApp()));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.onGenerateTitle, isNotNull);

    final context = tester.element(find.byType(Scaffold).first);
    expect(app.onGenerateTitle!(context), 'IBIS');
  });
}
