import 'package:flutter/material.dart';
import 'package:rize/helpers/pro_checkout_service.dart';
import 'package:rize/helpers/rize_style_helpers.dart';

Future<void> showProUpgradeSheet(
  BuildContext context, {
  required String source,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      assert(source.isNotEmpty);
      return const _ProUpgradeSheet();
    },
  );
}

class ProUpgradeBanner extends StatelessWidget {
  const ProUpgradeBanner({
    super.key,
    required this.availableCount,
    required this.onTap,
  });

  final int availableCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                rizeOrange.withOpacity(0.17),
                rizeBlue.withOpacity(0.14),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: rizeOrange.withOpacity(0.25)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: rizeOrange.withOpacity(0.17),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFFFB27D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Mehr Abwechslung mit RIZE Pro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Dein Spin wählt aktuell aus $availableCount passenden Übungen.',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProUpgradeSheet extends StatefulWidget {
  const _ProUpgradeSheet();

  @override
  State<_ProUpgradeSheet> createState() => _ProUpgradeSheetState();
}

class _ProUpgradeSheetState extends State<_ProUpgradeSheet> {
  bool _loading = false;

  Future<void> _checkout() async {
    setState(() => _loading = true);
    try {
      await startProCheckout();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
        decoration: const BoxDecoration(
          color: Color(0xFF102F55),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[rizeOrange, rizeBlue],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Dein Training. Ohne Limits.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                height: 1.1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Mit RIZE Pro greift jeder Daily Spin auf die vollständige Übungsbibliothek zu.',
              style: TextStyle(color: Colors.white60, height: 1.45),
            ),
            const SizedBox(height: 18),
            const _Benefit(
              icon: Icons.cyclone_rounded,
              text: 'Alle Übungen im Daily Spin',
            ),
            const _Benefit(
              icon: Icons.lock_open_rounded,
              text: 'Vollständige Trainingsbibliothek',
            ),
            const _Benefit(
              icon: Icons.auto_awesome_rounded,
              text: 'Mehr Abwechslung bei passender Intensität',
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _checkout,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF104F96),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'RIZE PRO · 3,99 € / MONAT',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Monatlich kündbar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: <Widget>[
        Icon(icon, color: rizeCyan, size: 20),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
