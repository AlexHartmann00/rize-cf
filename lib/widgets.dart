import 'package:flutter/services.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:rize/audio_player.dart';
import 'package:rize/base_widgets.dart';
import 'package:rize/firestore.dart'
    show saveAnamnesisResponse, uploadWorkoutToServer, updateUserIntensityScore;
import 'package:rize/types/anamnesis.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/globals.dart' as globals;
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:shared_preferences/shared_preferences.dart';

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
              Text(workout.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
              Text(workout.workoutType == WorkoutType.static
                  ? 'Statisch'
                  : 'Dynamisch'),
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
                      Text(workout.durationString),
                    ],
                  ),
                ],
              ),
              Text(workout.usedMuscleGroups.join(', ')),
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
      body: DefaultTextStyle(
        style: TextStyle(color: Colors.white, fontSize: 20),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                widget.workout.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
              ),
              Divider(),
              Text(
                'Beschreibung',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              Text(widget.workout.description),
              Divider(),
              Text(
                'Tipps',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              Text(widget.workout.coachingCues),
            ],
          ),
        ),
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
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('anamnesisDone', true);
                globals.userData!.intensityScore =
                    widget.questionnaire.totalScore;
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

class WorkoutScheduleWidget extends StatefulWidget {
  ScheduledWorkout workout;
  WorkoutScheduleWidget({super.key, required this.workout});

  @override
  State<WorkoutScheduleWidget> createState() => _WorkoutScheduleWidgetState();
}

class _WorkoutScheduleWidgetState extends State<WorkoutScheduleWidget> {
  @override
  Widget build(BuildContext context) {
    List<Widget> scheduleEntries = [];

    int i = 1;
    for (WorkoutStep scheduleEntry in widget.workout.schedule) {
      scheduleEntries.add(
        Column(
          children: [
            Text(
              'Runde $i',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 22,
              ),
            ),
            SizedBox(height: 5),
            _buildScheduleEntry(scheduleEntry, i - 1),
          ],
        ),
      );

      if (i < widget.workout.schedule.length) {
        scheduleEntries.add(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: VerticalDivider(color: Colors.black, width: 6),
          ),
        );
      }

