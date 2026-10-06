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
const Color kLightDetected = Color(0xFF1B5E20);
const Color kLightWarning = Color(0xFF8A5A00);

// DESIGN.md § Color — Dark.
const Color kDarkPrimary = Color(0xFF80CBC4);
const Color kDarkOnPrimary = Color(0xFF003731);
const Color kDarkSecondary = Color(0xFF4DD0E1);
const Color kDarkTertiary = Color(0xFFC792EA);
const Color kDarkSurface = Color(0xFF263238);
const Color kDarkOnSurface = Color(0xFFE3E9EA);
const Color kDarkError = Color(0xFFF2B8B5);
const Color kDarkDetected = Color(0xFFA5D6A7);
const Color kDarkWarning = Color(0xFFFFCC80);

/// The DESIGN.md state colours Material 3 does not provide, exposed as a
/// [ThemeExtension] so a component reads them from `Theme.of(context)`
/// instead of hard-coding a colour. `detected` and `warning` carry critical
/// detection-state text and icons (UX-002); `outline` is for dividers and the
/// shell indicator. DESIGN.md defines no dark `outline`, so the dark theme
/// mirrors its own `colorScheme.outline`.
@immutable
class IbisTokens extends ThemeExtension<IbisTokens> {
  const IbisTokens({
    required this.detected,
    required this.warning,
    required this.outline,
  });

  final Color detected;
  final Color warning;
  final Color outline;

  @override
  IbisTokens copyWith({Color? detected, Color? warning, Color? outline}) =>
      IbisTokens(
        detected: detected ?? this.detected,
        warning: warning ?? this.warning,
        outline: outline ?? this.outline,
      );

  @override
  IbisTokens lerp(ThemeExtension<IbisTokens>? other, double t) {
    if (other is! IbisTokens) {
      return this;
    }
    return IbisTokens(
      detected: Color.lerp(detected, other.detected, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
    );
  }
}

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
  final List<ThemeExtension<dynamic>> extensions = base.extensions.values
      .toList();
  extensions.add(
    const IbisTokens(
      detected: kLightDetected,
      warning: kLightWarning,
      outline: kLightOutline,
    ),
  );
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      onSurfaceVariant: kLightOnSurfaceVariant,
      outline: kLightOutline,
    ),
    textTheme: _withNumericFigures(base.textTheme),
    extensions: extensions,
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
  final List<ThemeExtension<dynamic>> extensions = base.extensions.values
      .toList();
  extensions.add(
    IbisTokens(
      detected: kDarkDetected,
      warning: kDarkWarning,
      outline: base.colorScheme.outline,
    ),
  );
  return base.copyWith(
    textTheme: _withNumericFigures(base.textTheme),
    extensions: extensions,
  );
}

final appLightThemeProvider = Provider<ThemeData>((ref) => buildLightTheme());

final appDarkThemeProvider = Provider<ThemeData>((ref) => buildDarkTheme());
