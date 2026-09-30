import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAccount)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.accountCount(_count)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => setState(() => _count++),
              child: Text(l10n.incrementAccount),
            ),
          ],
        ),
      ),
    );
  }
}
