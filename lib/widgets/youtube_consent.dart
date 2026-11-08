import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rize/helpers/external_link.dart';

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

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Darf RIZE YouTube-Videos anzeigen?'),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Wenn Du zustimmst, starten Übungsvideos automatisch. Beim Laden erhält Google unter anderem Deine IP-Adresse und Informationen zu Deinem Gerät und zum angesehenen Video. Google kann Cookies und ähnliche Technologien verwenden.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Du kannst auch jedes Video einzeln freigeben. Deine Wahl kannst Du jederzeit in den Einstellungen ändern.',
        ),
        for (final (label, url) in const [
          (
            'Google-Datenschutzerklärung',
            'https://policies.google.com/privacy?hl=de',
          ),
          (
            'So verwendet Google Cookies',
            'https://policies.google.com/technologies/cookies?hl=de',
          ),
          (
            'YouTube-Nutzungsbedingungen',
            'https://www.youtube.com/t/terms?hl=de',
          ),
        ])
          TextButton(
            onPressed: () => openExternalLink(context, url),
            child: Text(label),
          ),
        if (_error != null) Text(_error!),
      ],
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => _choose(false),
        child: const Text('Nur einzeln freigeben'),
      ),
      TextButton(
        onPressed: _saving ? null : () => _choose(true),
        child: const Text('Immer erlauben'),
      ),
    ],
  );
}
