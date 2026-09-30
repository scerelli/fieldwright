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
  String get sitesEmptyTitle => 'No sites';

  @override
  String get sitesEmptyMessage => 'Add a planned site to start.';

  @override
  String get sitesAddSite => 'Add site';

  @override
  String get sitesCreateHere => 'Create site here';

  @override
  String get sitesCreateHereFailed => 'Could not get your location. Try again.';

  @override
  String get siteEditorNewTitle => 'New site';

  @override
  String get siteEditorUpdateTitle => 'Update site';

  @override
  String get siteGeometryPoint => 'Point';

  @override
  String get siteGeometryLine => 'Line';

  @override
  String get siteGeometryPolygon => 'Polygon';

  @override
  String get siteEditorLatitude => 'Latitude';

  @override
  String get siteEditorLongitude => 'Longitude';

  @override
  String get siteEditorAddVertex => 'Add point';

  @override
  String get siteEditorRemoveVertex => 'Remove point';

  @override
  String get siteEditorSave => 'Save site';

  @override
  String get siteEditorInvalidGeometry => 'Enter a valid geometry.';

  @override
  String get siteDetailTitle => 'Site details';

  @override
  String get siteDetailName => 'Name';

  @override
  String get siteDetailGeometry => 'Geometry';

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
