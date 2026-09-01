import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rize/base_widgets.dart';
import 'package:rize/firestore.dart';
import 'package:rize/helpers/auth_service.dart';
import 'package:rize/pages/profile_page.dart';
import 'package:rize/pages/workout_details_page.dart';
import 'package:rize/widgets/slot_machine.dart';
import 'package:rize/types/config.dart';
import 'package:rize/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rize/globals.dart' as globals;
import 'package:rize/helpers/home_page_helpers.dart';
import 'package:rize/helpers/workout_library_helpers.dart';
import 'package:rize/helpers/muscle_group_labels.dart';
import 'package:rize/pages/progress_overview_content.dart';
import 'package:rize/pages/workout_library_page.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets/home_page_widgets.dart';
import 'package:rize/widgets/muscle_visualizer.dart';
import 'package:rize/widgets/workout_rounds_list.dart';
import 'package:rize/widgets/pro_upgrade_cta.dart';
import 'package:rize/widgets/anamnesis_questionnaire_flow.dart';
import 'package:rize/widgets/drag_safe_filter_chip.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _loadingUser = true;
  Object? _userLoadError;
  int _dataRevision = 0;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser({bool reloadAppData = false}) async {
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

      if (reloadAppData) {
        final List<Object?> refreshed = await Future.wait<Object?>(
          <Future<Object?>>[loadWorkoutCollection(), loadDailyWorkoutPlan()],
        );
        globals.workoutLibrary = refreshed[0]! as List<Workout>;
        globals.dailyWorkoutPlan = refreshed[1] as DailyWorkoutPlan?;
      }

      userData.intensityLevel = levels.firstWhere(
        (IntensityLevel level) =>
            userData.intensityScore >= level.minScore &&
            userData.intensityScore <= level.maxScore,
        orElse: IntensityLevel.unknown,
      );

      globals.userData = userData;
      globals.intensityLevels = levels;
      if (reloadAppData) _dataRevision++;
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
      //appBar: rizeAppBar,
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

    return HomePageSlotMachineWidget(
      key: ValueKey<int>(_dataRevision),
      onQuestionnaireCompleted: () => _initializeUser(reloadAppData: true),
    );
  }
}

class HomePageSlotMachineWidget extends StatefulWidget {
  const HomePageSlotMachineWidget({
    super.key,
    required this.onQuestionnaireCompleted,
  });

  final Future<void> Function() onQuestionnaireCompleted;

  @override
  State<HomePageSlotMachineWidget> createState() =>
      _HomePageSlotMachineWidgetState();
}

class _HomePageSlotMachineWidgetState extends State<HomePageSlotMachineWidget> {
  String get _includedMuscleGroupsKey =>
      'dailyWorkoutIncludedMuscleGroups:${globals.authenticatedUserId}';
  String get _excludedMuscleTagsKey =>
      'dailyWorkoutExcludedMuscleTags:${globals.authenticatedUserId}';

  final SlotMachineController _slotController = SlotMachineController();

  List<ScheduledWorkout> _selectedWorkouts = <ScheduledWorkout>[];
  int _exerciseCount = 1;
  Set<String> _selectedMuscleGroups = <String>{};
  Set<String> _excludedMuscleTags = <String>{};
  bool _showSpinExperience = false;
  bool _isSpinning = false;
  bool _questionnaireChecked = false;
  bool _checkingProNudge = false;

