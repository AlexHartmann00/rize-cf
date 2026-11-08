import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rize/helpers/external_link.dart';
import 'package:rize/helpers/rize_style_helpers.dart';

const _key = 'youtubeAlwaysAllowed.v1';
final youtubeConsent = ValueNotifier<bool?>(null);

Future<void> loadYoutubeConsent() async {
  youtubeConsent.value = (await SharedPreferences.getInstance()).getBool(_key);
}

class YoutubeConsentDialog extends StatefulWidget {
  const YoutubeConsentDialog({super.key, this.onSaved});

  final VoidCallback? onSaved;
  @override
  State<YoutubeConsentDialog> createState() => _YoutubeConsentDialogState();
}

class _YoutubeConsentDialogState extends State<YoutubeConsentDialog> {
  bool _saving = false;
  String? _error;

  Future<void> _choose(bool allow) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setBool(_key, allow)) throw StateError('write failed');
      youtubeConsent.value = allow;
      if (mounted) widget.onSaved?.call();
    } catch (_) {
      if (mounted)
        setState(() {
          _saving = false;
          _error =
              'Die Auswahl konnte nicht gespeichert werden. Bitte versuche es erneut.';
        });
    }
  }

  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: const Color(0xFF203954),
      side: const BorderSide(color: Color(0xFF47647E)),
      minimumSize: const Size.fromHeight(48),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      constraints: const BoxConstraints(maxWidth: 420),
      backgroundColor: const Color(0xFF102339),
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF36516A)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 2.65,
              child: Image.asset(
                'assets/onboarding/coach_flo_welcome.png',
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: const Text(
                      'Übungsvideos mit YouTube',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        height: 1.08,
                        letterSpacing: -0.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Möchtest Du Videos automatisch starten oder jedes Video einzeln freigeben?',
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.4,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Beim Laden erhält Google Deine IP-Adresse und kann Cookies setzen. Deine Wahl kannst Du in den Einstellungen ändern.',
                    style: TextStyle(
                      color: rizeMutedText,
                      height: 1.4,
                      fontSize: 14,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      expanded: _showDetails,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: rizeCyan,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () =>
                            setState(() => _showDetails = !_showDetails),
                        iconAlignment: IconAlignment.end,
                        icon: Icon(
                          _showDetails ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                        ),
                        label: const Text('Datenschutz & Cookies'),
                      ),
                    ),
                  ),
                  if (_showDetails) ...[
                    const Text(
                      'Google erhält auch Geräteinformationen und erfährt, welches Video Du ansiehst. Dabei können neben Cookies ähnliche Technologien zum Einsatz kommen.',
                      style: TextStyle(
                        color: rizeMutedText,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    for (final (label, url) in const [
                      (
                        'Google-Datenschutzerklärung',
                        'https://policies.google.com/privacy?hl=de',
                      ),
                      (
                        'Cookie-Hinweise von Google',
                        'https://policies.google.com/technologies/cookies?hl=de',
                      ),
                      (
                        'YouTube-Nutzungsbedingungen',
                        'https://www.youtube.com/t/terms?hl=de',
                      ),
                    ])
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: rizeCyan,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => openExternalLink(context, url),
                          child: Text(label),
                        ),
                      ),
                  ],
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 6),
                  OutlinedButton(
                    style: buttonStyle,
                    onPressed: _saving ? null : () => _choose(true),
                    child: const Text('Immer erlauben'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: buttonStyle,
                    onPressed: _saving ? null : () => _choose(false),
                    child: const Text('Nur einzeln freigeben'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
