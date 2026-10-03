import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/app.dart';

Finder navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('the shell renders in Italian when the device locale is it', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = <Locale>[const Locale('it')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const ProviderScope(child: IbisApp()));
    await tester.pumpAndSettle();

    for (final label in ['Progetti', 'Siti', 'Visite', 'Account']) {
      expect(navLabel(label), findsOneWidget);
    }

    expect(find.widgetWithText(AppBar, 'Progetti'), findsOneWidget);
    expect(find.text('Nessun progetto'), findsOneWidget);
    expect(find.text('Crea un progetto per iniziare.'), findsOneWidget);
  });
}
