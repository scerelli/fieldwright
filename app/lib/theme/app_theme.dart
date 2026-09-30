import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Placeholder seed; the brand palette is settled at /design (DESIGN.md is
// currently deferred).
const Color kSeedColor = Color(0xFF2E7D32);

ThemeData buildLightTheme() => FlexThemeData.light(
  keyColors: FlexKeyColors(keyPrimary: kSeedColor),
  useMaterial3: true,
);

ThemeData buildDarkTheme() => FlexThemeData.dark(
  keyColors: FlexKeyColors(keyPrimary: kSeedColor),
  useMaterial3: true,
);

final appLightThemeProvider = Provider<ThemeData>((ref) => buildLightTheme());

final appDarkThemeProvider = Provider<ThemeData>((ref) => buildDarkTheme());
