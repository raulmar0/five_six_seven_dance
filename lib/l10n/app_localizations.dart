import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ko.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('es'),
    Locale('fr'),
    Locale('ko'),
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'567 Dance!'**
  String get appName;

  /// Title for the settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Section header for support and info in settings
  ///
  /// In en, this message translates to:
  /// **'SUPPORT & INFO'**
  String get supportInfoSection;

  /// Menu item for Help Center
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenterItem;

  /// Menu item for About the App
  ///
  /// In en, this message translates to:
  /// **'About the App'**
  String get aboutAppItem;

  /// Menu item for Suggestions
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestionsItem;

  /// Menu item for Language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageItem;

  /// App version string
  ///
  /// In en, this message translates to:
  /// **'567 Dance! v1.0.4'**
  String get appVersion;

  /// Title for the about screen
  ///
  /// In en, this message translates to:
  /// **'About the App'**
  String get aboutTitle;

  /// Description text in the about screen
  ///
  /// In en, this message translates to:
  /// **'Thank you for being part of our community!\n\nWe created this app to celebrate the passion, energy, and discipline of Latin dance. Whether you\'re mastering your first steps or perfecting your rhythm, we are honored to be part of your dance journey.\n\nKeep moving and let the music guide you!'**
  String get aboutDescription;

  /// Header for the developer section
  ///
  /// In en, this message translates to:
  /// **'DEVELOPER'**
  String get developerTitle;

  /// Header for the contact section
  ///
  /// In en, this message translates to:
  /// **'CONTACT & SUPPORT'**
  String get contactTitle;

  /// Label for the tempo control
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get tempoLabel;

  /// Label for the measures/bars control
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get measuresLabel;

  /// Label for the instruments section
  ///
  /// In en, this message translates to:
  /// **'Instruments'**
  String get instrumentsLabel;

  /// Label for the voice section
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceLabel;

  /// Badge showing version number in about screen
  ///
  /// In en, this message translates to:
  /// **'VERSION 1.0'**
  String get versionBadge;
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
      <String>['en', 'es', 'fr', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
