import 'package:flutter/material.dart';
import 'package:game_shell/game_shell.dart';

import '../app/app_services.dart';
import '../settings/difficulty_setting.dart';
import '../theme/game_theme.dart';

/// Settings: the gameplay palette (Appearance), difficulty, the ad-removal
/// purchase (Purchases), and the relaxed clock (Accessibility). A
/// non-gameplay screen, so it carries the banner like every other menu
/// (SRA-BR-015).
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
                      value: Difficulty.normal,
                      title: Text('Normal'),
                      subtitle: Text(
                        'Shows a few cell values — which ones changes every '
                        'round. Cracked letters score ×1.25',
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
              const _SectionHeader('Purchases'),
              _PurchaseSection(entitlement: services.entitlement),
              const SizedBox(height: 16),
              const _SectionHeader('Accessibility'),
              SwitchListTile(
                title: const Text('Relaxed clock'),
                subtitle: const Text('Each clock tick lasts twice as long'),
                value: services.relaxedClock.value,
                onChanged: services.relaxedClock.set,
              ),
              const SizedBox(height: 16),
              const _SectionHeader('Legal'),
              _LegalLink(
                label: 'Privacy Policy',
                url: legalUrls.privacy,
                openUrl: services.openUrl,
              ),
              _LegalLink(
                label: 'Terms of Use',
                url: legalUrls.terms,
                openUrl: services.openUrl,
              ),
              _LegalLink(
                label: 'Support',
                url: legalUrls.support,
                openUrl: services.openUrl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where this game's Privacy/Terms/Support pages live. Shift-Register has
/// no marketing site of its own (unlike Modulo Squares, which has a
/// separate site/repo/domain) — these are lightweight pages on the Nelson
/// Grey site instead; see docs/STORE_SETUP.md.
class _LegalUrls {
  const _LegalUrls();

  static const _base = 'https://nelsongrey.com/games/intercept-echo';

  Uri get privacy => Uri.parse('$_base/privacy');
  Uri get terms => Uri.parse('$_base/terms');
  Uri get support => Uri.parse('$_base/support');
}

const legalUrls = _LegalUrls();

class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.label,
    required this.url,
    required this.openUrl,
  });

  final String label;
  final Uri url;
  final UrlOpener openUrl;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => openUrl(url),
    );
  }
}

/// Ad-free status, the one-time "Remove Ads" purchase (SRA-BR-007: a
/// single $2.99 IAP, matching Modulo Squares), and Restore Purchases.
/// [EntitlementService] isn't a [Listenable] — it reports changes on
/// [EntitlementService.adFreeChanges] instead — so this rebuilds off a
/// [StreamBuilder], seeded with the already-loaded [isAdFree] value.
class _PurchaseSection extends StatelessWidget {
  const _PurchaseSection({required this.entitlement});

  final EntitlementService entitlement;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: entitlement.adFreeChanges,
      initialData: entitlement.isAdFree,
      builder: (context, snapshot) {
        final adFree = snapshot.data ?? false;
        return Column(
          children: [
            ListTile(
              leading: Icon(
                adFree ? Icons.check_circle_outline : Icons.tv_off_outlined,
              ),
              title: Text(adFree ? 'Ad-free' : 'Ads on'),
              subtitle: Text(
                adFree
                    ? 'You will never see an ad in this game.'
                    : 'A banner and the occasional interstitial support '
                          'free play.',
              ),
            ),
            if (!adFree)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: FilledButton(
                  onPressed: () => _purchase(context),
                  child: const Text('Remove Ads — \$2.99'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: OutlinedButton(
                onPressed: () => _restore(context),
                child: const Text('Restore Purchases'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _purchase(BuildContext context) async {
    try {
      await entitlement.purchaseAdRemoval();
      // The store's own payment sheet handles the flow from here; a
      // completed purchase arrives through adFreeChanges above.
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _restore(BuildContext context) async {
    await entitlement.restore();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Purchases restored.')));
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
