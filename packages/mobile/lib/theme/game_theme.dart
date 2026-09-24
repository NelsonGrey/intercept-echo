import 'package:flutter/material.dart';

/// Identifies one of the built-in gameplay palettes. Persisted by name (see
/// [ThemeController]) — renaming a value here changes what a player who
/// already picked a non-default palette sees next launch.
enum GameThemeId { signal, deepOcean, arcadeNeon, warmSunset, candyPop }

/// A complete color palette for the gameplay screen. Slot names match the
/// `{{colors.<slot>}}` tokens in the "Shift-Register Palettes" design
/// canvas one-to-one, so a palette tweaked there drops straight in here.
/// Every themed surface reads from one of these rather than hardcoding a
/// color; test/theme/game_theme_contrast_test.dart holds each palette to
/// WCAG AA.
class GameThemePalette {
  const GameThemePalette({
    required this.name,
    required this.pageBg,
    required this.textPrimary,
    required this.textMuted,
    required this.clockTrack,
    required this.clockFill,
    required this.targetOnBg,
    required this.targetOnBorder,
    required this.targetOnFg,
    required this.targetOffBorder,
    required this.targetOffFg,
    required this.matchHit,
    required this.matchMiss,
    required this.bitOnBg,
    required this.bitOnShadow,
    required this.bitOnFg,
    required this.bitOffBg,
    required this.bitOffBorder,
    required this.bitOffFg,
    required this.overflowBg,
    required this.overflowAccent,
    required this.overflowLabel,
    required this.buttonBg,
    required this.buttonFg,
  });

  /// Shown in the palette picker.
  final String name;

  final Color pageBg;
  final Color textPrimary;
  final Color textMuted;

  /// The ring around the moves counter. It tracks moves remaining until the
  /// TRD's real clock exists, then tracks the clock.
  final Color clockTrack;
  final Color clockFill;

  final Color targetOnBg;
  final Color targetOnBorder;
  final Color targetOnFg;
  final Color targetOffBorder;
  final Color targetOffFg;

  /// The check (matches) and cross (differs) between target and register.
  /// Shape carries the meaning too, so these never rely on hue alone
  /// (SRA-BR-013).
  final Color matchHit;
  final Color matchMiss;

  final Color bitOnBg;
  final Color bitOnShadow;
  final Color bitOnFg;
  final Color bitOffBg;

  /// Must reach 3:1 against [pageBg] so a 0 cell reads as a square, not
  /// just a digit.
  final Color bitOffBorder;
  final Color bitOffFg;

  /// Overflow meter, gutters and label. Always a different hue from
  /// [bitOnBg] — Warm Sunset's bits are orange, so its overflow is green.
  final Color overflowBg;
  final Color overflowAccent;
  final Color overflowLabel;

  final Color buttonBg;
  final Color buttonFg;
}

