import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rize/base_widgets.dart';
import 'package:rize/firestore.dart';
import 'package:rize/globals.dart' as globals;
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

  QuestionnaireEntry get _question => widget.questionnaire.items[_index];
  int get _selectedIndex =>
      _question.responseOptions.indexWhere((option) => option.isSelected);
  bool get _isLast => _index == widget.questionnaire.items.length - 1;

  void _select(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      for (int i = 0; i < _question.responseOptions.length; i++) {
        _question.responseOptions[i].isSelected = i == index;
      }
    });
  }

  Future<void> _continue() async {
    if (_selectedIndex < 0 || _saving) return;
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
      if (globals.userData != null) {
        globals.userData!.intensityScore = widget.questionnaire.totalScore;
      }
      if (mounted) Navigator.pop(context);
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
    final int total = widget.questionnaire.items.length;
    final double progress = (_index + 1) / total;

    return PopScope(
      canPop: _index == 0 && !_saving,
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
                            'Dein RIZE Startpunkt',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Kurz einschätzen. Passender trainieren.',
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
                            const Text(
                              'Wähle die Antwort, die heute am besten zu Dir passt.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ..._question.responseOptions.indexed.map(
                              ((int, QuestionnaireResponseOption) entry) =>
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
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
                  onPressed: _selectedIndex < 0 || _saving ? null : _continue,
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
