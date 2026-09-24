import 'package:flutter/material.dart';
import 'package:game_shell/game_shell.dart';

import '../app/app_services.dart';
import '../settings/difficulty_setting.dart';
import '../theme/game_theme.dart';

/// Settings: the gameplay palette (Appearance) and the relaxed clock
/// (Accessibility). A non-gameplay screen, so it carries the banner like
/// every other menu (SRA-BR-015).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: GameScreenShell(
        adService: services.ads,
        body: ListenableBuilder(
          listenable: Listenable.merge([
            services.theme,
            services.relaxedClock,
            services.difficulty,
          ]),
          builder: (context, _) => ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              const _SectionHeader('Appearance'),
              for (final id in gameThemeOrder)
                _PaletteTile(
                  palette: gameThemePalettes[id]!,
                  selected: id == services.theme.value,
                  onTap: () => services.theme.select(id),
                ),
              const SizedBox(height: 16),
              const _SectionHeader('Difficulty'),
              RadioGroup<Difficulty>(
                groupValue: services.difficulty.value,
                onChanged: (d) {
                  if (d != null) services.difficulty.set(d);
                },
                child: const Column(
                  children: [
                    RadioListTile<Difficulty>(
                      value: Difficulty.easy,
                      title: Text('Easy'),
                      subtitle: Text(
                        'Shows what each cell is worth: 1, 2, 4, 8, 16, 32, '
                        '64, 128',
                      ),
                    ),
                    RadioListTile<Difficulty>(
                      value: Difficulty.hard,
                      title: Text('Hard'),
                      subtitle: Text(
                        'Hides the cell values. Cracked letters score ×1.5',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _SectionHeader('Accessibility'),
              SwitchListTile(
                title: const Text('Relaxed clock'),
                subtitle: const Text('Each clock tick lasts twice as long'),
                value: services.relaxedClock.value,
                onChanged: services.relaxedClock.set,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
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
                shape: BoxShape.circle,
                color: p.overflowAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
