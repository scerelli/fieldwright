import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// Application name shown in the OS task switcher and window title.
  ///
  /// In en, this message translates to:
  /// **'IBIS'**
  String get appTitle;

  /// Bottom navigation destination label and Projects screen title.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get navProjects;

  /// Bottom navigation destination label and Sites screen title.
  ///
  /// In en, this message translates to:
  /// **'Sites'**
  String get navSites;

  /// Bottom navigation destination label and Visits screen title.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get navVisits;

  /// Bottom navigation destination label and Account screen title.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// Title of the Projects screen empty state shown when no project is configured.
  ///
  /// In en, this message translates to:
  /// **'No project'**
  String get projectsEmptyTitle;

  /// Message of the Projects screen empty state shown when no project is configured.
  ///
  /// In en, this message translates to:
  /// **'Create or join a project to get started.'**
  String get projectsEmptyMessage;

  /// Title of the Sites screen empty state shown before any site exists.
  ///
  /// In en, this message translates to:
  /// **'No sites'**
  String get sitesEmptyTitle;

  /// Message of the Sites screen empty state shown before any site exists.
  ///
  /// In en, this message translates to:
  /// **'Add a planned site to start.'**
  String get sitesEmptyMessage;

  /// Tooltip of the Sites screen button that opens the site editor.
  ///
  /// In en, this message translates to:
  /// **'Add site'**
  String get sitesAddSite;

  /// Tooltip of the Sites screen button that creates a site from the current location.
  ///
  /// In en, this message translates to:
  /// **'Create site here'**
  String get sitesCreateHere;

  /// Message shown when creating a site from the current location fails.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Try again.'**
  String get sitesCreateHereFailed;

  /// Title of the site editor when creating a new site.
  ///
  /// In en, this message translates to:
  /// **'New site'**
  String get siteEditorNewTitle;

  /// Title of the site editor when changing an existing site.
  ///
  /// In en, this message translates to:
  /// **'Update site'**
  String get siteEditorUpdateTitle;

  /// Geometry kind option for a site drawn as a single point.
  ///
  /// In en, this message translates to:
  /// **'Point'**
  String get siteGeometryPoint;

  /// Geometry kind option for a site drawn as a line.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get siteGeometryLine;

  /// Geometry kind option for a site drawn as a polygon.
  ///
  /// In en, this message translates to:
  /// **'Polygon'**
  String get siteGeometryPolygon;

  /// Label of a site vertex latitude field, in decimal degrees.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get siteEditorLatitude;

  /// Label of a site vertex longitude field, in decimal degrees.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get siteEditorLongitude;

  /// Button that adds another vertex to a line or polygon site.
  ///
  /// In en, this message translates to:
  /// **'Add point'**
  String get siteEditorAddVertex;

  /// Button that removes a vertex from a line or polygon site.
  ///
  /// In en, this message translates to:
  /// **'Remove point'**
  String get siteEditorRemoveVertex;

  /// Button that saves the site being edited.
  ///
  /// In en, this message translates to:
  /// **'Save site'**
  String get siteEditorSave;

  /// Error shown when the entered geometry cannot be saved.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid geometry.'**
  String get siteEditorInvalidGeometry;

  /// Heading of the detail shown when a site is tapped on the map.
  ///
  /// In en, this message translates to:
  /// **'Site details'**
  String get siteDetailTitle;

  /// Label of the site name shown in the site detail.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get siteDetailName;

  /// Label of the geometry shown in the site detail.
  ///
  /// In en, this message translates to:
  /// **'Geometry'**
  String get siteDetailGeometry;

  /// Heading of the site covariate entry shown for a site.
  ///
  /// In en, this message translates to:
  /// **'Site covariates'**
  String get siteCovariatesTitle;

  /// Message shown when the protocol defines no site covariates.
  ///
  /// In en, this message translates to:
  /// **'No site covariates defined by the protocol.'**
  String get siteCovariatesNone;

  /// Label of the provenance method selector for a site covariate value.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get siteCovariatesMethod;

  /// Error shown when a covariate value is entered without a provenance method.
  ///
  /// In en, this message translates to:
  /// **'Select a method for each value.'**
  String get siteCovariatesMissingMethod;

  /// Button that saves the entered site covariate values.
  ///
  /// In en, this message translates to:
  /// **'Save covariates'**
  String get siteCovariatesSave;

  /// Provenance method for a covariate read from a phone sensor.
  ///
  /// In en, this message translates to:
  /// **'Phone sensor'**
  String get covariateMethodPhoneSensor;

  /// Provenance method for a covariate read from a field instrument.
  ///
  /// In en, this message translates to:
  /// **'Field instrument'**
  String get covariateMethodFieldInstrument;

  /// Provenance method for a covariate entered as a visual estimate.
  ///
  /// In en, this message translates to:
  /// **'Visual estimate'**
  String get covariateMethodVisualEstimate;

  /// Title of the Visits screen empty state shown before any visit exists.
  ///
  /// In en, this message translates to:
  /// **'No visits'**
  String get visitsEmptyTitle;

  /// Message of the Visits screen empty state shown before any visit exists.
  ///
  /// In en, this message translates to:
  /// **'Start a visit from a site.'**
  String get visitsEmptyMessage;

  /// Heading of the sites a visit can be started at on the Visits screen.
  ///
  /// In en, this message translates to:
  /// **'Sites'**
  String get visitsSitesHeading;

  /// Heading of the visits recorded on the Visits screen.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get visitsListHeading;

  /// Button that starts a visit at a site.
  ///
  /// In en, this message translates to:
  /// **'Start visit'**
  String get visitsStartVisit;

  /// Button that ends an in-progress visit.
  ///
  /// In en, this message translates to:
  /// **'End visit'**
  String get visitsEndVisit;

  /// Title of the confirmation dialog shown before ending a visit.
  ///
  /// In en, this message translates to:
  /// **'End visit?'**
  String get visitsEndVisitTitle;

  /// Visit state label while the visit's effort timer is running.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get visitStateInProgress;

  /// Visit state label once the collector has ended the visit.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get visitStateEnded;

  /// Title of the capture screen for the in-progress visit.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get captureTitle;

  /// Label of the visit's effort start time on the capture screen.
  ///
  /// In en, this message translates to:
  /// **'Effort started: {time}'**
  String captureEffortStarted(String time);

  /// Label of the visit's lifecycle state on the capture screen.
  ///
  /// In en, this message translates to:
  /// **'State: {state}'**
  String captureState(String state);

  /// Heading of the target taxa list on the capture screen.
  ///
  /// In en, this message translates to:
  /// **'Target taxa'**
  String get detectionTargetsHeading;

  /// Label of the two-state control marking a target taxon as detected.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get detectionDetected;

  /// Label of the two-state control marking a target taxon as searched for but not detected.
  ///
  /// In en, this message translates to:
  /// **'Not detected'**
  String get detectionNotDetected;

  /// Distinct state shown for a target taxon that has no Detection yet.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get detectionNotRecorded;

  /// Button that brings the next unrecorded target taxon into view in one tap.
  ///
  /// In en, this message translates to:
  /// **'Next unrecorded'**
  String get detectionNextUnrecorded;

  /// Message shown when the protocol has no target list.
  ///
  /// In en, this message translates to:
  /// **'The protocol defines no target taxa.'**
  String get detectionNoTargets;

  /// Incomplete signal shown while target taxa remain unrecorded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 target not recorded} other{{count} targets not recorded}}'**
  String visitIncomplete(int count);

  /// Signal shown once every target taxon has a Detection.
  ///
  /// In en, this message translates to:
  /// **'All targets recorded'**
  String get visitAllTargetsRecorded;

  /// Heading of the opportunistic taxa section on the capture screen.
  ///
  /// In en, this message translates to:
  /// **'Opportunistic taxa'**
  String get opportunisticHeading;

  /// Label of the abbreviation search field used to add an opportunistic taxon.
  ///
  /// In en, this message translates to:
  /// **'Search by abbreviation'**
  String get opportunisticSearchLabel;

  /// Message shown when no taxon abbreviation matches the search.
  ///
  /// In en, this message translates to:
  /// **'No matching taxa'**
  String get opportunisticNoResults;

  /// Label of an opportunistic Detection, which is presence-only and has no not-detected state.
  ///
  /// In en, this message translates to:
  /// **'Detected (opportunistic)'**
  String get opportunisticPresenceOnly;

  /// Label of the email field on the Account sign-in form.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// Label of the password field on the Account sign-in form.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// Button that submits the sign-in form.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// Error shown on the Account screen when sign-in is rejected.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Check your email and password.'**
  String get authSignInFailed;

  /// Button that ends the signed-in state and returns to the form.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// Shows the name of the signed-in person on the Account screen.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String authSignedInAs(String name);

  /// Label of the name field on the Account sign-up form.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get authName;

  /// Button that submits the Account sign-up form.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUp;

  /// Link on the Account sign-in form that reveals the sign-up form.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get authSwitchToSignUp;

  /// Link on the Account sign-up form that returns to the sign-in form.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authSwitchToSignIn;

  /// Error shown when the sign-up name is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get authNameRequired;

  /// Error shown when the sign-up email is malformed.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get authEmailInvalid;

  /// Error shown when the sign-up password is shorter than the minimum.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get authPasswordTooShort;

  /// Error shown when the sign-up request is rejected, such as an already-registered email.
  ///
  /// In en, this message translates to:
  /// **'Could not create the account. Check your details and try again.'**
  String get authSignUpFailed;

  /// Evidence captured as a photo; tooltip of the photo capture affordance on a Detection.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get evidencePhoto;

  /// Evidence captured as audio; tooltip of the audio capture affordance on a Detection.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get evidenceAudio;

  /// Button that stops an in-progress audio recording for a Detection.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get evidenceStop;

  /// Message shown when capturing photo or audio evidence fails.
  ///
  /// In en, this message translates to:
  /// **'Could not capture evidence. Try again.'**
  String get evidenceCaptureFailed;

  /// Heading of the visit covariate section on the capture screen.
  ///
  /// In en, this message translates to:
  /// **'Visit covariates'**
  String get visitCovariatesHeading;

  /// Label shown on a sensor-backed covariate field when the sensor is missing, so the value is entered by hand (UX-011).
  ///
  /// In en, this message translates to:
  /// **'Manual entry (sensor unavailable)'**
  String get measurementManualFallback;

  /// Marker shown on a covariate value read from an uncalibrated sensor (UX-011).
  ///
  /// In en, this message translates to:
  /// **'Low confidence (sensor not calibrated)'**
  String get measurementLowConfidence;

  /// Label of the provenance method selector for a manually entered covariate value.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get measurementMethod;

  /// Error shown when a covariate value is entered without a provenance method (INV-010).
  ///
  /// In en, this message translates to:
  /// **'Select a method for each value.'**
  String get measurementMissingMethod;

  /// Button that records the entered visit covariate values with their provenance.
  ///
  /// In en, this message translates to:
  /// **'Save measurements'**
  String get measurementSave;

  /// Tooltip and label of the Projects screen button that opens the project editor.
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get projectsCreateProject;

  /// Title of the project editor when defining a new project.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get projectEditorNewTitle;

  /// Label of the project name field in the project editor.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectEditorName;

  /// Label of the field naming the pinned Taxonomic reference in the project editor.
  ///
  /// In en, this message translates to:
  /// **'Taxonomic reference'**
  String get projectEditorReferenceId;

  /// Label of the field pinning the Taxonomic reference version in the project editor.
  ///
  /// In en, this message translates to:
  /// **'Taxonomic reference version'**
  String get projectEditorReferenceVersion;

  /// Label of the switch enabling validation for a project.
  ///
  /// In en, this message translates to:
  /// **'Validation'**
  String get projectEditorValidation;

  /// Label of the switch enabling sensitive-taxa coordinate obfuscation for a project.
  ///
  /// In en, this message translates to:
  /// **'Sensitive-taxa obfuscation'**
  String get projectEditorObfuscation;

  /// Button that creates the project being defined in the project editor.
  ///
  /// In en, this message translates to:
  /// **'Save project'**
  String get projectEditorSave;

  /// Error shown when the project name is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a project name.'**
  String get projectEditorNameRequired;

  /// Error shown when no taxonomic reference is given.
  ///
  /// In en, this message translates to:
  /// **'Select a taxonomic reference.'**
  String get projectEditorReferenceRequired;

  /// Error shown when the taxonomic reference version is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a taxonomic reference version.'**
  String get projectEditorVersionRequired;

  /// Error shown when creating the project fails.
  ///
  /// In en, this message translates to:
  /// **'Could not create the project. Try again.'**
  String get projectEditorCreateFailed;

  /// Heading of the read-only view of a frozen Protocol version.
  ///
  /// In en, this message translates to:
  /// **'Protocol version'**
  String get protocolVersionTitle;

  /// Title of the form that defines a new Protocol version.
  ///
  /// In en, this message translates to:
  /// **'New protocol version'**
  String get protocolVersionNewTitle;

  /// Label of the stable Protocol identity field in the protocol-version form.
  ///
  /// In en, this message translates to:
  /// **'Protocol ID'**
  String get protocolVersionProtocolId;

  /// Label of the taxonomic scope field in the protocol-version form.
  ///
  /// In en, this message translates to:
  /// **'Taxonomic scope'**
  String get protocolVersionTaxonomicScope;

  /// Label of the switch that leaves the target list undefined so the taxonomic scope defines the targets.
  ///
  /// In en, this message translates to:
  /// **'Complete-list mode'**
  String get protocolVersionCompleteListMode;

  /// Label of the target taxa field in the protocol-version form.
  ///
  /// In en, this message translates to:
  /// **'Target list'**
  String get protocolVersionTargetList;

  /// Label of the allowed Detection methods field in the protocol-version form.
  ///
  /// In en, this message translates to:
  /// **'Detection methods'**
  String get protocolVersionDetectionMethods;

  /// Heading of the required Sampling effort fields a Protocol version defines.
  ///
  /// In en, this message translates to:
  /// **'Required effort fields'**
  String get protocolVersionRequiredEffort;

  /// Label of the visit Covariate definitions field in the protocol-version form.
  ///
  /// In en, this message translates to:
  /// **'Visit covariates'**
  String get protocolVersionVisitCovariates;

  /// Label of the Site Covariate definitions field in the protocol-version form.
  ///
  /// In en, this message translates to:
  /// **'Site covariates'**
  String get protocolVersionSiteCovariates;

  /// Label of the Sampling effort field recording when the search started.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get effortFieldStart;

  /// Label of the Sampling effort field recording how long the search lasted.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get effortFieldDuration;

  /// Label of the Sampling effort field recording who searched.
  ///
  /// In en, this message translates to:
  /// **'Observers'**
  String get effortFieldObservers;

  /// Label of the Sampling effort field recording which Detection methods were used.
  ///
  /// In en, this message translates to:
  /// **'Detection methods'**
  String get effortFieldDetectionMethods;

  /// Button that defines the protocol version being edited.
  ///
  /// In en, this message translates to:
  /// **'Save protocol version'**
  String get protocolVersionSave;

  /// Badge shown on a Protocol version referenced by a Visit, which is immutable (INV-007).
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get protocolVersionFrozen;

  /// Button that starts a new Protocol version from a frozen one, since a frozen version never changes (INV-007).
  ///
  /// In en, this message translates to:
  /// **'Create a new version'**
  String get protocolVersionCreateNew;

  /// Label showing a Protocol version's server-assigned version number.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String protocolVersionVersion(int version);

  /// Explanation shown when a frozen Protocol version is read-only (INV-007).
  ///
  /// In en, this message translates to:
  /// **'This version is frozen and can no longer change. Create a new version to make changes.'**
  String get protocolVersionReadOnly;

  /// Error shown when the protocol ID is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a protocol ID.'**
  String get protocolVersionProtocolIdRequired;

  /// Error shown when the taxonomic scope is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one taxon in scope.'**
  String get protocolVersionScopeRequired;

  /// Error shown when a non-complete-list protocol has no target taxa.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one target taxon or use complete-list mode.'**
  String get protocolVersionTargetListRequired;

  /// Error shown when no Detection method is given.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one detection method.'**
  String get protocolVersionDetectionMethodsRequired;

  /// Error shown when no required Sampling effort field is selected (INV-005).
  ///
  /// In en, this message translates to:
  /// **'Select at least one required effort field.'**
  String get protocolVersionEffortRequired;

  /// Error shown when a Covariate definition line cannot be parsed.
  ///
  /// In en, this message translates to:
  /// **'Enter each covariate as name:type[:unit], or leave the field empty.'**
  String get protocolVersionInvalidCovariates;

  /// Error shown when defining the protocol version fails.
  ///
  /// In en, this message translates to:
  /// **'Could not save the protocol version. Try again.'**
  String get protocolVersionCreateFailed;

  /// Title of the members screen listing a project's members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersTitle;

  /// Message shown when the project has no members.
  ///
  /// In en, this message translates to:
  /// **'No members yet.'**
  String get membersEmpty;

  /// Error shown when loading the member list fails.
  ///
  /// In en, this message translates to:
  /// **'Could not load the members. Try again.'**
  String get membersLoadFailed;

  /// Heading of the add-member form shown to a project creator.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get membersAddHeading;

  /// Label of the email field in the add-member form.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get membersEmail;

  /// Label of the role selector in the add-member form.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get membersRole;

  /// Button that adds the member entered in the add-member form.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get membersAdd;

  /// Error shown when the add-member email is empty or malformed.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get membersEmailRequired;

  /// Error shown when no role is selected in the add-member form.
  ///
  /// In en, this message translates to:
  /// **'Select a role.'**
  String get membersRoleRequired;

  /// Error shown when adding a member fails.
  ///
  /// In en, this message translates to:
  /// **'Could not add the member. Try again.'**
  String get membersAddFailed;

  /// Label of the Membership role assigned to a project's creator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get membershipRoleCreator;

  /// Label of the Membership collector role.
  ///
  /// In en, this message translates to:
  /// **'Collector'**
  String get membershipRoleCollector;

  /// Label of the Membership validator role.
  ///
  /// In en, this message translates to:
  /// **'Validator'**
  String get membershipRoleValidator;

  /// Title of the survey-periods screen listing a project's Survey periods.
  ///
  /// In en, this message translates to:
  /// **'Survey periods'**
  String get surveyPeriodsTitle;

  /// Message shown when the project has no Survey periods.
  ///
  /// In en, this message translates to:
  /// **'No survey periods yet.'**
  String get surveyPeriodsEmpty;

  /// Error shown when loading the Survey-period list fails.
  ///
  /// In en, this message translates to:
  /// **'Could not load the survey periods. Try again.'**
  String get surveyPeriodsLoadFailed;

  /// Heading of the add-Survey-period form shown to a project creator.
  ///
  /// In en, this message translates to:
  /// **'Add survey period'**
  String get surveyPeriodsAddHeading;

  /// Label of the name field in the add-Survey-period form.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get surveyPeriodName;

  /// Label of the start-date field in the add-Survey-period form.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get surveyPeriodStartDate;

  /// Label of the end-date field in the add-Survey-period form.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get surveyPeriodEndDate;

  /// Button that adds the Survey period entered in the add-Survey-period form.
  ///
  /// In en, this message translates to:
  /// **'Add survey period'**
  String get surveyPeriodsAdd;

  /// Error shown when the Survey-period name is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get surveyPeriodNameRequired;

  /// Error shown when the Survey-period start date is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a start date.'**
  String get surveyPeriodStartRequired;

  /// Error shown when the Survey-period end date is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter an end date.'**
  String get surveyPeriodEndRequired;

  /// Error shown when a Survey-period date is not an ISO date.
  ///
  /// In en, this message translates to:
  /// **'Enter each date as YYYY-MM-DD.'**
  String get surveyPeriodInvalidDate;

  /// Error shown when a Survey period's end date precedes its start date.
  ///
  /// In en, this message translates to:
  /// **'The end date cannot precede the start date.'**
  String get surveyPeriodEndBeforeStart;

  /// Error shown when adding a Survey period fails.
  ///
  /// In en, this message translates to:
  /// **'Could not add the survey period. Try again.'**
  String get surveyPeriodsAddFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