  late Future<List<ScheduledWorkout>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = loadWorkoutHistoryFromServer();
    _restoreMuscleFilters();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openQuestionnaireWhenRequired();
    });
  }

  Future<void> _restoreMuscleFilters() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedMuscleGroups =
          preferences.getStringList(_includedMuscleGroupsKey)?.toSet() ??
          <String>{};
      _excludedMuscleTags =
          preferences.getStringList(_excludedMuscleTagsKey)?.toSet() ??
          <String>{};
    });
  }

  Future<void> _updateMuscleFilters(
    ({Set<String> included, Set<String> excluded}) filters,
  ) async {
    setState(() {
      _selectedMuscleGroups = filters.included;
      _excludedMuscleTags = filters.excluded;
    });
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await Future.wait(<Future<bool>>[
      preferences.setStringList(
        _includedMuscleGroupsKey,
        filters.included.toList(growable: false)..sort(),
      ),
      preferences.setStringList(
        _excludedMuscleTagsKey,
        filters.excluded.toList(growable: false)..sort(),
      ),
    ]);
  }

  Future<void> _openQuestionnaireWhenRequired() async {
    if (_questionnaireChecked || !mounted) return;
    _questionnaireChecked = true;

    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final bool questionnaireSubmitted =
        (preferences.getBool('anamnesisDone') ?? false) ||
        (globals.userData?.intensityScore ?? 0) != 0;

    if (questionnaireSubmitted || !mounted) return;

    final questionnaire = await loadAnamnesisQuestionnaire();
    if (!mounted) return;

    final bool? completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            AnamnesisQuestionnaireFlow(questionnaire: questionnaire),
      ),
    );
    if (completed == true) {
      await widget.onQuestionnaireCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final DailyWorkoutPlan? plan = globals.dailyWorkoutPlan;

    return FutureBuilder<List<ScheduledWorkout>>(
      future: _historyFuture,
      builder:
          (
            BuildContext context,
            AsyncSnapshot<List<ScheduledWorkout>> snapshot,
          ) {
            final int streak = snapshot.hasData
                ? computeCurrentStreakFromHistory(snapshot.data!)
                : 0;

            if (plan == null) {
              return _buildNoWorkoutState(streak);
            }

            if (plan.isCompleted) {
              return _buildCompletedState(plan, streak);
            }

            return _buildActiveWorkoutState(plan, streak);
          },
    );
  }

  Widget _pageShell({
    required List<Widget> children,
    int? streak,
    String? message,
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
                  message: message ?? dailyMotivation(now),
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
          if (_buildProBanner() case final Widget banner) ...<Widget>[
            banner,
            const SizedBox(height: 14),
          ],
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
          exerciseCount: _exerciseCount,
          onExerciseCountChanged: (int value) =>
              setState(() => _exerciseCount = value),
          selectedMuscleGroups: _selectedMuscleGroups,
          excludedMuscleTags: _excludedMuscleTags,
          onMuscleFiltersChanged: _updateMuscleFilters,
          onSpin: _spinWorkout,
          onClose: () {
            setState(() {
              _showSpinExperience = false;
              _selectedWorkouts = <ScheduledWorkout>[];
            });
          },
        ),
        if (_buildProBanner() case final Widget banner) ...<Widget>[
          const SizedBox(height: 14),
          banner,
        ],
        if (_selectedWorkouts.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          ..._selectedWorkouts.indexed.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DailyWorkoutCard(
                workout: entry.$2,
                eyebrow:
                    'ÜBUNG ${entry.$1 + 1} VON ${_selectedWorkouts.length}',
                progress: 0,
                schedule: WorkoutRoundsList(
                  workout: entry.$2,
                  onRoundCompleted: _refreshWorkoutProgress,
                ),
                muscleVisualization: MuscleVisualization(workout: entry.$2),
                onOpenTechnique: () => _openWorkout(entry.$2),
                onReset: entry.$1 == 0
                    ? () async {
                        await deleteDailyWorkoutPlan();
                        if (!mounted) return;
                        setState(() {
                          globals.dailyWorkoutPlan = null;
                          _selectedWorkouts = <ScheduledWorkout>[];
                        });
                      }
                    : null,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActiveWorkoutState(DailyWorkoutPlan plan, int streak) {
    return _pageShell(
      streak: streak,
      children: <Widget>[
        if (plan.workouts.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${plan.workouts.length} Übungen · ${(plan.progress * 100).round()} % geschafft',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ...plan.workouts.indexed.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DailyWorkoutCard(
              workout: entry.$2,
              eyebrow: 'ÜBUNG ${entry.$1 + 1} VON ${plan.workouts.length}',
              progress: dailyWorkoutProgress(entry.$2),
              schedule: WorkoutRoundsList(
                workout: entry.$2,
                onRoundCompleted: _refreshWorkoutProgress,
              ),
              muscleVisualization: MuscleVisualization(workout: entry.$2),
              onOpenTechnique: () => _openWorkout(entry.$2),
              onReset: entry.$1 == 0 && plan.workouts.every(canResetDailyPlan)
                  ? () async {
                      await deleteDailyWorkoutPlan();
                      if (!mounted) return;
                      setState(() {
                        globals.dailyWorkoutPlan = null;
                        _selectedWorkouts = <ScheduledWorkout>[];
                        _showSpinExperience = false;
                      });
                    }
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_buildProBanner() case final Widget banner) ...<Widget>[
          banner,
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget? _buildProBanner() {
    if (globals.userData?.isPro == true) return null;
    final int availableCount = availableWorkoutsForUser(
      workouts: globals.workoutLibrary,
      intensityScore: globals.userData?.intensityScore ?? 0,
      isPro: false,
    ).length;
    return ProUpgradeBanner(
      availableCount: availableCount,
      onTap: () => showProUpgradeSheet(context, source: 'home_banner'),
    );
  }

  Widget _buildCompletedState(DailyWorkoutPlan plan, int streak) {
    final Duration remaining = timeUntilTomorrow(DateTime.now());

    return _pageShell(
      streak: streak,
      message:
          'Workout geschafft. Stark – jetzt darfst Du den Erfolg wirken lassen.',
      children: <Widget>[
        CompletedWorkoutHero(
          workout: plan.workouts.first,
          streak: streak,
          nextWorkoutIn: compactDuration(remaining),
        ),
      ],
    );
  }

  Future<void> _spinWorkout() async {
    if (_isSpinning) return;

    final IntensityLevel level =
        globals.userData?.intensityLevel ?? IntensityLevel.unknown();

    final bool isPro = globals.userData?.isPro == true;
    final int requestedCount = isPro ? _exerciseCount.clamp(1, 5) : 1;
    final List<Workout> entitledWorkouts = availableWorkoutsForUser(
      workouts: globals.workoutLibrary,
      intensityScore: globals.userData?.intensityScore ?? 0,
      isPro: isPro,
    );
    final List<Workout> workouts = workoutsForUserIntensity(
      workouts: entitledWorkouts,
      intensityScore: globals.userData?.intensityScore,
      tolerance: globals.intensityScoreTolerance,
    );

    final List<int> intensities = buildIntensityFactors(level);
    final List<List<WorkoutStep>> schedules = buildScheduleOptions(level);

    if (workouts.isEmpty || intensities.isEmpty || schedules.isEmpty) {
      return;
    }

    final List<Workout> eligibleWorkouts = isPro
        ? workouts
              .where(
                (Workout workout) => workoutMatchesMuscleFilters(
                  workout,
                  includedMuscleGroups: _selectedMuscleGroups,
                  excludedTags: _excludedMuscleTags,
                ),
              )
              .toList(growable: false)
        : workouts;
    final Random random = Random();
    final List<Workout> randomSelection = selectWorkoutsForSpin(
      workouts: eligibleWorkouts,
      count: requestedCount,
      random: random,
      muscleFilter: isPro ? _selectedMuscleGroups : const <String>{},
      excludedTags: isPro ? _excludedMuscleTags : const <String>{},
    );

    if (randomSelection.length < requestedCount) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Für diese Filter sind nur ${randomSelection.length} unterschiedliche Übungen verfügbar. Passe Muskelgruppen, Ausschlüsse oder die Übungsanzahl an.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isSpinning = true);

    try {
      final int scheduleIndex = random.nextInt(schedules.length);
      final int intensityIndex = random.nextInt(intensities.length);
      final String planId = DateTime.now().microsecondsSinceEpoch.toString();
      final List<ScheduledWorkout> spunWorkouts =
          List<ScheduledWorkout>.generate(requestedCount, (int index) {
            final ScheduledWorkout item = ScheduledWorkout.fromBaseWorkout(
              randomSelection[index],
              schedules[index == 0
                  ? scheduleIndex
                  : random.nextInt(schedules.length)],
              intensities[index == 0
                  ? intensityIndex
                  : random.nextInt(intensities.length)],
            );
            item.planId = planId;
            item.planPosition = index;
            return level.applyToWorkout(item);
          });
      final ScheduledWorkout workout = spunWorkouts.first;

      final List<String> names = eligibleWorkouts
          .map((Workout item) => item.name)
          .toSet()
          .toList(growable: false);

      await _slotController.spinTo(<int>[
        names.indexOf(workout.name),
        intensityIndex,
        scheduleIndex,
      ]);

      await Future.wait(
        spunWorkouts.map((item) => item.saveAsDailyWorkoutPlan()),
      );

      if (!mounted) return;

      setState(() {
        _selectedWorkouts = spunWorkouts;
        globals.dailyWorkoutPlan = DailyWorkoutPlan(
          id: planId,
          workouts: spunWorkouts,
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSpinning = false);
      }
    }
  }

  Future<void> _openWorkout(ScheduledWorkout workout) async {
    final bool? completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WorkoutDetailsPage(workout: workout),
      ),
    );

    if (completed == true && mounted) {
      _refreshWorkoutProgress();
    }
  }

  Future<void> _refreshWorkoutProgress() async {
    if (!mounted) return;
    final Future<List<ScheduledWorkout>> historyFuture =
        loadWorkoutHistoryFromServer();
    setState(() {
      _historyFuture = historyFuture;
    });

    final List<ScheduledWorkout> history = await historyFuture;
    await _showProNudgeWhenEligible(history);
  }

  Future<void> _showProNudgeWhenEligible(List<ScheduledWorkout> history) async {
    if (_checkingProNudge || globals.userData?.isPro == true || !mounted) {
      return;
    }
    _checkingProNudge = true;
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final String preferenceKey =
          'freeProNudgeAfterFive:${globals.authenticatedUserId}';
      final bool wasAlreadyShown = preferences.getBool(preferenceKey) ?? false;
      final int completedWorkoutCount = history
          .where((ScheduledWorkout workout) => workout.isCompleted)
          .length;
      if (!shouldShowFreeProNudge(
        isPro: globals.userData?.isPro == true,
        completedWorkoutCount: completedWorkoutCount,
        wasAlreadyShown: wasAlreadyShown,
      )) {
        return;
      }

      await preferences.setBool(preferenceKey, true);
      if (!mounted) return;
      await showProUpgradeSheet(context, source: 'five_completed_workouts');
    } finally {
      _checkingProNudge = false;
    }
  }
}

class _DailySpinPanel extends StatelessWidget {
  const _DailySpinPanel({
    required this.controller,
    required this.isSpinning,
    required this.onSpin,
    required this.onClose,
    required this.exerciseCount,
    required this.onExerciseCountChanged,
    required this.selectedMuscleGroups,
    required this.excludedMuscleTags,
    required this.onMuscleFiltersChanged,
  });

  final SlotMachineController controller;
  final bool isSpinning;
  final Future<void> Function() onSpin;
  final VoidCallback onClose;
  final int exerciseCount;
  final ValueChanged<int> onExerciseCountChanged;
  final Set<String> selectedMuscleGroups;
  final Set<String> excludedMuscleTags;
  final ValueChanged<({Set<String> included, Set<String> excluded})>
  onMuscleFiltersChanged;

  @override
  Widget build(BuildContext context) {
    final IntensityLevel level =
        globals.userData?.intensityLevel ?? IntensityLevel.unknown();

    final bool isPro = globals.userData?.isPro == true;
    final List<Workout> entitledWorkouts = availableWorkoutsForUser(
      workouts: globals.workoutLibrary,
      intensityScore: globals.userData?.intensityScore ?? 0,
      isPro: isPro,
    );
    final List<Workout> workouts = workoutsForUserIntensity(
      workouts: entitledWorkouts,
      intensityScore: globals.userData?.intensityScore,
      tolerance: globals.intensityScoreTolerance,
    );

    final List<Workout> visibleSpinPool = isPro
        ? workouts
              .where(
                (Workout workout) => workoutMatchesMuscleFilters(
                  workout,
                  includedMuscleGroups: selectedMuscleGroups,
                  excludedTags: excludedMuscleTags,
                ),
              )
              .toList(growable: false)
        : workouts;

    final List<String> workoutNames = visibleSpinPool
        .map((Workout workout) => workout.name)
        .toSet()
        .toList(growable: false);

    final List<int> intensities = buildIntensityFactors(level);
    final List<List<WorkoutStep>> schedules = buildScheduleOptions(level);

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
                  'Deine Tagesaufgabe',
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
            'Bereit für Deine Tagesaufgabe? Wir kombinieren Übung, Intensität und Umfang passend zu Deinem Level.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.58),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          if (isPro) ...<Widget>[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Wie viel traust Du Dir heute zu?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List<Widget>.generate(5, (int index) {
                final int value = index + 1;
                final bool selected = exerciseCount == value;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 4 ? 0 : 7),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isSpinning
                            ? null
                            : () => onExerciseCountChanged(value),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF79D5FF)
                                : Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF79D5FF)
                                  : Colors.white.withOpacity(0.09),
                            ),
                          ),
                          child: Text(
                            '$value',
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFF0B417B)
                                  : Colors.white70,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 9),
            Text(
              _challengeLabel(exerciseCount),
              style: const TextStyle(
                color: Color(0xFF9DDEF9),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _MuscleFocusButton(
              selectedGroups: selectedMuscleGroups,
              excludedTags: excludedMuscleTags,
              onTap: isSpinning
                  ? null
                  : () => _selectMuscleFilters(context, workouts),
            ),
          ] else ...<Widget>[
            ProFeatureLock(
              title: 'Mehrere Übungen & Muskelfokus',
              description:
                  'Mit Pro bestimmst Du Tagesumfang und Muskelgruppen. Deine kostenlose Tagesaufgabe enthält eine passende Übung.',
              onTap: () =>
                  showProUpgradeSheet(context, source: 'spin_pro_features'),
            ),
          ],
          const SizedBox(height: 12),
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

  String _challengeLabel(int count) => switch (count) {
    1 => '1 Übung · Ein starker Impuls',
    2 => '2 Übungen · Heute geht etwas mehr',
    3 => '3 Übungen · Eine solide Session',
    4 => '4 Übungen · Du willst es wissen',
    _ => '5 Übungen · Volle Energie',
  };

  Future<void> _selectMuscleFilters(
    BuildContext context,
    List<Workout> workouts,
  ) async {
    final List<String> groups =
        workouts
            .expand((Workout workout) => workout.usedMuscleGroups)
            .toSet()
            .toList()
          ..sort(
            (String a, String b) =>
                muscleGroupLabel(a).compareTo(muscleGroupLabel(b)),
          );
    final List<String> tags =
        workouts
            .expand((Workout workout) => workout.tags)
            .map((String tag) => tag.trim())
            .where((String tag) => tag.isNotEmpty)
            .toSet()
            .toList()
          ..sort(
            (String a, String b) =>
                muscleGroupLabel(a).compareTo(muscleGroupLabel(b)),
          );
    // Keep the draft outside the route builder. The modal route can rebuild
    // while it is dragged; recreating these sets there would restore the
    // persisted filters and discard every change made since opening the sheet.
    Set<String> includedDraft = Set<String>.of(selectedMuscleGroups);
    Set<String> excludedDraft = Set<String>.of(excludedMuscleTags);
    final ({Set<String> included, Set<String> excluded})? result =
        await showModalBottomSheet<
          ({Set<String> included, Set<String> excluded})
        >(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                final int matchingCount = workouts
                    .where(
                      (Workout workout) => workoutMatchesMuscleFilters(
                        workout,
                        includedMuscleGroups: includedDraft,
                        excludedTags: excludedDraft,
                      ),
                    )
                    .length;
                return SafeArea(
                  top: false,
                  bottom: false,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      20 + MediaQuery.paddingOf(context).bottom,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF102F55),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
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
                          'Worauf hast Du heute Lust?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Wähle einen oder mehrere Bereiche. Bei mehreren Übungen sorgt RIZE automatisch für Abwechslung.',
                          style: TextStyle(
                            color: Colors.white60,
                            height: 1.4,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'MUSKELGRUPPEN EINSCHLIESSEN',
                                  style: TextStyle(
                                    color: Color(0xFF9DDEF9),
                                    fontSize: 10,
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: <Widget>[
                                    DragSafeFilterChip(
                                      key: const ValueKey<String>(
                                        'include-all-muscles',
                                      ),
                                      label: const Text('Alles offen'),
                                      avatar: const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 17,
                                      ),
                                      selected: includedDraft.isEmpty,
                                      onSelected: (_) {
                                        setModalState(
                                          () => includedDraft = <String>{},
                                        );
                                      },
                                    ),
                                    ...groups.map(
                                      (String group) => DragSafeFilterChip(
                                        key: ValueKey<String>('include-$group'),
                                        label: Text(muscleGroupLabel(group)),
                                        selected: includedDraft.contains(group),
                                        onSelected: (bool selected) {
                                          setModalState(() {
                                            includedDraft = Set<String>.of(
                                              includedDraft,
                                            );
                                            selected
                                                ? includedDraft.add(group)
                                                : includedDraft.remove(group);
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                if (tags.isNotEmpty) ...<Widget>[
                                  const SizedBox(height: 18),
                                  const Text(
                                    'BEREICHE AUSSCHLIESSEN',
                                    style: TextStyle(
                                      color: Color(0xFFFF9AA3),
                                      fontSize: 10,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      DragSafeFilterChip(
                                        key: const ValueKey<String>(
                                          'exclude-no-tags',
                                        ),
                                        label: const Text(
                                          'Nichts ausschließen',
                                        ),
                                        avatar: const Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 17,
                                        ),
                                        selected: excludedDraft.isEmpty,
                                        selectedColor: const Color(
                                          0xFFFF6B78,
                                        ).withOpacity(0.28),
                                        onSelected: (_) {
                                          setModalState(
                                            () => excludedDraft = <String>{},
                                          );
                                        },
                                      ),
                                      ...tags.map(
                                        (String tag) => DragSafeFilterChip(
                                          key: ValueKey<String>('exclude-$tag'),
                                          label: Text(muscleGroupLabel(tag)),
                                          selected: excludedDraft.contains(tag),
                                          selectedColor: const Color(
                                            0xFFFF6B78,
                                          ).withOpacity(0.28),
                                          checkmarkColor: const Color(
                                            0xFFFFB3BA,
                                          ),
                                          side: BorderSide(
                                            color: excludedDraft.contains(tag)
                                                ? const Color(0xFFFF7E89)
                                                : Colors.white24,
                                          ),
                                          onSelected: (bool selected) {
                                            setModalState(() {
                                              excludedDraft = Set<String>.of(
                                                excludedDraft,
                                              );
                                              selected
                                                  ? excludedDraft.add(tag)
                                                  : excludedDraft.remove(tag);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: matchingCount == 0
                              ? null
                              : () => Navigator.pop(context, (
                                  included: includedDraft,
                                  excluded: excludedDraft,
                                )),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF125EB4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            includedDraft.isEmpty && excludedDraft.isEmpty
                                ? 'ALLE MUSKELGRUPPEN · $matchingCount ÜBUNGEN'
                                : 'FILTER ÜBERNEHMEN · $matchingCount ÜBUNGEN',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
    if (result != null) onMuscleFiltersChanged(result);
  }
}

class _MuscleFocusButton extends StatelessWidget {
  const _MuscleFocusButton({
    required this.selectedGroups,
    required this.excludedTags,
    this.onTap,
  });

  final Set<String> selectedGroups;
  final Set<String> excludedTags;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String label = selectedGroups.isEmpty
        ? 'Alle Muskelgruppen'
        : selectedGroups.map(muscleGroupLabel).join(' · ');
    final String excludedLabel = excludedTags.isEmpty
        ? 'Nichts ausgeschlossen'
        : excludedTags.map(muscleGroupLabel).join(' · ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.065),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.accessibility_new_rounded,
                color: Color(0xFF79D5FF),
                size: 21,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'MUSKELFOKUS · PRO',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                        letterSpacing: 0.9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'AUSSCHLUSS · $excludedLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: excludedTags.isEmpty
                            ? Colors.white38
                            : const Color(0xFFFF9AA3),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.tune_rounded, color: Colors.white54, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
