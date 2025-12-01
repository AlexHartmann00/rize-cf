import 'package:fitness_app/base_widgets.dart';
import 'package:fitness_app/firestore.dart' show saveAnamnesisResponse;
import 'package:fitness_app/types/anamnesis.dart';
import 'package:fitness_app/types/workout.dart';
import 'package:flutter/material.dart';

class WorkoutSummaryWidget extends StatefulWidget {
  Workout workout;

  WorkoutSummaryWidget({super.key, required this.workout});

  @override
  State<WorkoutSummaryWidget> createState() => _WorkoutSummaryWidgetState();
}

class _WorkoutSummaryWidgetState extends State<WorkoutSummaryWidget> {
  @override
  Widget build(BuildContext context) {
    Workout workout = widget.workout;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkoutDetailsPage(workout: workout),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(100),
          border: Border.all(),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(workout.name),
              Text(workout.workoutType.name),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('Intensität ${workout.impactLevel.name}'),
                  Icon(
                    Icons.flash_on,
                    color: Color.lerp(
                      Colors.green,
                      Colors.red,
                      workout.impactScore,
                    ),
                  ),
                  Column(
                    children: [
                      CircularProgressIndicator(
                        value: workout.impactScore,
                        color: Color.lerp(
                          Colors.green,
                          Colors.red,
                          workout.impactScore,
                        ),
                      ),
                      Text(workout.impactScore.toString()),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${workout.baseSeconds} Sekunden'),
                      Text('${workout.baseReps} Wiederholungen'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkoutDetailsPage extends StatefulWidget {
  Workout workout;
  WorkoutDetailsPage({super.key, required this.workout});

  @override
  State<WorkoutDetailsPage> createState() => _WorkoutDetailsPageState();
}

class _WorkoutDetailsPageState extends State<WorkoutDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return RizeScaffold(
      appBar: rizeAppBar,
      body: Column(
        children: [
          Text(widget.workout.name),
          Text(widget.workout.description),
          Text('${widget.workout.baseReps} Wiederholungen'),
        ],
      ),
    );
  }
}

AppBar rizeAppBar = AppBar(
  backgroundColor: Colors.white,
  title: Row(
    spacing: 10,
    children: [
      Image.asset('assets/brand/Logo transparent.png', height: 50),
      Text('RIZE', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
    ],
  ),
);

class AnamnesisQuestionnaireWidget extends StatefulWidget {
  final AnamnesisQuestionnaire questionnaire;

  const AnamnesisQuestionnaireWidget({super.key, required this.questionnaire});

  @override
  State<AnamnesisQuestionnaireWidget> createState() =>
      _AnamnesisQuestionnaireWidgetState();
}

class _AnamnesisQuestionnaireWidgetState
    extends State<AnamnesisQuestionnaireWidget> {
  // questionIndex -> selected optionIndex
  late final Map<int, int> _selectedOptionPerQuestion;

  @override
  void initState() {
    super.initState();

    // Initialize from existing model state if needed
    _selectedOptionPerQuestion = {};
    for (var qIndex = 0; qIndex < widget.questionnaire.items.length; qIndex++) {
      final question = widget.questionnaire.items[qIndex];
      final selectedIndex = question.responseOptions.indexWhere(
        (o) => o.isSelected,
      );
      if (selectedIndex != -1) {
        _selectedOptionPerQuestion[qIndex] = selectedIndex;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RizeScaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: null,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/brand/Logo transparent.png', height: 50),
            Text(
              'RIZE',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              'Herzlich willkommen bei RIZE!',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Lass uns mit ein paar Fragen deinen aktuellen Fitnesszustand einschätzen:',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge!.copyWith(color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.questionnaire.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, questionIndex) {
                  final question = widget.questionnaire.items[questionIndex];

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Frage ${questionIndex + 1}: ${question.questionTitle}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Divider(),
                          Text(
                            question.questionText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(question.responseOptions.length, (
                            optionIndex,
                          ) {
                            final option =
                                question.responseOptions[optionIndex];

                            return RadioListTile<int>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(option.optionText),
                              value: optionIndex,
                              groupValue:
                                  _selectedOptionPerQuestion[questionIndex],
                              onChanged: (int? newValue) {
                                if (newValue == null) return;
                                setState(() {
                                  _selectedOptionPerQuestion[questionIndex] =
                                      newValue;

                                  // keep underlying model in sync
                                  for (
                                    var i = 0;
                                    i < question.responseOptions.length;
                                    i++
                                  ) {
                                    question.responseOptions[i].isSelected =
                                        i == newValue;
                                  }
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await saveAnamnesisResponse(widget.questionnaire);

                Navigator.of(context).pop();
              },
              child: Text('Los geht\'s!'),
            ),
          ],
        ),
      ),
    );
  }
}
