// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'IBIS';

  @override
  String get navProjects => 'Projects';

  @override
  String get navSites => 'Sites';

  @override
  String get navVisits => 'Visits';

  @override
  String get navAccount => 'Account';

  @override
  String get projectsEmptyTitle => 'No project';

  @override
  String get projectsEmptyMessage => 'Create or join a project to get started.';

  @override
  String sitesCount(int count) {
    return 'Sites count: $count';
  }

  @override
  String get incrementSites => 'Increment Sites';

  @override
  String visitsCount(int count) {
    return 'Visits count: $count';
  }

  @override
  String get incrementVisits => 'Increment Visits';

  @override
  String accountCount(int count) {
    return 'Account count: $count';
  }

  @override
  String get incrementAccount => 'Increment Account';
}
