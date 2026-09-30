import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/widgets/empty_state.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders the title and the message', (tester) async {
    await tester.pumpWidget(
      wrap(const EmptyState(title: 'Nothing here', message: 'Add something')),
    );

    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Add something'), findsOneWidget);
  });

  testWidgets('renders the action when one is provided', (tester) async {
    await tester.pumpWidget(
      wrap(
        EmptyState(
          title: 'Nothing here',
          message: 'Add something',
          action: ElevatedButton(onPressed: () {}, child: const Text('Do it')),
        ),
      ),
    );

    expect(find.widgetWithText(ElevatedButton, 'Do it'), findsOneWidget);
  });

  testWidgets('omits the action when none is provided', (tester) async {
    await tester.pumpWidget(
      wrap(const EmptyState(title: 'Nothing here', message: 'Add something')),
    );

    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('body text uses the theme styles and is at least 16 sp', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const EmptyState(title: 'Nothing here', message: 'Add something')),
    );

    final context = tester.element(find.byType(EmptyState));
    final textTheme = Theme.of(context).textTheme;
    final title = tester.widget<Text>(find.text('Nothing here'));
    final message = tester.widget<Text>(find.text('Add something'));

    expect(title.style, textTheme.titleLarge);
    expect(message.style, textTheme.bodyLarge);
    expect(message.style!.fontSize, greaterThanOrEqualTo(16.0));
  });
}
