
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rize/base_widgets.dart';
import 'package:rize/firestore.dart';
import 'package:rize/helpers/auth_service.dart';
import 'package:rize/main.dart' show ProfilePage;
import 'package:rize/pages/workout_details_page.dart';
import 'package:rize/widgets/slot_machine.dart';
import 'package:rize/types/config.dart';
import 'package:rize/utils.dart';
import 'package:rize/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rize/globals.dart' as globals;
import 'package:rize/helpers/home_page_helpers.dart';
import 'package:rize/pages/progress_overview_content.dart';
import 'package:rize/pages/workout_library_page.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets/home_page_widgets.dart';
import 'package:rize/widgets/muscle_visualizer.dart';

// Keep/import these from their existing project locations:
// - authServiceNotifier
// - loadUserData
// - loadIntensityLevels
// - loadWorkoutHistoryFromServer
// - computeCurrentStreakFromHistory
// - loadAnamnesisQuestionnaire
// - AnamnesisQuestionnaireWidget
// - deleteDailyWorkoutPlan
// - SlotMachine / SlotMachineController
// - WorkoutDetailsPage
// - WorkoutScheduleWidget
// - ProfilePage
// - RizeScaffold / rizeAppBar
//
// The imports depend on where those existing declarations currently live in
// your project. Move the imports from the old home-page file to this file.

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _loadingUser = true;
  Object? _userLoadError;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    if (mounted) {
      setState(() {
        _loadingUser = true;
        _userLoadError = null;
      });
    }

    try {
      final user = authServiceNotifier.value.currentUser;
      if (user == null) {
        throw StateError('Es ist kein Benutzer angemeldet.');
      }

      final userData = await loadUserData(user.uid);
      final List<IntensityLevel> levels = await loadIntensityLevels();

      userData.intensityLevel = levels.firstWhere(
        (IntensityLevel level) =>
            userData.intensityScore >= level.minScore &&
            userData.intensityScore <= level.maxScore,
        orElse: IntensityLevel.unknown,
      );

      globals.userData = userData;
    } catch (error) {
      _userLoadError = error;
    } finally {
      if (mounted) {
        setState(() => _loadingUser = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RizeScaffold(
      appBar: rizeAppBar,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Theme.of(context).primaryColorDark,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        currentIndex: globals.navBarIndex,
        onTap: (int value) {
          setState(() => globals.navBarIndex = value);
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_rounded),
            label: 'Fortschritt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmarks_rounded),
            label: 'Bibliothek',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
      body: switch (globals.navBarIndex) {
        0 => _buildHomeContent(),
        1 => ProgressOverviewContent(userId: globals.authenticatedUserId!),
        2 => const WorkoutLibraryPage(),
        3 => ProfilePage(),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildHomeContent() {
    if (_loadingUser) {
      return const HomeLoadingView();
    }

    if (_userLoadError != null) {
      return HomeErrorView(
        message: 'Deine Trainingsdaten konnten nicht geladen werden.',
        onRetry: _initializeUser,
      );
    }

    return const HomePageSlotMachineWidget();
  }
}

class HomePageSlotMachineWidget extends StatefulWidget {
  const HomePageSlotMachineWidget({super.key});

  @override
  State<HomePageSlotMachineWidget> createState() =>
      _HomePageSlotMachineWidgetState();
}

class _HomePageSlotMachineWidgetState
    extends State<HomePageSlotMachineWidget> {
  final SlotMachineController _slotController = SlotMachineController();

  ScheduledWorkout? _selectedWorkout;
  bool _showSpinExperience = false;
  bool _isSpinning = false;
  bool _questionnaireChecked = false;

  late Future<List<ScheduledWorkout>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = loadWorkoutHistoryFromServer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openQuestionnaireWhenRequired();
    });
  }

  Future<void> _openQuestionnaireWhenRequired() async {
    if (_questionnaireChecked || !mounted) return;
    _questionnaireChecked = true;

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    final bool questionnaireSubmitted =
        (preferences.getBool('anamnesisDone') ?? false) ||
            (globals.userData?.intensityScore ?? 0) != 0;

    if (questionnaireSubmitted || !mounted) return;

    final questionnaire = await loadAnamnesisQuestionnaire();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnamnesisQuestionnaireWidget(
          questionnaire: questionnaire,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ScheduledWorkout? plan = globals.dailyWorkoutPlan;

    return FutureBuilder<List<ScheduledWorkout>>(
      future: _historyFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<ScheduledWorkout>> snapshot,
      ) {
        final int streak = snapshot.hasData
            ? computeCurrentStreakFromHistory(snapshot.data!)
            : 0;

        if (plan == null) {
          return _buildNoWorkoutState(streak);
        }

        if (!isDailyPlanActionable(plan)) {
          return _buildCompletedState(plan, streak);
        }

        return _buildActiveWorkoutState(plan, streak);
      },
    );
  }

  Widget _pageShell({
    required List<Widget> children,
    int? streak,
  }) {
    final DateTime now = DateTime.now();

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CoachFloHomeHeader(
                  greeting: homeGreeting(
                    authServiceNotifier.value.currentUser?.displayName,
                    now,
                  ),
                  message: dailyMotivation(now),
                  streak: streak,
                ),
                const SizedBox(height: 18),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoWorkoutState(int streak) {
    if (!_showSpinExperience) {
      return _pageShell(
        streak: streak,
        children: <Widget>[
          const CoachFloManifestoCard(),
          const SizedBox(height: 14),
          DailySpinHero(
            onStart: () {
              setState(() => _showSpinExperience = true);
            },
          ),
          const SizedBox(height: 14),
          const HomePrinciplesRow(),
        ],
      );
    }

    return _pageShell(
      streak: streak,
      children: <Widget>[
        _DailySpinPanel(
          controller: _slotController,
          isSpinning: _isSpinning,
          onSpin: _spinWorkout,
          onClose: () {
            setState(() {
              _showSpinExperience = false;
              _selectedWorkout = null;
            });
          },
        ),
        if (_selectedWorkout != null) ...<Widget>[
          const SizedBox(height: 14),
          DailyWorkoutCard(
            workout: _selectedWorkout!,
            progress: 0,
            schedule: WorkoutScheduleWidget(workout: _selectedWorkout!),
            muscleVisualization:
                MuscleVisualization(workout: _selectedWorkout!),
            onOpenTechnique: () => _openWorkout(_selectedWorkout!),
            onReset: () async {
              await deleteDailyWorkoutPlan();
              if (!mounted) return;
              setState(() {
                globals.dailyWorkoutPlan = null;
                _selectedWorkout = null;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildActiveWorkoutState(
    ScheduledWorkout workout,
    int streak,
  ) {
    return _pageShell(
      streak: streak,
      children: <Widget>[
        DailyWorkoutCard(
          workout: workout,
          progress: dailyWorkoutProgress(workout),
          schedule: WorkoutScheduleWidget(workout: workout),
          muscleVisualization: MuscleVisualization(workout: workout),
          onOpenTechnique: () => _openWorkout(workout),
          onReset: canResetDailyPlan(workout)
              ? () async {
                  await deleteDailyWorkoutPlan();
                  if (!mounted) return;
                  setState(() {
                    globals.dailyWorkoutPlan = null;
                    _selectedWorkout = null;
                    _showSpinExperience = false;
                  });
                }
              : null,
        ),
        const SizedBox(height: 14),
        const CoachFloManifestoCard(),
      ],
    );
  }

  Widget _buildCompletedState(
    ScheduledWorkout workout,
    int streak,
  ) {
    final Duration remaining = timeUntilTomorrow(DateTime.now());

    return _pageShell(
      streak: streak,
      children: <Widget>[
        CompletedWorkoutHero(
          workout: workout,
          streak: streak,
          nextWorkoutIn: compactDuration(remaining),
        ),
        const SizedBox(height: 14),
        const CoachFloManifestoCard(),
      ],
    );
  }

  Future<void> _spinWorkout() async {
    if (_isSpinning) return;

    final IntensityLevel level =
        globals.userData?.intensityLevel ?? IntensityLevel.unknown();

    final List<Workout> workouts = workoutsForUserIntensity(
      workouts: globals.workoutLibrary,
      intensityScore: globals.userData?.intensityScore,
      tolerance: globals.intensityScoreTolerance,
    );

    final List<int> intensities = buildIntensityFactors(level);
    final List<List<WorkoutStep>> schedules = buildScheduleOptions(level);

    if (workouts.isEmpty || intensities.isEmpty || schedules.isEmpty) {
      return;
    }

    setState(() => _isSpinning = true);

    try {
      final Random random = Random();
      final int scheduleIndex = random.nextInt(schedules.length);
      final int intensityIndex = random.nextInt(intensities.length);
      final Workout baseWorkout = workouts[random.nextInt(workouts.length)];

      ScheduledWorkout workout = ScheduledWorkout.fromBaseWorkout(
        baseWorkout,
        schedules[scheduleIndex],
        intensities[intensityIndex],
      );

      final List<String> names = workouts
          .map((Workout item) => item.name)
          .toSet()
          .toList(growable: false);

      await _slotController.spinTo(<int>[
        names.indexOf(workout.name),
        intensityIndex,
        scheduleIndex,
      ]);

      workout = level.applyToWorkout(workout);
      await workout.saveAsDailyWorkoutPlan();

      if (!mounted) return;

      setState(() {
        _selectedWorkout = workout;
        globals.dailyWorkoutPlan = workout;
      });
    } finally {
      if (mounted) {
        setState(() => _isSpinning = false);
      }
    }
  }

  void _openWorkout(ScheduledWorkout workout) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutDetailsPage(workout: workout),
      ),
    );
  }
}

class _DailySpinPanel extends StatelessWidget {
  const _DailySpinPanel({
    required this.controller,
    required this.isSpinning,
    required this.onSpin,
    required this.onClose,
  });

  final SlotMachineController controller;
  final bool isSpinning;
  final Future<void> Function() onSpin;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final IntensityLevel level =
        globals.userData?.intensityLevel ?? IntensityLevel.unknown();

    final List<Workout> workouts = workoutsForUserIntensity(
      workouts: globals.workoutLibrary,
      intensityScore: globals.userData?.intensityScore,
      tolerance: globals.intensityScoreTolerance,
    );

    final List<String> workoutNames = workouts
        .map((Workout workout) => workout.name)
        .toSet()
        .toList(growable: false);

    final List<int> intensities = buildIntensityFactors(level);
    final List<List<WorkoutStep>> schedules =
        buildScheduleOptions(level);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.white.withOpacity(0.09),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Dein Daily Spin',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              IconButton(
                onPressed: isSpinning ? null : onClose,
                icon: const Icon(Icons.close_rounded),
                color: Colors.white70,
              ),
            ],
          ),
          Text(
            'Wir kombinieren Übung, Intensität und Umfang passend zu Deinem Level.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.58),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SlotMachine(
            height: 238,
            itemExtent: 62,
            staggerMs: 190,
            controller: controller,
            showLever: false,
            enableHaptics: true,
            compact: MediaQuery.sizeOf(context).width < 390,
            symbolsPerReel: <List<Widget>>[
              workoutNames
                  .map((String name) => Text(name))
                  .toList(growable: false),
              intensities
                  .map((int value) => Text('$value'))
                  .toList(growable: false),
              schedules
                  .map(
                    (List<WorkoutStep> schedule) =>
                        Text(workoutScheduleToString(schedule)),
                  )
                  .toList(growable: false),
            ],
            reelTitles: const <Widget>[
              Text('Übung'),
              Text('Intensität'),
              Text('Umfang'),
            ],
            onResult: (List<int> result) {},
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isSpinning ? null : onSpin,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF125EB4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            icon: isSpinning
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Icon(Icons.cyclone_rounded),
            label: Text(
              isSpinning ? 'DEIN WORKOUT ENTSTEHT …' : 'JETZT DREHEN',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
