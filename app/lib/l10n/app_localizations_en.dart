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
  String get projectsEmptyMessage => 'Create a project to get started.';

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
  String get visitStateSubmitted => 'Submitted';

  @override
  String get visitDetailTitle => 'Visit details';

  @override
  String get visitDetailStatus => 'Validation status';

  @override
  String get visitStatusSubmitted => 'Submitted';

  @override
  String get visitStatusValidated => 'Validated';

  @override
  String get visitStatusRejected => 'Rejected';

  @override
  String get visitDetailCorrectionsHeading => 'Corrections';

  @override
  String get visitDetailCorrectionsEmpty => 'This visit has no corrections.';

  @override
  String get visitDetailLoadFailed => 'Could not load the visit. Try again.';

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
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignInFailed =>
      'Sign-in failed. Check your email and password.';

  @override
  String get authSignOut => 'Sign out';

  @override
  String authSignedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get authName => 'Name';

  @override
  String get authSignUp => 'Create account';

  @override
  String get authSwitchToSignUp => 'Create an account';

  @override
  String get authSwitchToSignIn => 'Back to sign in';

  @override
  String get authNameRequired => 'Enter your name.';

  @override
  String get authEmailInvalid => 'Enter a valid email.';

  @override
  String get authPasswordTooShort => 'Use at least 8 characters.';

  @override
  String get authSignUpFailed =>
      'Could not create the account. Check your details and try again.';

  @override
  String get evidencePhoto => 'Photo';

  @override
  String get evidenceAudio => 'Audio';

  @override
  String get evidenceStop => 'Stop';

  @override
  String get evidenceCaptureFailed => 'Could not capture evidence. Try again.';

  @override
  String get visitCovariatesHeading => 'Visit covariates';

  @override
  String get measurementManualFallback => 'Manual entry (sensor unavailable)';

  @override
  String get measurementLowConfidence =>
      'Low confidence (sensor not calibrated)';

  @override
  String get measurementMethod => 'Method';

  @override
  String get measurementMissingMethod => 'Select a method for each value.';

  @override
  String get measurementSave => 'Save measurements';

  @override
  String get projectsCreateProject => 'Create project';

  @override
  String get projectEditorNewTitle => 'New project';

  @override
  String get projectEditorName => 'Project name';

  @override
  String get projectEditorReferenceId => 'Taxonomic reference';

  @override
  String get projectEditorReferenceVersion => 'Taxonomic reference version';

  @override
  String get projectEditorValidation => 'Validation';

  @override
  String get projectEditorObfuscation => 'Sensitive-taxa obfuscation';

  @override
  String get projectEditorSave => 'Save project';

  @override
  String get projectEditorNameRequired => 'Enter a project name.';

  @override
  String get projectEditorReferenceRequired => 'Select a taxonomic reference.';

  @override
  String get projectEditorVersionRequired =>
      'Enter a taxonomic reference version.';

  @override
  String get projectEditorCreateFailed =>
      'Could not create the project. Try again.';

  @override
  String get projectEditorReferenceIdHelper =>
      'The checklist the Project\'s taxon names resolve against.';

  @override
  String get projectEditorReferenceVersionHelper =>
      'The exact checklist version pinned to the Project; taxon names resolve against it before submission.';

  @override
  String get projectEditorSaveFailed =>
      'Could not save the project. Try again.';

  @override
  String get projectSettingsNotFound => 'This Project is not on this device.';

  @override
  String get projectSettingsTitle => 'Project settings';

  @override
  String get protocolVersionTitle => 'Protocol version';

  @override
  String get protocolVersionNewTitle => 'New protocol version';

  @override
  String get protocolVersionProtocolId => 'Protocol ID';

  @override
  String get protocolVersionTaxonomicScope => 'Taxonomic scope';

  @override
  String get protocolVersionCompleteListMode => 'Complete-list mode';

  @override
  String get protocolVersionTargetList => 'Target list';

  @override
  String get protocolVersionDetectionMethods => 'Detection methods';

  @override
  String get protocolVersionRequiredEffort => 'Required effort fields';

  @override
  String get protocolVersionVisitCovariates => 'Visit covariates';

  @override
  String get protocolVersionSiteCovariates => 'Site covariates';

  @override
  String get effortFieldStart => 'Start';

  @override
  String get effortFieldDuration => 'Duration';

  @override
  String get effortFieldObservers => 'Observers';

  @override
  String get effortFieldDetectionMethods => 'Detection methods';

  @override
  String get protocolVersionSave => 'Save protocol version';

  @override
  String get protocolVersionFrozen => 'Frozen';

  @override
  String get protocolVersionCreateNew => 'Create a new version';

  @override
  String protocolVersionVersion(int version) {
    return 'Version $version';
  }

  @override
  String get protocolVersionReadOnly =>
      'This version is frozen and can no longer change. Create a new version to make changes.';

  @override
  String get protocolVersionProtocolIdRequired => 'Enter a protocol ID.';

  @override
  String get protocolVersionScopeRequired =>
      'Enter at least one taxon in scope.';

  @override
  String get protocolVersionTargetListRequired =>
      'Enter at least one target taxon or use complete-list mode.';

  @override
  String get protocolVersionDetectionMethodsRequired =>
      'Enter at least one detection method.';

  @override
  String get protocolVersionEffortRequired =>
      'Select at least one required effort field.';

  @override
  String get protocolVersionInvalidCovariates =>
      'Enter each covariate as name:type[:unit], or leave the field empty.';

  @override
  String get protocolVersionCreateFailed =>
      'Could not save the protocol version. Try again.';

  @override
  String get membersTitle => 'Members';

  @override
  String get membersEmpty => 'No members yet.';

  @override
  String get membersLoadFailed => 'Could not load the members. Try again.';

  @override
  String get membersAddHeading => 'Add member';

  @override
  String get membersEmail => 'Email';

  @override
  String get membersRole => 'Role';

  @override
  String get membersAdd => 'Add member';

  @override
  String get membersEmailRequired => 'Enter a valid email.';

  @override
  String get membersRoleRequired => 'Select a role.';

  @override
  String get membersAddFailed => 'Could not add the member. Try again.';

  @override
  String get membershipRoleCreator => 'Creator';

  @override
  String get membershipRoleCollector => 'Collector';

  @override
  String get membershipRoleValidator => 'Validator';

  @override
  String get surveyPeriodsTitle => 'Survey periods';

  @override
  String get surveyPeriodsEmpty => 'No survey periods yet.';

  @override
  String get surveyPeriodsLoadFailed =>
      'Could not load the survey periods. Try again.';

  @override
  String get surveyPeriodsAddHeading => 'Add survey period';

  @override
  String get surveyPeriodName => 'Name';

  @override
  String get surveyPeriodStartDate => 'Start date';

  @override
  String get surveyPeriodEndDate => 'End date';

  @override
  String get surveyPeriodsAdd => 'Add survey period';

  @override
  String get surveyPeriodNameRequired => 'Enter a name.';

  @override
  String get surveyPeriodStartRequired => 'Enter a start date.';

  @override
  String get surveyPeriodEndRequired => 'Enter an end date.';

  @override
  String get surveyPeriodInvalidDate => 'Enter each date as YYYY-MM-DD.';

  @override
  String get surveyPeriodEndBeforeStart =>
      'The end date cannot precede the start date.';

  @override
  String get surveyPeriodsAddFailed =>
      'Could not add the survey period. Try again.';

  @override
  String get syncIndicatorQueued => 'Queued';

  @override
  String get syncIndicatorSyncing => 'Syncing';

  @override
  String get syncIndicatorSynced => 'Synced';

  @override
  String get syncIndicatorFailed => 'Sync failed';

  @override
  String get syncIndicatorRetry => 'Retry';

  @override
  String get helpTitle => 'Manual';

  @override
  String get helpOpen => 'Open the manual';

  @override
  String get helpCreateProjectTitle => 'Create a Project';

  @override
  String get helpCreateProjectBody =>
      'From the Projects list, tap + to create a Project — no account needed. Name it and pin a taxonomic reference; you can add a Protocol version, Survey periods and Sites afterwards.';

  @override
  String get helpCaptureVisitTitle => 'Capture a Visit';

  @override
  String get helpCaptureVisitBody =>
      'Open a Project and start a Visit at a Site; the effort timer starts. Record each target taxon as detected or not detected, add opportunistic taxa and Evidence, then end the Visit.';

  @override
  String get helpSubmitVisitTitle => 'Submit the Visit';

  @override
  String get helpSubmitVisitBody =>
      'Submit an ended Visit when you have a connection. Submission is safe to retry, the Visit becomes immutable, and a validator may validate it when the Project enables validation.';

  @override
  String get needsAttentionTitle => 'Needs attention';

  @override
  String get needsAttentionProtocolVersion => 'No Protocol version';

  @override
  String get needsAttentionSetProtocolVersion => 'Set Protocol version';

  @override
  String get needsAttentionSurveyPeriod => 'No Survey period';

  @override
  String get needsAttentionSetSurveyPeriod => 'Set Survey period';

  @override
  String get needsAttentionPinnedReference => 'No pinned reference';

  @override
  String get needsAttentionPinReference => 'Pin reference';

  @override
  String needsAttentionUnrecordedTargets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count targets not recorded',
      one: '1 target not recorded',
    );
    return '$_temp0';
  }

  @override
  String get needsAttentionRecordTargets => 'Record targets';

  @override
  String needsAttentionUnresolvedTaxa(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count taxa unresolved',
      one: '1 taxon unresolved',
    );
    return '$_temp0';
  }

  @override
  String get needsAttentionResolveTaxa => 'Resolve taxa';

  @override
  String get provisionalVisit => 'Provisional';

  @override
  String get projectCardNoReference => 'No reference pinned';
}
