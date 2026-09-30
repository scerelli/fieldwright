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

  /// Placeholder counter shown on the Visits screen.
  ///
  /// In en, this message translates to:
  /// **'Visits count: {count}'**
  String visitsCount(int count);

  /// Placeholder increment button on the Visits screen.
  ///
  /// In en, this message translates to:
  /// **'Increment Visits'**
  String get incrementVisits;

  /// Placeholder counter shown on the Account screen.
  ///
  /// In en, this message translates to:
  /// **'Account count: {count}'**
  String accountCount(int count);

  /// Placeholder increment button on the Account screen.
  ///
  /// In en, this message translates to:
  /// **'Increment Account'**
  String get incrementAccount;
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
