import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ibis/app.dart';

void main() {
  testWidgets('the root widget reads its title from Riverpod', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appTitleProvider.overrideWithValue('Overridden IBIS')],
        child: const IbisApp(),
      ),
    );

    expect(find.widgetWithText(AppBar, 'Overridden IBIS'), findsOneWidget);
  });
}
