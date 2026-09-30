import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Placeholder seed; the brand palette is settled at /design (DESIGN.md is
// currently deferred).
const Color kSeedColor = Color(0xFF2E7D32);

// The dark theme follows VS Code's Material Dark palette (equinusocio's
// Material Theme): blue-grey surfaces with a teal primary. The light theme
// above keeps the seed-based scheme.
const Color kDarkPrimary = Color(0xFF80CBC4);
const Color kDarkSecondary = Color(0xFF4DD0E1);
const Color kDarkTertiary = Color(0xFFC792EA);
const Color kDarkSurface = Color(0xFF263238);
const Color kDarkOnSurface = Color(0xFFEEFFFF);

ThemeData buildLightTheme() => FlexThemeData.light(
  keyColors: FlexKeyColors(keyPrimary: kSeedColor),
  useMaterial3: true,
);

ThemeData buildDarkTheme() => FlexThemeData.dark(
  keyColors: FlexKeyColors(
    keyPrimary: kDarkPrimary,
    keepPrimary: true,
    keySecondary: kDarkSecondary,
    useSecondary: true,
    keepSecondary: true,
    keyTertiary: kDarkTertiary,
    useTertiary: true,
    keepTertiary: true,
  ),
  primary: kDarkPrimary,
  primaryLightRef: kDarkPrimary,
  secondary: kDarkSecondary,
  secondaryLightRef: kDarkSecondary,
  tertiary: kDarkTertiary,
  tertiaryLightRef: kDarkTertiary,
  surface: kDarkSurface,
  scaffoldBackground: kDarkSurface,
  onSurface: kDarkOnSurface,
  useMaterial3: true,
);

final appLightThemeProvider = Provider<ThemeData>((ref) => buildLightTheme());

final appDarkThemeProvider = Provider<ThemeData>((ref) => buildDarkTheme());
