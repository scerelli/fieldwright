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
  String get siteCovariatesTitle => 'Site covariates';

  @override
  String get siteCovariatesNone =>
      'No site covariates defined by the protocol.';

  @override
  String get siteCovariatesMethod => 'Method';

  @override
  String get siteCovariatesMissingMethod => 'Select a method for each value.';

  @override
  String get siteCovariatesSave => 'Save covariates';

  @override
  String get covariateMethodPhoneSensor => 'Phone sensor';

  @override
  String get covariateMethodFieldInstrument => 'Field instrument';

  @override
  String get covariateMethodVisualEstimate => 'Visual estimate';

  @override
  String get visitsEmptyTitle => 'No visits';

  @override
  String get visitsEmptyMessage => 'Start a visit from a site.';

  @override
  String get visitsSitesHeading => 'Sites';

  @override
  String get visitsListHeading => 'Visits';

  @override
  String get visitsStartVisit => 'Start visit';

  @override
  String get visitsEndVisit => 'End visit';

  @override
  String get visitsEndVisitTitle => 'End visit?';

  @override
  String get visitStateInProgress => 'In progress';

  @override
  String get visitStateEnded => 'Ended';

  @override
  String get captureTitle => 'Visit';

  @override
  String captureEffortStarted(String time) {
    return 'Effort started: $time';
  }

  @override
  String captureState(String state) {
    return 'State: $state';
  }

  @override
  String get detectionTargetsHeading => 'Target taxa';

  @override
  String get detectionDetected => 'Detected';

  @override
  String get detectionNotDetected => 'Not detected';

  @override
  String get detectionNotRecorded => 'Not recorded';

  @override
  String get detectionNextUnrecorded => 'Next unrecorded';

  @override
  String get detectionNoTargets => 'The protocol defines no target taxa.';

  @override
  String visitIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count targets not recorded',
      one: '1 target not recorded',
    );
    return '$_temp0';
  }

  @override
  String get visitAllTargetsRecorded => 'All targets recorded';

  @override
  String get opportunisticHeading => 'Opportunistic taxa';

  @override
  String get opportunisticSearchLabel => 'Search by abbreviation';

  @override
  String get opportunisticNoResults => 'No matching taxa';

  @override
  String get opportunisticPresenceOnly => 'Detected (opportunistic)';

  @override
  String accountCount(int count) {
    return 'Account count: $count';
  }

  @override
  String get incrementAccount => 'Increment Account';

  @override
  String get evidencePhoto => 'Photo';

  @override
  String get evidenceAudio => 'Audio';

  @override
  String get evidenceStop => 'Stop';

  @override
  String get evidenceCaptureFailed => 'Could not capture evidence. Try again.';
}
