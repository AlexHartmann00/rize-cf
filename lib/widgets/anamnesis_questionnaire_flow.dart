import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rize/base_widgets.dart';
import 'package:rize/firestore.dart';
import 'package:rize/helpers/rize_style_helpers.dart';
import 'package:rize/types/anamnesis.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnamnesisQuestionnaireFlow extends StatefulWidget {
  const AnamnesisQuestionnaireFlow({super.key, required this.questionnaire});

  final AnamnesisQuestionnaire questionnaire;

  @override
  State<AnamnesisQuestionnaireFlow> createState() =>
      _AnamnesisQuestionnaireFlowState();
}

class _AnamnesisQuestionnaireFlowState
    extends State<AnamnesisQuestionnaireFlow> {
  int _index = 0;
  bool _saving = false;
  bool _showWelcome = true;

  QuestionnaireEntry get _question => widget.questionnaire.items[_index];
  int get _selectedIndex =>
      _question.responseOptions.indexWhere((option) => option.isSelected);
  bool get _isLast => _index == widget.questionnaire.items.length - 1;
  bool get _canContinue => _question.isAnswered && !_saving;

  void _select(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      for (int i = 0; i < _question.responseOptions.length; i++) {
        _question.responseOptions[i].isSelected = i == index;
      }
    });
  }

  void _setNumber(String value) {
    final int? parsed = int.tryParse(value.trim());
    setState(() {
      _question.numberAnswer = parsed != null && parsed > 0 && parsed <= 120
          ? parsed
          : null;
    });
  }

  Future<void> _continue() async {
    if (!_canContinue) return;
    if (!_isLast) {
      setState(() => _index++);
      return;
    }

    setState(() => _saving = true);
    try {
      await saveAnamnesisResponse(widget.questionnaire);
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.setBool('anamnesisDone', true);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deine Antworten konnten nicht gespeichert werden.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcome) {
      return PopScope<Object?>(
        key: const ValueKey<String>('onboarding-pop-scope'),
        canPop: false,
        child: RizeScaffold(
          appBar: null,
          bottomNavigationBar: null,
          body: SafeArea(
            child: _WelcomeIntro(
              onStart: () {
                HapticFeedback.lightImpact();
                setState(() => _showWelcome = false);
              },
            ),
          ),
        ),
      );
    }

    final int total = widget.questionnaire.items.length;
    final double progress = (_index + 1) / total;

    return PopScope<Object?>(
      key: const ValueKey<String>('onboarding-pop-scope'),
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && _index > 0 && !_saving) setState(() => _index--);
      },
      child: RizeScaffold(
        appBar: null,
        bottomNavigationBar: null,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                child: Row(
                  children: <Widget>[
                    if (_index > 0)
                      IconButton.filledTonal(
                        onPressed: _saving
                            ? null
                            : () => setState(() => _index--),
                        icon: const Icon(Icons.arrow_back_rounded),
                      )
                    else
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: <Color>[rizeCyan, rizeBlue],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                        ),
                      ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Willkommen bei RIZE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Vier kurze Fragen für dein Training.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_index + 1} / $total',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(rizeCyan),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) =>
                          FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.06, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                  child: SingleChildScrollView(
                    key: ValueKey<int>(_index),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: rizeCyan.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _question.questionTitle.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: rizeCyan,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _question.questionText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                height: 1.16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              _question.expectsNumber
                                  ? 'Gib dein Alter in Jahren an.'
                                  : 'Wähle die Antwort, die heute am besten zu dir passt.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_question.expectsNumber)
                              TextFormField(
                                initialValue: _question.numberAnswer
                                    ?.toString(),
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3),
                                ],
                                onChanged: _setNumber,
                                onFieldSubmitted: (_) {
                                  if (_canContinue) _continue();
                                },
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Alter',
                                  hintStyle: const TextStyle(
                                    color: Colors.white38,
                                  ),
                                  suffixText: 'Jahre',
                                  suffixStyle: const TextStyle(
                                    color: Colors.white60,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.075),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 20,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: const BorderSide(
                                      color: rizeCyan,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ..._question.responseOptions.indexed.map(
                                ((int, QuestionnaireResponseOption) entry) =>
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: _AnswerCard(
                                        label: entry.$2.optionText,
                                        selected: entry.$1 == _selectedIndex,
                                        onTap: () => _select(entry.$1),
                                      ),
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                child: FilledButton.icon(
                  onPressed: _canContinue ? _continue : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF10539E),
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isLast
                              ? Icons.auto_awesome_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                  label: Text(
                    _saving
                        ? 'WIRD GESPEICHERT …'
                        : _isLast
                        ? 'MEIN TRAINING STARTEN'
                        : 'WEITER',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeIntro extends StatelessWidget {
  const _WelcomeIntro({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 56).clamp(
                  0,
                  double.infinity,
                ),
                maxWidth: 520,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutBack,
                    tween: Tween<double>(begin: 0, end: 1),
                    builder:
                        (BuildContext context, double value, Widget? child) {
                          return Opacity(
                            opacity: value.clamp(0, 1),
                            child: Transform.translate(
                              offset: Offset((1 - value) * -34, 0),
                              child: Transform.scale(
                                scale: 0.94 + (value * 0.06),
                                child: child,
                              ),
                            ),
                          );
                        },
                    child: Container(
                      key: const ValueKey<String>('coach-flo-welcome'),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: rizeCyan.withValues(alpha: 0.22),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: rizeCyan.withValues(alpha: 0.16),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(29),
                        child: AspectRatio(
                          aspectRatio: 1.46,
                          child: Image.asset(
                            'assets/onboarding/coach_flo_welcome.png',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    'Willkommen bei RIZE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      height: 1.1,
                      letterSpacing: -0.7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Schön, dass du da bist! Ich freue mich darauf, dich bei deinem Training zu begleiten.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Beantworte kurz vier Fragen, damit dein Start genau zu dir passt. Viel Spaß und viel Erfolg!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '„Das Geheimnis des Erfolgs ist anzufangen.“',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: rizeCyan,
                      fontSize: 14,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '– Coach Flo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    key: const ValueKey<String>('start-onboarding'),
                    onPressed: onStart,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(58),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF10539E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text(
                      "LOS GEHT'S",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: selected
                ? rizeCyan.withOpacity(0.16)
                : Colors.white.withOpacity(0.075),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? rizeCyan.withOpacity(0.65)
                  : Colors.white.withOpacity(0.1),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: selected ? rizeCyan : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? rizeCyan : Colors.white38,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF0B3E74),
                        size: 17,
                      )
                    : null,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
