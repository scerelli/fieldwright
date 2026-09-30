// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'IBIS';

  @override
  String get navProjects => 'Progetti';

  @override
  String get navSites => 'Siti';

  @override
  String get navVisits => 'Visite';

  @override
  String get navAccount => 'Account';

  @override
  String projectsCount(int count) {
    return 'Conteggio progetti: $count';
  }

  @override
  String get incrementProjects => 'Incrementa progetti';

  @override
  String sitesCount(int count) {
    return 'Conteggio siti: $count';
  }

  @override
  String get incrementSites => 'Incrementa siti';

  @override
  String visitsCount(int count) {
    return 'Conteggio visite: $count';
  }

  @override
  String get incrementVisits => 'Incrementa visite';

  @override
  String accountCount(int count) {
    return 'Conteggio account: $count';
  }

  @override
  String get incrementAccount => 'Incrementa account';
}
