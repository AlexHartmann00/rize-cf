import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                      'Deine Tagesaufgabe wählt aktuell aus $availableCount passenden Übungen.',
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

class ProFeatureLock extends StatelessWidget {
  const ProFeatureLock({
    super.key,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.065),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: rizeOrange.withOpacity(0.24)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: rizeOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFFFFB27D),
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Text(
                          'PRO',
                          style: TextStyle(
                            color: Color(0xFFFFB27D),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
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
  ProBillingPeriod _billingPeriod = ProBillingPeriod.monthly;

  Future<void> _checkout() async {
    final bool? billingDetailsReady = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: const _BillingDetailsSheet(),
      ),
    );
    if (billingDetailsReady != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await startProCheckout(billingPeriod: _billingPeriod);
      if (mounted) Navigator.of(context).pop();
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
    return Container(
      key: const ValueKey<String>('pro-upgrade-sheet-background'),
      decoration: const BoxDecoration(
        color: Color(0xFF102F55),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
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
                'Mit RIZE Pro greift jede Tagesaufgabe auf die vollständige Übungsbibliothek zu.',
                style: TextStyle(color: Colors.white60, height: 1.45),
              ),
              const SizedBox(height: 18),
              SegmentedButton<ProBillingPeriod>(
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((
                    Set<WidgetState> states,
                  ) {
                    return states.contains(WidgetState.selected)
                        ? const Color(0xFF102F55)
                        : Colors.white;
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    Set<WidgetState> states,
                  ) {
                    return states.contains(WidgetState.selected)
                        ? const Color(0xFFE8F0FF)
                        : Colors.transparent;
                  }),
                  side: WidgetStateProperty.all<BorderSide>(
                    const BorderSide(color: Colors.white54, width: 1.2),
                  ),
                ),
                segments: const <ButtonSegment<ProBillingPeriod>>[
                  ButtonSegment<ProBillingPeriod>(
                    value: ProBillingPeriod.monthly,
                    label: Text('MONATLICH'),
                  ),
                  ButtonSegment<ProBillingPeriod>(
                    value: ProBillingPeriod.yearly,
                    label: Text('JÄHRLICH'),
                  ),
                ],
                selected: <ProBillingPeriod>{_billingPeriod},
                showSelectedIcon: false,
                onSelectionChanged: _loading
                    ? null
                    : (Set<ProBillingPeriod> selection) {
                        setState(() => _billingPeriod = selection.first);
                      },
              ),
              const SizedBox(height: 18),
              const _Benefit(
                icon: Icons.cyclone_rounded,
                text: 'Alle Übungen in der Tagesaufgabe',
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
                    : Text(
                        _billingPeriod == ProBillingPeriod.monthly
                            ? 'RIZE PRO · 3,99 € / MONAT'
                            : 'RIZE PRO · 39,90 € / JAHR',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
              const SizedBox(height: 9),
              Text(
                _billingPeriod == ProBillingPeriod.monthly
                    ? 'Monatliche Verlängerung, wenn nicht gekündigt.'
                    : 'Jährliche Verlängerung, wenn nicht gekündigt. Du zahlst nur 10 statt 12 Monate.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BillingDetailsSheet extends StatefulWidget {
  const _BillingDetailsSheet();

  @override
  State<_BillingDetailsSheet> createState() => _BillingDetailsSheetState();
}

class _BillingDetailsSheetState extends State<_BillingDetailsSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _street = TextEditingController();
  final TextEditingController _postalCode = TextEditingController();
  final TextEditingController _city = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final BillingProfile profile = await loadBillingProfile();
      _name.text = profile.fullName;
      _street.text = profile.street;
      _postalCode.text = profile.postalCode;
      _city.text = profile.city;
    } catch (_) {
      // Autofill and manual entry remain available if prefill fails.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _street.dispose();
    _postalCode.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    try {
      await saveBillingProfile(
        BillingProfile(
          fullName: _name.text,
          street: _street.text,
          postalCode: _postalCode.text,
          city: _city.text,
        ),
      );
      TextInput.finishAutofillContext();
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Bitte ausfüllen' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('billing-details-sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF102F55),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
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
                  const SizedBox(height: 20),
                  const Text(
                    'Kurz für Deine Rechnung',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Einmal ausfüllen – beim nächsten Mal ist schon alles da.',
                    style: TextStyle(color: Colors.white60, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 70),
                      child: Center(
                        child: CircularProgressIndicator(color: rizeCyan),
                      ),
                    )
                  else ...<Widget>[
                    _BillingField(
                      key: const ValueKey<String>('billing-name'),
                      controller: _name,
                      label: 'Vor- und Nachname',
                      icon: Icons.person_outline_rounded,
                      autofillHints: const <String>[AutofillHints.name],
                      validator: _required,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _BillingField(
                      key: const ValueKey<String>('billing-street'),
                      controller: _street,
                      label: 'Straße und Hausnummer',
                      icon: Icons.home_outlined,
                      autofillHints: const <String>[
                        AutofillHints.streetAddressLine1,
                      ],
                      validator: _required,
                      keyboardType: TextInputType.streetAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: 120,
                          child: _BillingField(
                            key: const ValueKey<String>('billing-postal-code'),
                            controller: _postalCode,
                            label: 'PLZ',
                            icon: Icons.pin_drop_outlined,
                            autofillHints: const <String>[
                              AutofillHints.postalCode,
                            ],
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(5),
                            ],
                            validator: (String? value) =>
                                RegExp(r'^\d{5}$').hasMatch(value?.trim() ?? '')
                                ? null
                                : '5 Ziffern',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BillingField(
                            key: const ValueKey<String>('billing-city'),
                            controller: _city,
                            label: 'Ort',
                            icon: Icons.location_city_outlined,
                            autofillHints: const <String>[
                              AutofillHints.addressCity,
                            ],
                            validator: _required,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _save(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Row(
                        children: <Widget>[
                          Icon(
                            Icons.public_rounded,
                            color: Colors.white54,
                            size: 20,
                          ),
                          SizedBox(width: 11),
                          Text(
                            'Deutschland',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const ValueKey<String>('save-billing-profile'),
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(55),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF104F96),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'WEITER ZU MOLLIE',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Sicher gespeichert und nur für Deine Rechnungen verwendet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BillingField extends StatelessWidget {
  const _BillingField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.autofillHints,
    required this.validator,
    required this.textInputAction,
    this.keyboardType,
    this.inputFormatters,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Iterable<String> autofillHints;
  final String? Function(String?) validator;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofillHints: autofillHints,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: TextCapitalization.words,
      inputFormatters: inputFormatters,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: rizeCyan, size: 21),
        filled: true,
        fillColor: Colors.white.withOpacity(0.075),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: rizeCyan, width: 1.4),
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
