import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// DESIGN.md § Color — Light. Critical text is the near-black onSurface pair,
// never the accent, so it clears UX-002's 7:1; onSurfaceVariant carries the
// secondary text.
const Color kLightPrimary = Color(0xFF00695C);
const Color kLightOnPrimary = Color(0xFFFFFFFF);
const Color kLightSecondary = Color(0xFF3A6EA5);
const Color kLightBackground = Color(0xFFF6F8F9);
const Color kLightSurface = Color(0xFFFFFFFF);
const Color kLightOnSurface = Color(0xFF14181A);
const Color kLightOnSurfaceVariant = Color(0xFF444B4E);
const Color kLightOutline = Color(0xFF70797C);
const Color kLightError = Color(0xFFB3261E);

// DESIGN.md § Color — Dark.
const Color kDarkPrimary = Color(0xFF80CBC4);
const Color kDarkOnPrimary = Color(0xFF003731);
const Color kDarkSecondary = Color(0xFF4DD0E1);
const Color kDarkTertiary = Color(0xFFC792EA);
const Color kDarkSurface = Color(0xFF263238);
const Color kDarkOnSurface = Color(0xFFE3E9EA);
const Color kDarkError = Color(0xFFF2B8B5);

/// DESIGN.md § Typography — Inter, with tabular figures for counts, effort and
/// coordinates so digits line up when scanned and compared.
const String kFontFamily = 'Inter';
const List<FontFeature> kTabularFigures = <FontFeature>[
  FontFeature.tabularFigures(),
];

TextTheme _withNumericFigures(TextTheme text) => text.copyWith(
  bodyMedium: text.bodyMedium?.copyWith(fontFeatures: kTabularFigures),
);

ThemeData buildLightTheme() {
  final base = FlexThemeData.light(
    primary: kLightPrimary,
    onPrimary: kLightOnPrimary,
    secondary: kLightSecondary,
    surface: kLightSurface,
    onSurface: kLightOnSurface,
    scaffoldBackground: kLightBackground,
    error: kLightError,
    fontFamily: kFontFamily,
    fixedColorStyle: FlexFixedColorStyle.seeded,
    useMaterial3: true,
  );
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      onSurfaceVariant: kLightOnSurfaceVariant,
      outline: kLightOutline,
    ),
    textTheme: _withNumericFigures(base.textTheme),
  );
}

ThemeData buildDarkTheme() {
  final base = FlexThemeData.dark(
    primary: kDarkPrimary,
    primaryLightRef: kDarkPrimary,
    onPrimary: kDarkOnPrimary,
    secondary: kDarkSecondary,
    secondaryLightRef: kDarkSecondary,
    tertiary: kDarkTertiary,
    tertiaryLightRef: kDarkTertiary,
    surface: kDarkSurface,
    onSurface: kDarkOnSurface,
    scaffoldBackground: kDarkSurface,
    error: kDarkError,
    fontFamily: kFontFamily,
    useMaterial3: true,
  );
  return base.copyWith(textTheme: _withNumericFigures(base.textTheme));
}

final appLightThemeProvider = Provider<ThemeData>((ref) => buildLightTheme());

final appDarkThemeProvider = Provider<ThemeData>((ref) => buildDarkTheme());
