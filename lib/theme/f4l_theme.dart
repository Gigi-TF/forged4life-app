import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand tokens, sampled from the SkillsForge360 logo artwork.
/// These are the only colour literals in the app — everything else reads from here.
class F4L {
  // --- brand, straight off the logo ---
  static const teal      = Color(0xFF02656A);
  static const tealDeep  = Color(0xFF014346);
  static const tealMid   = Color(0xFF04888C);
  static const orange    = Color(0xFFEE6C18);
  static const orangeDeep= Color(0xFFC85A0D);

  // --- dark canvas (the app chrome) ---
  static const canvas    = Color(0xFF100F18);
  static const surface   = Color(0xFF181725);
  static const field     = Color(0xFF211F31);
  static const ink       = Color(0xFFF6F3FF);
  static const mute      = Color(0xFFADA6C6);
  static const tealLift  = Color(0xFF0DA0A4);   // teal lifted for legibility on dark

  // --- light canvas ---
  static const lCanvas   = Color(0xFFF3F2F9);
  static const lSurface  = Color(0xFFFFFFFF);
  static const lInk      = Color(0xFF14121C);
  static const lMute     = Color(0xFF514C64);

  // --- the card itself: white in BOTH themes ---
  static const cardTint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFDFDFB), Color(0xFFF3FAFA), Color(0xFFFFF4EC)],
    stops: [0.0, 0.50, 1.0],
  );

  /// Vertical rail behind "LOYALTY CARD" — teal cooling into orange.
  static const rail = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [teal, tealMid, Color(0xFF8F9A2E), orange],
    stops: [0.0, 0.34, 0.62, 1.0],
  );

  /// Horizontal version, for headlines and primary buttons.
  static const blend = LinearGradient(
    begin: Alignment(-1, -0.35),
    end: Alignment(1, 0.35),
    colors: [tealLift, Color(0xFF3E9E78), Color(0xFFB69A2C), orange],
    stops: [0.0, 0.32, 0.64, 1.0],
  );

  /// Day passes read amber, so staff can tell them apart at a glance.
  static const dayTint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFDF7), Color(0xFFFFF6E8), Color(0xFFFFEFDD)],
    stops: [0.0, 0.52, 1.0],
  );

  static ThemeData dark() => _build(Brightness.dark, canvas, surface, field, ink, mute);
  static ThemeData light() =>
      _build(Brightness.light, lCanvas, lSurface, const Color(0xFFEAE8F3), lInk, lMute);

  static ThemeData _build(Brightness b, Color canvas, Color surface, Color field,
      Color ink, Color mute) {
    final base = ThemeData(brightness: b, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(seedColor: orange, brightness: b)
          .copyWith(surface: surface, secondary: teal),
      textTheme: GoogleFonts.montserratTextTheme(base.textTheme)
          .apply(bodyColor: ink, displayColor: ink),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: ink.withValues(alpha: 0.09)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Paints text with the brand gradient. Use for headlines and big figures.
class BlendText extends StatelessWidget {
  const BlendText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (b) => F4L.blend.createShader(b),
        blendMode: BlendMode.srcIn,
        child: Text(text,
            textAlign: textAlign,
            style: (style ?? const TextStyle()).copyWith(color: Colors.white)),
      );
}
