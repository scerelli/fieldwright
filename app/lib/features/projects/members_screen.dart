import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../projects/members_client.dart';

/// The Project members surface: lists a Project's Memberships and, for the
/// Project's creator, lets one be added with a grantable role (`DOMAIN.md`).
///
/// A non-creator sees the same list without the add action. The add form
/// validates the email and the role before any request leaves the device.
class MembersScreen extends StatefulWidget {
  const MembersScreen({
    super.key,
    required this.client,
    required this.projectId,
    required this.isCreator,
  });

  final MembersClient client;
  final String projectId;

  /// Whether the signed-in person is the Project's creator. Only a creator may
  /// grant a role, so only they see the add action.
  final bool isCreator;

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final TextEditingController _email = TextEditingController();
  List<Membership> _members = const <Membership>[];
  MembershipRole? _role;
  bool _loading = true;
  String? _loadError;
  String? _formError;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final members = await widget.client.list(widget.projectId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
      });
    } on MembersException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = AppLocalizations.of(context).membersLoadFailed;
      });
    }
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();
    if (email.isEmpty || !_emailPattern.hasMatch(email)) {
      setState(() => _formError = l10n.membersEmailRequired);
      return;
    }
    final role = _role;
    if (role == null) {
      setState(() => _formError = l10n.membersRoleRequired);
      return;
    }

    setState(() {
      _formError = null;
      _adding = true;
    });

    try {
      final member = await widget.client.add(
        projectId: widget.projectId,
        email: email,
        role: role,
      );
      if (!mounted) return;
      setState(() {
        _adding = false;
        _members = <Membership>[..._members, member];
        _email.clear();
        _role = null;
      });
    } on MembersException {
      if (!mounted) return;
      setState(() {
        _adding = false;
        _formError = l10n.membersAddFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.membersTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: const Key('members_list'),
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.isCreator) _buildAddForm(l10n),
                if (_loadError != null)
                  Padding(
                    key: const Key('members_error'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _loadError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (_members.isEmpty)
                  Text(l10n.membersEmpty)
                else
                  for (final member in _members)
                    ListTile(
                      key: Key('member_${member.id}'),
                      leading: const Icon(Icons.person_outline),
                      title: Text(
                        member.email.isEmpty ? member.personId : member.email,
                      ),
                      subtitle: Text(_roleLabel(l10n, member.role)),
                    ),
              ],
            ),
    );
  }

  Widget _buildAddForm(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.membersAddHeading,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('member_add_email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(labelText: l10n.membersEmail),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<MembershipRole>(
          key: const Key('member_add_role'),
          initialValue: _role,
          decoration: InputDecoration(labelText: l10n.membersRole),
          items: <DropdownMenuItem<MembershipRole>>[
            for (final role in MembershipRole.grantable)
              DropdownMenuItem<MembershipRole>(
                value: role,
                child: Text(_roleLabel(l10n, role)),
              ),
          ],
          onChanged: (value) => setState(() => _role = value),
        ),
        if (_formError != null)
          Padding(
            key: const Key('member_add_error'),
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _formError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('member_add_submit'),
          onPressed: _adding ? null : _add,
          child: Text(l10n.membersAdd),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

String _roleLabel(AppLocalizations l10n, MembershipRole role) => switch (role) {
  MembershipRole.creator => l10n.membershipRoleCreator,
  MembershipRole.collector => l10n.membershipRoleCollector,
  MembershipRole.validator => l10n.membershipRoleValidator,
};
