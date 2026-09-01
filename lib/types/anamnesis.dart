class AnamnesisQuestionnaire {
  List<QuestionnaireEntry> entries;

  List<QuestionnaireEntry> get items => entries;
  double get totalScore {
    final List<QuestionnaireEntry> weightedEntries = entries
        .where((QuestionnaireEntry entry) => entry.weightInScore > 0)
        .toList(growable: false);

    // Keep legacy questionnaires functional while all clients migrate to the
    // role-based onboarding schema.
    if (weightedEntries.isEmpty) {
      final List<double> selectedValues = entries
          .expand(
            (QuestionnaireEntry entry) => entry.responseOptions
                .where(
                  (QuestionnaireResponseOption option) => option.isSelected,
                )
                .map(
                  (QuestionnaireResponseOption option) => option.optionValue,
                ),
          )
          .toList(growable: false);
      if (selectedValues.isEmpty) return 0;
      return selectedValues.reduce((double a, double b) => a + b) /
          selectedValues.length;
    }

    double score = 0;
    for (final QuestionnaireEntry entry in weightedEntries) {
      score += entry.weightInScore * entry.selectedOption!.optionValue;
    }

    final QuestionnaireEntry? returnQuestion = _entryWithRole(
      'safety_multiplier',
    );
    score *= returnQuestion?.selectedOption?.multiplier ?? 1;

    final QuestionnaireEntry? ageQuestion = _entryWithRole('safety_cap');
    final int? age = ageQuestion?.numberAnswer;
    if (age != null) score = score.clamp(0, _ageCap(age));

    return score.clamp(0.10, 1.00).toDouble();
  }

  QuestionnaireEntry? _entryWithRole(String role) {
    for (final QuestionnaireEntry entry in entries) {
      if (entry.role == role) return entry;
    }
    return null;
  }

  double _ageCap(int age) {
    if (age < 30) return 1.00;
    if (age < 45) return 0.90;
    if (age < 60) return 0.78;
    if (age < 70) return 0.65;
    return 0.52;
  }

  AnamnesisQuestionnaire({required this.entries});

  factory AnamnesisQuestionnaire.fromJson(Map<String, dynamic> json) {
    List entriesFromJson = json['entries'] as List;
    List<QuestionnaireEntry> entriesList = entriesFromJson
        .map((entry) => QuestionnaireEntry.fromJson(entry))
        .toList();

    return AnamnesisQuestionnaire(entries: entriesList);
  }
}

class QuestionnaireEntry {
  String id;
  int order;
  String role;
  double weightInScore;
  String input;
  String questionText;
  String questionTitle;
  List<QuestionnaireResponseOption> responseOptions;
  int? numberAnswer;

  QuestionnaireEntry({
    this.id = '',
    this.order = 0,
    this.role = '',
    this.weightInScore = 0,
    this.input = 'single_select',
    required this.questionText,
    required this.questionTitle,
    required this.responseOptions,
  });

  bool get expectsNumber => input == 'number';

  QuestionnaireResponseOption? get selectedOption {
    for (final QuestionnaireResponseOption option in responseOptions) {
      if (option.isSelected) return option;
    }
    return null;
  }

  bool get isAnswered => expectsNumber
      ? numberAnswer != null && numberAnswer! > 0 && numberAnswer! <= 120
      : selectedOption != null;

  factory QuestionnaireEntry.fromJson(Map<String, dynamic> json) {
    List optionsFromJson = json['responseOptions'] as List;
    List<QuestionnaireResponseOption> responseOptionsList = optionsFromJson
        .map((option) => QuestionnaireResponseOption.fromJson(option))
        .toList();

    return QuestionnaireEntry(
      id: json['id'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      role: json['role'] as String? ?? '',
      weightInScore: (json['weightInScore'] as num?)?.toDouble() ?? 0,
      input: json['input'] as String? ?? 'single_select',
      questionText: json['questionText'] as String,
      questionTitle: json['questionTitle'] as String,
      responseOptions: responseOptionsList,
    );
  }
}

class QuestionnaireResponseOption {
  String optionText;
  double optionValue;
  double? multiplier;
  bool isSelected = false;

  QuestionnaireResponseOption({
    required this.optionText,
    required this.optionValue,
    this.multiplier,
  });

  factory QuestionnaireResponseOption.fromJson(Map<String, dynamic> json) {
    return QuestionnaireResponseOption(
      optionText: json['optionText'],
      optionValue: (json['optionValue'] as num?)?.toDouble() ?? 0,
      multiplier: (json['multiplier'] as num?)?.toDouble(),
    );
  }
}
