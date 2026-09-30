import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../auth/auth_client.dart';
import '../../auth/auth_provider.dart';
import '../../l10n/app_localizations.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    await ref
        .read(authProvider.notifier)
        .signIn(email: _email.text.trim(), password: _password.text);
  }

  Future<void> _signOut() => ref.read(authProvider.notifier).signOut();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAccount)),
      body: auth.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _signInForm(l10n, failed: true),
        data: (person) => person == null
            ? _signInForm(l10n, failed: false)
            : _signedIn(l10n, person),
      ),
    );
  }

  Widget _signInForm(AppLocalizations l10n, {required bool failed}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          key: const Key('auth_email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(labelText: l10n.authEmail),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('auth_password'),
          controller: _password,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(labelText: l10n.authPassword),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('auth_sign_in'),
          onPressed: _signIn,
          child: Text(l10n.authSignIn),
        ),
        if (failed) ...[
          const SizedBox(height: 16),
          Text(
            l10n.authSignInFailed,
            key: const Key('auth_error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  Widget _signedIn(AppLocalizations l10n, Person person) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.authSignedInAs(person.name)),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('auth_sign_out'),
          onPressed: _signOut,
          child: Text(l10n.authSignOut),
        ),
      ],
    );
  }
}
