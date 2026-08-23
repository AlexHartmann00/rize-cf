import 'package:flutter/material.dart';
import 'package:rize/base_widgets.dart';
import 'package:rize/pages/workout_execution_page.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets/muscle_visualizer.dart';
import 'package:rize/widgets/workout_details_widgets.dart';
import 'package:rize/youtube.dart';

class WorkoutDetailsPage extends StatelessWidget {
  const WorkoutDetailsPage({super.key, required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return RizeScaffold(
      appBar: null,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: WorkoutDetailsHero(
                    workout: workout,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(<Widget>[
                      if (_hasYoutubeVideo) ...<Widget>[
                        WorkoutDetailsSection(
                          title: 'Technik ansehen',
                          subtitle:
                              'Schau Dir die Bewegung in Ruhe an, bevor Du startest.',
                          icon: Icons.play_circle_outline_rounded,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: YoutubeVideo(
                              videoId: workout.youtubeVideoId,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      WorkoutDetailsSection(
                        title: 'Darum geht es',
                        icon: Icons.info_outline_rounded,
                        child: WorkoutDetailsBodyText(
                          text: workout.description,
                        ),
                      ),
                      if (workout.usedMuscleGroups.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 14),
                        WorkoutDetailsSection(
                          title: 'Trainierte Muskelgruppen',
                          subtitle:
                              'Rot ist der Hauptfokus, Orange zeigt weitere beteiligte Bereiche.',
                          icon: Icons.accessibility_new_rounded,
                          child: MuscleVisualization(
                            workout: workout,
                            large: true,
                          ),
                        ),
                      ],
                      if (workout.isUnilateral) ...<Widget>[
                        const SizedBox(height: 14),
                        UnilateralWorkoutCard(
                          helpText: workout.unilateralHelpText,
                        ),
                      ],
                      const SizedBox(height: 14),
                      WorkoutDetailsSection(
                        title: 'Coach-Flo-Tipp',
                        subtitle:
                            'Darauf solltest Du während der Bewegung achten.',
                        icon: Icons.psychology_alt_rounded,
                        child: CoachingCueList(
                          coachingCues: workout.coachingCues,
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: WorkoutDetailsBottomAction(
                workout: workout,
                onStart: () => _startWorkout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasYoutubeVideo {
    return workout.youtubeVideoId.isNotEmpty;
  }

  Future<void> _startWorkout(BuildContext context) async {
    if (workout is! ScheduledWorkout) {
      Navigator.of(context).pop();
      return;
    }

    final bool? completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WorkoutExecutionPage(
          workout: workout as ScheduledWorkout,
          scheduleEntryIndex: 0,
        ),
      ),
    );

    if (completed == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
