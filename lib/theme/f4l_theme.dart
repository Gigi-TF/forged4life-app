import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand tokens, sampled from the SkillsForge360 logo artwork.
/// These are the only colour literals in the app.
class F4L {
  // --- brand ---
  static const teal = Color(0xFF02656A);
  static const tealDeep = Color(0xFF014346);
  static const tealMid = Color(0xFF04888C);
  static const tealLift = Color(0xFF0DA0A4);
  static const orange = Color(0xFFEE6C18);
  static const orangeDeep = Color(0xFFC85A0D);

  // --- dark canvas ---
  static const canvas = Color(0xFF100F18);
  static const surface = Color(0xFF181725);
  static const field = Color(0xFF211F31);
  static const ink = Color(0xFFF6F3FF);
  static const mute = Color(0xFFADA6C6);

  // --- light canvas: mint, not white ---
  static const mintCore = Color(0xFFBFE0DF);
  static const mintMid = Color(0xFFD3E9E8);
  static const mintRim = Color(0xFFE2F0F0);
  static const lSurface = Color(0xFFF7FCFC);
  static const lField = Color(0xFFE6F1F1);
  static const lInk = Color(0xFF0B2E31);

  /// Secondary text in light mode.
  ///
  /// Was #4C6668, which measured 4.39:1 against the mint core — under the 4.5
  /// minimum for body text, which is why light mode read as washed out. This
  /// is 7.3:1. Contrast, not weight, was the actual problem.
  static const lMute = Color(0xFF2C4547);

  /// Every text style in light mode is nudged up by this many weight steps.
  ///
  /// One step (400→500, 500→600) makes text sit more solidly on a tinted
  /// background without flattening the hierarchy. Set to 2 for heavier, 0 to
  /// turn it off. Dark mode is untouched — light text on dark already looks
  /// heavier than it is, and bumping it would smear.
  static const lightWeightBoost = 1;

  static const cardTint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFDFDFB), Color(0xFFF7FCFC), Color(0xFFFFF6EE)],
    stops: [0.0, 0.50, 1.0],
  );

  static const dayTint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFDF7), Color(0xFFFFF6E8), Color(0xFFFFEFDD)],
    stops: [0.0, 0.52, 1.0],
  );

  static const rail = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [teal, tealMid, Color(0xFF8F9A2E), orange],
    stops: [0.0, 0.34, 0.62, 1.0],
  );

  static const blend = LinearGradient(
    begin: Alignment(-1, -0.35),
    end: Alignment(1, 0.35),
    colors: [tealLift, Color(0xFF3E9E78), Color(0xFFB69A2C), orange],
    stops: [0.0, 0.32, 0.64, 1.0],
  );

  /// Darker stops for light mode — the dark-mode blend is too bright to read
  /// as text on mint.
  static const blendLight = LinearGradient(
    begin: Alignment(-1, -0.35),
    end: Alignment(1, 0.35),
    colors: [teal, Color(0xFF25714F), Color(0xFF7E6A1C), orangeDeep],
    stops: [0.0, 0.32, 0.64, 1.0],
  );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        surface: surface,
        field: field,
        ink: ink,
        mute: mute,
        outline: Colors.white.withValues(alpha: 0.10),
      );

  static ThemeData light() => _build(
        brightness: Brightness.light,
        surface: lSurface,
        field: lField,
        ink: lInk,
        mute: lMute,
        outline: teal.withValues(alpha: 0.20),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color surface,
    required Color field,
    required Color ink,
    required Color mute,
    required Color outline,
  }) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final isLight = brightness == Brightness.light;

    var text = GoogleFonts.montserratTextTheme(base.textTheme)
        .apply(bodyColor: ink, displayColor: ink);

    if (isLight && lightWeightBoost > 0) {
      text = _heavier(text, lightWeightBoost);
    }

    return base.copyWith(
      // F4LBackdrop paints the background; scaffolds must not cover it.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      dividerColor: outline,

      colorScheme: ColorScheme.fromSeed(
        seedColor: orange,
        brightness: brightness,
      ).copyWith(surface: surface, secondary: teal, outline: outline),

      textTheme: text,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: ink,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 17,
          fontWeight: isLight ? FontWeight.w800 : FontWeight.w700,
          color: ink,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: outline),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        hintStyle: TextStyle(
            color: mute.withValues(alpha: 0.7),
            fontWeight: isLight ? FontWeight.w500 : FontWeight.w400),
        labelStyle: TextStyle(
            color: mute,
            fontWeight: isLight ? FontWeight.w600 : FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
      ),

      dialogTheme: DialogThemeData(backgroundColor: surface),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface),
    );
  }

  /// Nudges every style in a TextTheme up by [steps] weight increments,
  /// stopping at w900 so nothing overflows the variable font's range.
  static TextTheme _heavier(TextTheme t, int steps) {
    TextStyle? up(TextStyle? s) {
      if (s == null) return null;
      const scale = [
        FontWeight.w100,
        FontWeight.w200,
        FontWeight.w300,
        FontWeight.w400,
        FontWeight.w500,
        FontWeight.w600,
        FontWeight.w700,
        FontWeight.w800,
        FontWeight.w900,
      ];
      final i = scale.indexOf(s.fontWeight ?? FontWeight.w400);
      final next = scale[(i < 0 ? 3 : i + steps).clamp(0, scale.length - 1)];
      return s.copyWith(fontWeight: next);
    }

    return TextTheme(
      displayLarge: up(t.displayLarge),
      displayMedium: up(t.displayMedium),
      displaySmall: up(t.displaySmall),
      headlineLarge: up(t.headlineLarge),
      headlineMedium: up(t.headlineMedium),
      headlineSmall: up(t.headlineSmall),
      titleLarge: up(t.titleLarge),
      titleMedium: up(t.titleMedium),
      titleSmall: up(t.titleSmall),
      bodyLarge: up(t.bodyLarge),
      bodyMedium: up(t.bodyMedium),
      bodySmall: up(t.bodySmall),
      labelLarge: up(t.labelLarge),
      labelMedium: up(t.labelMedium),
      labelSmall: up(t.labelSmall),
    );
  }
}

/// Paints text with the brand gradient.
class BlendText extends StatelessWidget {
  const BlendText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).brightness == Brightness.dark
        ? F4L.blend
        : F4L.blendLight;

    return ShaderMask(
      shaderCallback: (b) => gradient.createShader(b),
      blendMode: BlendMode.srcIn,
      child: Text(text,
          textAlign: textAlign,
          style: (style ?? const TextStyle()).copyWith(color: Colors.white)),
    );
  }
}