const Map<GameThemeId, GameThemePalette> gameThemePalettes = {
  GameThemeId.signal: GameThemePalette(
    name: 'Signal',
    pageBg: Color(0xFFF3F1EC),
    textPrimary: Color(0xFF16181D),
    textMuted: Color(0xFF555B67),
    clockTrack: Color(0xFFD5D3CC),
    clockFill: Color(0xFF16181D),
    targetOnBg: Color(0xFFE4E7FB),
    targetOnBorder: Color(0xFF3645C9),
    targetOnFg: Color(0xFF3645C9),
    targetOffBorder: Color(0xFF86847C),
    targetOffFg: Color(0xFF3A3F4A),
    matchHit: Color(0xFF16181D),
    matchMiss: Color(0xFFC2540A),
    bitOnBg: Color(0xFF3645C9),
    bitOnShadow: Color(0xFF1F2A8A),
    bitOnFg: Color(0xFFFFFFFF),
    bitOffBg: Color(0xFFFFFFFF),
    bitOffBorder: Color(0xFF86847C),
    bitOffFg: Color(0xFF2E323B),
    overflowBg: Color(0xFFFCE9DA),
    overflowAccent: Color(0xFFC2540A),
    overflowLabel: Color(0xFF8A3A06),
    buttonBg: Color(0xFF16181D),
    buttonFg: Color(0xFFFFFFFF),
  ),
  GameThemeId.deepOcean: GameThemePalette(
    name: 'Deep Ocean',
    pageBg: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF10262E),
    textMuted: Color(0xFF4A6B73),
    clockTrack: Color(0xFFDCEEF1),
    clockFill: Color(0xFF0B6B77),
    targetOnBg: Color(0xFFE1F5F6),
    targetOnBorder: Color(0xFF087985),
    targetOnFg: Color(0xFF087985),
    targetOffBorder: Color(0xFF6E9BA3),
    targetOffFg: Color(0xFF2F525A),
    matchHit: Color(0xFF10262E),
    matchMiss: Color(0xFFC0392B),
    bitOnBg: Color(0xFF2A6FB0),
    bitOnShadow: Color(0xFF1B4B7A),
    bitOnFg: Color(0xFFFFFFFF),
    bitOffBg: Color(0xFFEAF4F6),
    bitOffBorder: Color(0xFF5F8F98),
    bitOffFg: Color(0xFF10262E),
    overflowBg: Color(0xFFFDECC8),
    overflowAccent: Color(0xFFB86E00),
    overflowLabel: Color(0xFF85430F),
    // Dark label, as in Modulo Squares: white on this teal is only ~2.8:1.
    buttonBg: Color(0xFF0FA3B1),
    buttonFg: Color(0xFF0A2A2F),
  ),
  GameThemeId.arcadeNeon: GameThemePalette(
    name: 'Arcade Neon',
    pageBg: Color(0xFF11162A),
    textPrimary: Color(0xFFF2F7FF),
    textMuted: Color(0xFF8C9AB8),
    clockTrack: Color(0xFF1E2740),
    clockFill: Color(0xFF00E5FF),
    targetOnBg: Color(0xFF1B2A3D),
    targetOnBorder: Color(0xFF00E5FF),
    targetOnFg: Color(0xFF00E5FF),
    targetOffBorder: Color(0xFF6B7FA8),
    targetOffFg: Color(0xFFB4C0DA),
    matchHit: Color(0xFF39FF88),
    matchMiss: Color(0xFFFF5C5C),
    bitOnBg: Color(0xFF3D7BFF),
    bitOnShadow: Color(0xFF1F47B8),
    bitOnFg: Color(0xFFFFFFFF),
    bitOffBg: Color(0xFF1C2540),
    bitOffBorder: Color(0xFF6B7FA8),
    bitOffFg: Color(0xFFDCE4F5),
    overflowBg: Color(0xFF2A2312),
    overflowAccent: Color(0xFFFFD23D),
    overflowLabel: Color(0xFFFFD23D),
    buttonBg: Color(0xFF00E5FF),
    buttonFg: Color(0xFF05131F),
  ),
  GameThemeId.warmSunset: GameThemePalette(
    name: 'Warm Sunset',
    pageBg: Color(0xFFFFFCF7),
    textPrimary: Color(0xFF3A2418),
    textMuted: Color(0xFF7E5F45),
    clockTrack: Color(0xFFF3E3D6),
    clockFill: Color(0xFF7A3B1E),
    targetOnBg: Color(0xFFFDECC8),
    targetOnBorder: Color(0xFF85430F),
    targetOnFg: Color(0xFF85430F),
    targetOffBorder: Color(0xFFA07B5B),
    targetOffFg: Color(0xFF6A4C35),
    matchHit: Color(0xFF3A2418),
    matchMiss: Color(0xFFB53529),
    // Darkened from Modulo Squares' #E8734A (2.9:1 on this cream page) to
    // clear 3:1; dark digits because white on it fails.
    bitOnBg: Color(0xFFE26A40),
    bitOnShadow: Color(0xFFA94A28),
    bitOnFg: Color(0xFF3A1A0E),
    bitOffBg: Color(0xFFFFF6EC),
    bitOffBorder: Color(0xFFA07B5B),
    bitOffFg: Color(0xFF4E3322),
    overflowBg: Color(0xFFE3F5EA),
    overflowAccent: Color(0xFF2E8B57),
    overflowLabel: Color(0xFF1F6B40),
    buttonBg: Color(0xFF7A3B1E),
    buttonFg: Color(0xFFFFFFFF),
  ),
  GameThemeId.candyPop: GameThemePalette(
    name: 'Candy Pop',
    pageBg: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF3B0A56),
    textMuted: Color(0xFF6E4E82),
    clockTrack: Color(0xFFF1DFF7),
    clockFill: Color(0xFFD6006B),
    targetOnBg: Color(0xFFF3E1FD),
    targetOnBorder: Color(0xFF7B1FA2),
    targetOnFg: Color(0xFF7B1FA2),
    targetOffBorder: Color(0xFFA5789A),
    targetOffFg: Color(0xFF5E3F72),
    matchHit: Color(0xFF3B0A56),
    matchMiss: Color(0xFFB53529),
    bitOnBg: Color(0xFFD6006B),
    bitOnShadow: Color(0xFF9A004D),
    bitOnFg: Color(0xFFFFFFFF),
    bitOffBg: Color(0xFFFBEEF7),
    bitOffBorder: Color(0xFFA5789A),
    bitOffFg: Color(0xFF3B0A56),
    overflowBg: Color(0xFFFFF3C4),
    overflowAccent: Color(0xFFA86F00),
    overflowLabel: Color(0xFF7A5200),
    buttonBg: Color(0xFF7B1FA2),
    buttonFg: Color(0xFFFFFFFF),
  ),
};

/// Display order for the palette picker; Signal is the default for new
/// players.
const List<GameThemeId> gameThemeOrder = [
  GameThemeId.signal,
  GameThemeId.deepOcean,
  GameThemeId.arcadeNeon,
  GameThemeId.warmSunset,
  GameThemeId.candyPop,
];

const GameThemeId defaultGameTheme = GameThemeId.signal;
