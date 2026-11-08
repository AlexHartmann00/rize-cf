import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openExternalLink(BuildContext context, String url) async {
  try {
    if (await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication))
      return;
  } catch (_) {
    // The OS may have no handler for this URL.
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Der Link konnte nicht geöffnet werden.')),
    );
  }
}
