import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navVisits)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.visitsCount(_count)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => setState(() => _count++),
              child: Text(l10n.incrementVisits),
            ),
          ],
        ),
      ),
    );
  }
}
