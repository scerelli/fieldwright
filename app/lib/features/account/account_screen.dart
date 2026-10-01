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
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const int _minPasswordLength = 8;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _signingUp = false;
  String? _formError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showSignUp() {
    setState(() {
      _signingUp = true;
      _formError = null;
    });
  }

  void _showSignIn() {
    ref.invalidate(authProvider);
    setState(() {
      _signingUp = false;
      _formError = null;
    });
  }

  Future<void> _signIn() async {
    setState(() => _formError = null);
    await ref
        .read(authProvider.notifier)
        .signIn(email: _email.text.trim(), password: _password.text);
  }

  Future<void> _signUp() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    final invalid = _signUpValidationError(
      l10n,
      name: name,
      email: email,
      password: password,
    );
    if (invalid != null) {
      setState(() => _formError = invalid);
      return;
    }

    setState(() => _formError = null);
    await ref
        .read(authProvider.notifier)
        .signUp(name: name, email: email, password: password);
    if (!mounted) return;
    if (ref.read(authProvider).value != null) {
      setState(() => _signingUp = false);
    }
  }

  /// Reports a malformed sign-up without a request leaving the device.
  String? _signUpValidationError(
    AppLocalizations l10n, {
    required String name,
    required String email,
    required String password,
  }) {
    if (name.isEmpty) return l10n.authNameRequired;
    if (!_emailPattern.hasMatch(email)) return l10n.authEmailInvalid;
    if (password.length < _minPasswordLength) return l10n.authPasswordTooShort;
    return null;
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
        error: (error, stackTrace) => _form(
          l10n,
          error: _signingUp ? l10n.authSignUpFailed : l10n.authSignInFailed,
        ),
        data: (person) => person == null
            ? _form(l10n, error: _formError)
            : _signedIn(l10n, person),
      ),
    );
  }

  Widget _form(AppLocalizations l10n, {required String? error}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_signingUp) ...[
          TextField(
            key: const Key('auth_name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: InputDecoration(labelText: l10n.authName),
          ),
          const SizedBox(height: 16),
        ],
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
          autofillHints: _signingUp
              ? const [AutofillHints.newPassword]
              : const [AutofillHints.password],
          decoration: InputDecoration(labelText: l10n.authPassword),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: Key(_signingUp ? 'auth_sign_up' : 'auth_sign_in'),
          onPressed: _signingUp ? _signUp : _signIn,
          child: Text(_signingUp ? l10n.authSignUp : l10n.authSignIn),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: Key(
            _signingUp ? 'auth_switch_to_sign_in' : 'auth_switch_to_sign_up',
          ),
          onPressed: _signingUp ? _showSignIn : _showSignUp,
          child: Text(
            _signingUp ? l10n.authSwitchToSignIn : l10n.authSwitchToSignUp,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(
            error,
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
