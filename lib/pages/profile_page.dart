import 'package:flutter/material.dart';
import 'package:rize/globals.dart' as globals;
import 'package:rize/helpers/auth_service.dart';
import 'package:rize/helpers/pro_checkout_service.dart';
import 'package:rize/pages/settings_page.dart';
import 'package:rize/pages/welcome_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _busy = false;

  Future<void> _editName() async {
    final controller = TextEditingController(
      text: authServiceNotifier.value.currentUser?.displayName,
    );
    final String? value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name ändern'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (value == null || value.trim().isEmpty) return;
    await authServiceNotifier.value.updateUsername(value);
    if (mounted) setState(() {});
  }

  Future<void> _resetPassword() async {
    final email = authServiceNotifier.value.currentUser?.email;
    if (email == null) return;
    await authServiceNotifier.value.sendPasswordResetEmail(email);
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwort-Link wurde per E-Mail gesendet.'),
        ),
      );
  }

  Future<void> _startCheckout() async {
    setState(() => _busy = true);
    try {
      await startProCheckout();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelSubscription() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('RIZE Pro kündigen?'),
        content: const Text(
          'Es werden keine weiteren Monatsbeiträge abgebucht. Deinen bereits bezahlten Zugang kannst Du bis zum Ende des Abrechnungszeitraums weiter nutzen.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Pro behalten'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abo kündigen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final DateTime? accessUntil = await cancelProSubscription();
      globals.userData?.subscriptionStatus = 'canceled';
      globals.userData?.proAccessUntil = accessUntil;
      globals.userData?.isPro = accessUntil != null;
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accessUntil == null
                  ? 'RIZE Pro wurde gekündigt.'
                  : 'Gekündigt. Dein Pro-Zugang bleibt bis ${accessUntil.day.toString().padLeft(2, '0')}.${accessUntil.month.toString().padLeft(2, '0')}.${accessUntil.year} aktiv.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authServiceNotifier.value.currentUser;
    final bool isPro = globals.userData?.isPro == true;
    final bool subscriptionCanceled =
        globals.userData?.subscriptionStatus == 'canceled';
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white,
                      child: Text(
                        (user?.displayName ?? 'R')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            user?.displayName ?? 'Sportler',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _editName,
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF1675D1), Color(0xFF0D4A91)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        isPro
                            ? subscriptionCanceled
                                  ? 'RIZE PRO · GEKÜNDIGT'
                                  : 'RIZE PRO AKTIV'
                            : 'RIZE PRO',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isPro
                            ? subscriptionCanceled
                                  ? 'Dein Zugang bleibt bis zum Ende des bezahlten Zeitraums aktiv.'
                                  : 'Du hast Zugriff auf die komplette Bibliothek.'
                            : 'Alle Übungen. Jeder Spin. Dein volles Potenzial.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (!isPro) ...<Widget>[
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _busy ? null : _startCheckout,
                          child: Text(
                            _busy ? 'WIRD GEÖFFNET …' : 'FÜR 3,99 € / MONAT',
                          ),
                        ),
                      ] else if (!subscriptionCanceled) ...<Widget>[
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: _busy ? null : _cancelSubscription,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                          ),
                          child: Text(
                            _busy ? 'WIRD GEKÜNDIGT …' : 'ABO VERWALTEN',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _tile(Icons.person_outline_rounded, 'Name ändern', _editName),
                _tile(
                  Icons.lock_reset_rounded,
                  'Passwort zurücksetzen',
                  _resetPassword,
                ),
                _tile(
                  Icons.settings_rounded,
                  'Einstellungen',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
                ),
                _tile(Icons.logout_rounded, 'Abmelden', () async {
                  await authServiceNotifier.value.signOut();
                  if (context.mounted)
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const WelcomePage()),
                    );
                }, destructive: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool destructive = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: onTap,
      tileColor: Colors.white.withOpacity(0.09),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      leading: Icon(icon, color: destructive ? Colors.redAccent : Colors.white),
      title: Text(
        label,
        style: TextStyle(
          color: destructive ? Colors.redAccent : Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
    ),
  );
}
