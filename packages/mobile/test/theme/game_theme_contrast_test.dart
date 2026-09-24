import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_register_arcade/theme/game_theme.dart';

double _linearChannel(int channel) {
  final value = channel / 255;
  return value <= 0.04045
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color color) {
  final argb = color.toARGB32();
  return 0.2126 * _linearChannel((argb >> 16) & 0xff) +
      0.7152 * _linearChannel((argb >> 8) & 0xff) +
      0.0722 * _linearChannel(argb & 0xff);
}

double _contrast(Color first, Color second) {
  final values = [_luminance(first), _luminance(second)]..sort();
  return (values.last + 0.05) / (values.first + 0.05);
}

/// WCAG AA: 4.5:1 for small text, 3:1 for large text (the 24px register
/// digits) and for non-text marks (borders, ring, check/cross, pips).
const _smallText = 4.5;
const _largeOrNonText = 3.0;

typedef _Pair = (
  String,
  Color Function(GameThemePalette),
  Color Function(GameThemePalette),
  double,
);

final List<_Pair> _pairs = [
  ('textPrimary on pageBg', (p) => p.textPrimary, (p) => p.pageBg, _smallText),
  ('textMuted on pageBg', (p) => p.textMuted, (p) => p.pageBg, _smallText),
  (
    'targetOnFg on targetOnBg',
    (p) => p.targetOnFg,
    (p) => p.targetOnBg,
    _smallText,
  ),
  ('targetOffFg on pageBg', (p) => p.targetOffFg, (p) => p.pageBg, _smallText),
  (
    'overflowLabel on pageBg',
    (p) => p.overflowLabel,
    (p) => p.pageBg,
    _smallText,
  ),
  ('buttonFg on buttonBg', (p) => p.buttonFg, (p) => p.buttonBg, _smallText),
  ('bitOnFg on bitOnBg', (p) => p.bitOnFg, (p) => p.bitOnBg, _largeOrNonText),
  (
    'bitOffFg on bitOffBg',
    (p) => p.bitOffFg,
    (p) => p.bitOffBg,
    _largeOrNonText,
  ),
  (
    'clockFill on clockTrack',
    (p) => p.clockFill,
    (p) => p.clockTrack,
    _largeOrNonText,
  ),
  ('matchHit on pageBg', (p) => p.matchHit, (p) => p.pageBg, _largeOrNonText),
  ('matchMiss on pageBg', (p) => p.matchMiss, (p) => p.pageBg, _largeOrNonText),
  (
    'overflowAccent on overflowBg',
    (p) => p.overflowAccent,
    (p) => p.overflowBg,
    _largeOrNonText,
  ),
  (
    'overflowAccent on pageBg',
    (p) => p.overflowAccent,
    (p) => p.pageBg,
    _largeOrNonText,
  ),
  ('bitOnBg on pageBg', (p) => p.bitOnBg, (p) => p.pageBg, _largeOrNonText),
  // A 0 cell must read as a square against the page, not just a digit.
  (
    'bitOffBorder on pageBg',
    (p) => p.bitOffBorder,
    (p) => p.pageBg,
    _largeOrNonText,
  ),
  (
    'targetOffBorder on pageBg',
    (p) => p.targetOffBorder,
    (p) => p.pageBg,
    _largeOrNonText,
  ),
];

void main() {
  test('every palette in the picker is defined', () {
    for (final id in gameThemeOrder) {
      expect(gameThemePalettes[id], isNotNull, reason: '$id');
    }
    expect(gameThemeOrder.first, defaultGameTheme);
  });

  for (final id in gameThemeOrder) {
    final palette = gameThemePalettes[id]!;
    test('${palette.name} meets WCAG AA', () {
      for (final (name, fg, bg, minimum) in _pairs) {
        expect(
          _contrast(fg(palette), bg(palette)),
          greaterThanOrEqualTo(minimum),
          reason: '${palette.name}: $name must be at least $minimum:1',
        );
      }
    });
  }

  test('overflow never shares the 1-bit color', () {
    for (final id in gameThemeOrder) {
      final p = gameThemePalettes[id]!;
      expect(p.overflowAccent, isNot(p.bitOnBg), reason: p.name);
    }
  });
}