      i++;
    }

    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: scheduleEntries,
      ),
    );
  }

  Widget _buildScheduleEntry(WorkoutStep scheduleEntry, int entryIndex) {
    TimeOfDay timeOfDay = scheduleEntry.timeOfDay;
    int plannedUnits = scheduleEntry.plannedUnits;
    int completedUnits = scheduleEntry.completedUnits;

    bool completed = plannedUnits <= completedUnits;

    return Column(
      children: [
        if (timeOfDay != TimeOfDay.any)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, color: Colors.white),
              SizedBox(width: 5),
              Text(
                _timeOfDayToString(timeOfDay),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        Text(
          widget.workout.durationStringShort,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 14,
          ),
        ),

        IconButton(
          onPressed: completed
              ? () {}
              : () async {
                  if (timeOfDay != TimeOfDay.any) {
                    DateTime now = DateTime.now();
                    if ((timeOfDay == TimeOfDay.morning &&
                            (now.hour < 5 || now.hour >= 12)) ||
                        (timeOfDay == TimeOfDay.afternoon &&
                            (now.hour < 12 || now.hour >= 17)) ||
                        (timeOfDay == TimeOfDay.evening &&
                            (now.hour < 17 || now.hour >= 22))) {
                      // show alert dialog that workout can only be completed in the specified time frame
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Nicht im richtigen Zeitraum'),
                            content: Text(
                              'Dieses Training kann nur im angegebenen Zeitraum abgeschlossen werden.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                      return;
                    }
                  }

                  bool completed = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorkoutExecutionPage(
                        workout: widget.workout,
                        scheduleEntryIndex: entryIndex,
                      ),
                    ),
                  );
                  setState(() {
                    completedUnits++;
                    if (completedUnits > plannedUnits) {
                      completedUnits = plannedUnits;
                    }
                    widget.workout.schedule[entryIndex] = WorkoutStep(
                      timeOfDay: timeOfDay,
                      plannedUnits: plannedUnits,
                      completedUnits: completedUnits,
                    );
                  });
                  // setState(() {
                  //   completedUnits++;
                  //   if(completedUnits > plannedUnits) {
                  //     completedUnits = plannedUnits;
                  //   }
                  //   int index = widget.workout.schedule.indexOf(scheduleEntry);
                  //   widget.workout.schedule[index] = (timeOfDay, plannedUnits, completedUnits);
                  // });
                  // await uploadWorkoutToServer(widget.workout);
                },
          icon: Container(
            width: 90,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.transparent),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: completed
                  ? Icon(Icons.check, color: Colors.green)
                  : Text(
                      'LOS',
                      style: TextStyle(
                        color: Theme.of(context).primaryColorDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  String _timeOfDayToString(TimeOfDay timeOfDay) {
    switch (timeOfDay) {
      case TimeOfDay.morning:
        return 'Morgens (vor 12 Uhr)';
      case TimeOfDay.afternoon:
        return 'Nachmittags (12-17 Uhr)';
      case TimeOfDay.evening:
        return 'Abends (17-22 Uhr)';
      case TimeOfDay.any:
        return 'Beliebig';
    }
  }
}

class WorkoutExecutionPage extends StatefulWidget {
  ScheduledWorkout workout;
  int scheduleEntryIndex;
  WorkoutExecutionPage({
    super.key,
    required this.workout,
    required this.scheduleEntryIndex,
  });

  @override
  State<WorkoutExecutionPage> createState() => _WorkoutExecutionPageState();
}

class _WorkoutExecutionPageState extends State<WorkoutExecutionPage> {
  //TODO: Possibility to start another set of reps/seconds if the user wants to do more than planned
  //TODO: Implement thresholds etc. on Firebase side
  //TODO: Login via Apple and Google
  //TODO: After workout, show feedback icons for workout difficulty (1-5)
  //10 sec timer before start of the timer "get into position"
  //+/- buttons for reps-dependent workouts

  bool showTimer = false;
  int timerSeconds = 0;
  bool timerCompleted = false;
  int managedRepetitions = 0;
  @override
  Widget build(BuildContext context) {
    final int maxReps =
    (widget.workout.baseReps ?? 0) * widget.workout.intensityFactor;
    return RizeScaffold(
      appBar: rizeAppBar,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(),
          Text(
            widget.workout.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          Text(
            'Runde ${widget.scheduleEntryIndex + 1}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          //if(widget.workout.baseSeconds != null)
          Text(
            '${widget.workout.durationString}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          if (widget.workout.baseSeconds != null &&
              !showTimer &&
              !timerCompleted)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  showTimer = true;
                  timerSeconds =
                      (widget.workout.baseSeconds ?? 0) *
                      widget.workout.intensityFactor;
                  Future.doWhile(() async {
                    if (!mounted) return false;
                    await Future.delayed(Duration(seconds: 1));
                    setState(() {
                      timerSeconds -= 1;
                    });
                    if (timerSeconds <= 0) {
                      HapticFeedback.vibrate();
                      //playTimerSound();
                      setState(() {
                        showTimer = false;
                        timerCompleted = true;
                      });
                    }
                    return showTimer;
                  });
                });
              },
              child: Text('Timer starten'),
            ),
          if (showTimer && widget.workout.baseSeconds != null)
            Text(
              timerSeconds.toString(),
              style: TextStyle(
                fontSize: 48,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (widget.workout.baseReps != null)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NumberPicker(
                axis: Axis.vertical,
                value: managedRepetitions.clamp(0, maxReps),
                minValue: 0,
                maxValue: maxReps,
                itemHeight: 50,
                itemWidth: 90,
                step: 1,
                haptics: true,
                selectedTextStyle: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                textStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.45),
                ),
                onChanged: (int v) => setState(() => managedRepetitions = v),
              ),
              const SizedBox(height: 10),
              const Text(
                'Wiederholungen geschafft',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
            // Column(
            //   children: [
            //     Row(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: [
            //         IconButton(
            //           onPressed: () {
            //             setState(() {
            //               if (managedRepetitions == 0) return;
            //               managedRepetitions--;
            //             });
            //           },
            //           icon: Container(
            //             decoration: BoxDecoration(
            //               color: Colors.white,
            //               borderRadius: BorderRadius.circular(5),
            //             ),
            //             child: Padding(
            //               padding: const EdgeInsets.all(8.0),
            //               child: Icon(Icons.remove),
            //             ),
            //           ),
            //         ),
            //         Container(
            //           width: 50,
            //           height: 50,
            //           decoration: BoxDecoration(
            //             color: Colors.white,
            //             borderRadius: BorderRadius.circular(5),
            //           ),
            //           child: Center(
            //             child: Text(
            //               managedRepetitions.toString(),
            //               style: TextStyle(
            //                 fontSize: 25,
            //                 fontWeight: FontWeight.bold,
            //               ),
            //             ),
            //           ),
            //         ),
            //         IconButton(
            //           onPressed: () {
            //             setState(() {
            //               managedRepetitions++;
            //               widget.workout.int
            //             });
            //           },
            //           icon: Container(
            //             decoration: BoxDecoration(
            //               color: Colors.white,
            //               borderRadius: BorderRadius.circular(5),
            //             ),
            //             child: Padding(
            //               padding: const EdgeInsets.all(8.0),
            //               child: Icon(Icons.add),
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //     Text(
            //       'Wiederholungen geschafft',
            //       style: TextStyle(
            //         color: Colors.white,
            //         fontSize: 25,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //   ],
            // ),
          if (timerCompleted || widget.workout.baseReps != null)
            IconButton(
              onPressed: () async {
                bool completed = widget.workout.baseReps != null
                      ? managedRepetitions >= maxReps
                      : true;
                setState(() {
                  showTimer = false;
                  WorkoutStep workoutStep =
                      widget.workout.schedule[widget.scheduleEntryIndex];

                  
                  widget.workout.schedule[widget.scheduleEntryIndex] =
                      WorkoutStep(
                        timeOfDay: workoutStep.timeOfDay,
                        plannedUnits: workoutStep.plannedUnits,
                        completedUnits: completed ? workoutStep.plannedUnits : 0,
                      );
                });

                await uploadWorkoutToServer(widget.workout);
                
                Navigator.of(context).pop(completed);
              },
              icon: Container(
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(
                        'Runde abschließen',
                        style: TextStyle(
                          color: Theme.of(context).primaryColorDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.check, color: Colors.green),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
