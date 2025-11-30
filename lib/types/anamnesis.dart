class AnamnesisQuestionnaire {
  List<QuestionnaireEntry> entries;

  List<QuestionnaireEntry> get items => entries;
  double get totalScore {
    double score = 0.0;
    for (var entry in entries) {
      for (var option in entry.responseOptions) {
        if (option.isSelected) {
          score += option.optionValue;
        }
      }
    }
    return score / entries.length;
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
  String questionText;
  String questionTitle;
  List<QuestionnaireResponseOption> responseOptions;

  QuestionnaireEntry({
    required this.questionText,
    required this.questionTitle,
    required this.responseOptions,
  });

  factory QuestionnaireEntry.fromJson(Map<String, dynamic> json) {
    List optionsFromJson = json['responseOptions'] as List;
    List<QuestionnaireResponseOption> responseOptionsList = optionsFromJson
        .map((option) => QuestionnaireResponseOption.fromJson(option))
        .toList();

    return QuestionnaireEntry(
      questionText: json['questionText'],
      questionTitle: json['questionTitle'],
      responseOptions: responseOptionsList,
    );
  }
}

class QuestionnaireResponseOption {
  String optionText;
  double optionValue;
  bool isSelected = false;

  QuestionnaireResponseOption({
    required this.optionText,
    required this.optionValue,
  });

  factory QuestionnaireResponseOption.fromJson(Map<String, dynamic> json) {
    return QuestionnaireResponseOption(
      optionText: json['optionText'],
      optionValue: json['optionValue'].toDouble(),
    );
  }
}
