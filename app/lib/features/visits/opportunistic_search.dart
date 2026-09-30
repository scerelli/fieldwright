import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import 'taxon_reference.dart';

/// The abbreviation-search picker for opportunistic taxa (UX-005). The
/// collector types an abbreviation and picks a taxon from the matching list;
/// the list is the only way to add a taxon, so free text alone never creates a
/// Detection. An empty query lists every taxon in the reference.
class OpportunisticSearch extends ConsumerStatefulWidget {
  const OpportunisticSearch({super.key, required this.onPick});

  final ValueChanged<Taxon> onPick;

  @override
  ConsumerState<OpportunisticSearch> createState() =>
      _OpportunisticSearchState();
}

class _OpportunisticSearchState extends ConsumerState<OpportunisticSearch> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pick(Taxon taxon) {
    widget.onPick(taxon);
    _controller.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final results = ref.watch(taxonReferenceProvider).search(_query);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('opportunistic_search_field'),
          controller: _controller,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            labelText: l10n.opportunisticSearchLabel,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 8),
        if (results.isEmpty)
          Text(
            l10n.opportunisticNoResults,
            key: const Key('opportunistic_no_results'),
          )
        else
          for (final taxon in results)
            ListTile(
              key: Key('opportunistic_result_${taxon.abbreviation}'),
              contentPadding: EdgeInsets.zero,
              title: Text(taxon.name),
              subtitle: Text(taxon.abbreviation),
              onTap: () => _pick(taxon),
            ),
      ],
    );
  }
}
