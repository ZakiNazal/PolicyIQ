import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core palette — deep-space operative terminal
  static const Color background = Color(0xFF060810);
  static const Color surface = Color(0xFF0D1017);
  static const Color surfaceElevated = Color(0xFF131820);
  static const Color surfaceBright = Color(0xFF1A2030);
  static const Color border = Color(0xFF1E2A3A);
  static const Color borderBright = Color(0xFF2A3A50);

  // Accent spectrum
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentGreen = Color(0xFF00FF9D);
  static const Color accentAmber = Color(0xFFFFB347);
  static const Color accentRed = Color(0xFFFF4466);
  static const Color accentPurple = Color(0xFFBB66FF);
  static const Color accentBlue = Color(0xFF4488FF);

  // Text
  static const Color textPrimary = Color(0xFFE8F0FF);
  static const Color textSecondary = Color(0xFF7A90B0);
  static const Color textMuted = Color(0xFF3D5068);
  static const Color textAccent = Color(0xFF00E5FF);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        fontFamily: GoogleFonts.spaceMono().fontFamily,
        colorScheme: const ColorScheme.dark(
          surface: surface,
          primary: accentCyan,
          secondary: accentGreen,
          error: accentRed,
        ),
        dividerColor: border,
        textTheme: GoogleFonts.spaceMonoTextTheme(const TextTheme(
          displayLarge: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: 1.5,
          ),
          titleMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: textSecondary,
            letterSpacing: 1.2,
          ),
          bodyLarge: TextStyle(
            fontSize: 24,
            color: textPrimary,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            fontSize: 20,
            color: textSecondary,
            height: 1.5,
          ),
          labelSmall: TextStyle(
            fontSize: 18,
            color: textMuted,
            letterSpacing: 1.5,
          ),
        )),
      );
}

// Shared styled containers
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;
  final Color? glowColor;
  final double borderRadius;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.glowColor,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppTheme.border,
          width: 1,
        ),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withOpacity(0.08),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  const SectionLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.spaceMono(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color ?? AppTheme.textMuted,
        letterSpacing: 2.5,
      ),
    );
  }
}

class DotBadge extends StatelessWidget {
  final Color color;
  final double size;
  const DotBadge({super.key, required this.color, this.size = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.6), blurRadius: 4, spreadRadius: 1),
        ],
      ),
    );
  }
}
