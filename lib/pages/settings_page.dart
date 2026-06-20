import 'package:flutter/material.dart';
import 'package:rize/base_widgets.dart';
import 'package:rize/firestore.dart';
import 'package:rize/globals.dart' as globals;
import 'package:rize/utils.dart' show Time;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Time? _reminderTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reminderTime = globals.userData?.spinReminderTime;
  }

  Future<void> _setReminder(Time? value) async {
    if (_saving) return;
    setState(() {
      _reminderTime = value;
      _saving = true;
    });
    try {
      await updateSpinReminderTime(value);
      globals.userData?.spinReminderTime = value;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Die Erinnerung konnte nicht gespeichert werden.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _chooseTime() async {
    final Time current = _reminderTime ?? Time(16, 30);
    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'ERINNERUNGSZEIT',
      cancelText: 'ABBRECHEN',
      confirmText: 'ÜBERNEHMEN',
      builder: (BuildContext context, Widget? child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF58C7F5),
            surface: Color(0xFF15375F),
          ),
        ),
        child: child!,
      ),
    );
    if (selected != null) {
      await _setReminder(Time(selected.hour, selected.minute));
    }
  }

  String get _formattedTime {
    final Time value = _reminderTime ?? Time(16, 30);
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')} Uhr';
  }

  @override
  Widget build(BuildContext context) {
    return RizeScaffold(
      appBar: null,
      bottomNavigationBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton.filledTonal(
                        tooltip: 'Zurück',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Einstellungen',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                            Text(
                              'Passe RIZE an Deinen Alltag an.',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'BENACHRICHTIGUNGEN',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const _SettingsIcon(
                              icon: Icons.notifications_active_rounded,
                              color: Color(0xFF58C7F5),
                            ),
                            const SizedBox(width: 13),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Daily-Spin-Erinnerung',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Ein freundlicher Impuls zu Deiner Wunschzeit.',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_saving)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Switch.adaptive(
                                value: _reminderTime != null,
                                onChanged: (bool enabled) =>
                                    _setReminder(enabled ? Time(16, 30) : null),
                              ),
                          ],
                        ),
                        if (_reminderTime != null) ...<Widget>[
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _saving ? null : _chooseTime,
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.schedule_rounded,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Erinnerungszeit',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formattedTime,
                                    style: const TextStyle(
                                      color: Color(0xFF7ED8FF),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white38,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _SettingsCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _SettingsIcon(
                          icon: Icons.local_fire_department_rounded,
                          color: Color(0xFFFF9857),
                        ),
                        SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      'Serienschutz',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '16:30',
                                    style: TextStyle(
                                      color: Color(0xFFFFB27D),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Wenn Deine Serie läuft und heute noch kein Workout erledigt ist, erinnern wir Dich automatisch.',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Benachrichtigungen können zusätzlich in den Systemeinstellungen Deines Geräts deaktiviert sein.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.42),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.085),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}
