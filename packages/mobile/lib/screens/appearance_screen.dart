import 'package:flutter/material.dart';
import 'package:game_shell/game_shell.dart';

import '../app/app_services.dart';
import '../theme/game_theme.dart';

/// Palette picker for the gameplay screen. A non-gameplay screen, so it
/// carries the banner like every other menu (SRA-BR-015). It becomes the
/// Appearance section of Settings once a Settings screen exists.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: GameScreenShell(
        adService: services.ads,
        body: ValueListenableBuilder<GameThemeId>(
          valueListenable: services.theme,
          builder: (context, selected, _) => ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final id in gameThemeOrder)
                _PaletteTile(
                  palette: gameThemePalettes[id]!,
                  selected: id == selected,
                  onTap: () => services.theme.select(id),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final GameThemePalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      selected: selected,
      minTileHeight: 64,
      leading: _Swatch(palette: palette),
      title: Text(palette.name),
      trailing: selected ? const Icon(Icons.check) : null,
    );
  }
}

/// A miniature of the register on the palette's page color: a 1 cell, a 0
/// cell and an overflow pip.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.palette});

  final GameThemePalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    Widget cell({required bool on}) => Container(
          width: 16,
          height: 24,
          decoration: BoxDecoration(
            color: on ? p.bitOnBg : p.bitOffBg,
            borderRadius: BorderRadius.circular(4),
            border: on ? null : Border.all(color: p.bitOffBorder, width: 1.5),
          ),
        );
    return ExcludeSemantics(
      child: Container(
        width: 72,
        height: 40,
        decoration: BoxDecoration(
          color: p.pageBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            cell(on: true),
            const SizedBox(width: 3),
            cell(on: false),
            const SizedBox(width: 6),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: p.overflowAccent),
            ),
          ],
        ),
      ),
    );
  }
}
