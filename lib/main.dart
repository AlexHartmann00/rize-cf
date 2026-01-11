import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rize/auth_service.dart';
import 'package:rize/base_widgets.dart';
import 'package:rize/firebase_options.dart';
import 'package:rize/firestore.dart';
import 'package:rize/globals.dart' as globals;
import 'package:rize/slot_machine.dart' show SlotMachine, SlotMachineController;
import 'package:rize/types/anamnesis.dart';
import 'package:rize/types/config.dart' show IntensityLevel;
import 'package:rize/types/user.dart' show UserData;
import 'package:rize/types/workout.dart';
import 'package:rize/utils.dart'
    show timeOfDayIsCurrent, timeOfDayIsPast, workoutScheduleToString, computeCurrentStreakFromHistory;
import 'package:rize/widgets.dart';
import 'package:rize/workout_library.dart';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'dart:convert';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rize/globals.dart' as data;
import 'package:shared_preferences/shared_preferences.dart';

//TODO: Daily workout in shared preferences
// Creation day; workout id; schedule & schedule progress; intensity
// On app start, if saved workout day was before today, clear saved workout

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  authServiceNotifier.value.authStateChanges.listen((user) {
    if (user != null) {
      loadUserData(user.uid).then((userData) {
        globals.userData = userData;
        print('User logged in: ${user.uid}');
        globals.authenticatedUserId = user.uid;
        loadIntensityLevels().then((value) {
          globals.intensityLevels = value;
          print(
            'levels debug: ${value.length}; user score: ${globals.userData!.intensityScore}; levels: ${value.map((e) => '${e.label} ${e.minScore}-${e.maxScore}').toList()}',
          );
          print(
            'Levels debug: ${value.firstWhere((level) => globals.userData!.intensityScore >= level.minScore && globals.userData!.intensityScore <= level.maxScore).label}',
          );
          globals.userData!.intensityLevel = value.firstWhere(
            (level) =>
                globals.userData!.intensityScore >= level.minScore &&
                globals.userData!.intensityScore <= level.maxScore,
          );
        });
      });
    } else {
      print('User logged out');
      globals.authenticatedUserId = null;
    }
  });
  print('Current user: ${authServiceNotifier.value.currentUser}');
  if (authServiceNotifier.value.currentUser != null) {
    UserData userData = await loadUserData(
      authServiceNotifier.value.currentUser!.uid,
    );
    List<IntensityLevel> levels = await loadIntensityLevels();
    userData.intensityLevel = levels.firstWhere(
      (level) =>
          userData.intensityScore >= level.minScore &&
          userData.intensityScore <= level.maxScore,
    );

    globals.userData = userData;
  }

  //TODO: remove this; only for testing
  //await authServiceNotifier.value.signOut();
  data.workoutLibrary = await loadWorkoutCollection();

  globals.dailyWorkoutPlan = await loadDailyWorkoutPlan();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIZE',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 6, 98, 172),
        ),
      ),
      home: authServiceNotifier.value.currentUser == null
          ? const WelcomePage()
          : const MyHomePage(title: 'RIZE'),
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool showLoginOptions = false;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController displayNameController = TextEditingController();
  bool showLogin = false;
  bool showRegister = false;
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return RizeScaffold(
      appBar: null,
      bottomNavigationBar: null,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'RIZE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 70,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                'Built by Daily Action',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (!showLoginOptions)
                IconButton(
                  onPressed: () {
                    setState(() {
                      showLoginOptions = true;
                    });
                  },
                  icon: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Loslegen!',
                        style: TextStyle(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              if (showLoginOptions & !showLogin & !showRegister)
                Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          showRegister = true;
                        });
                      },
                      icon: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Registrieren',
                            style: TextStyle(
                              color: Theme.of(context).primaryColorDark,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          showLogin = true;
                        });
                      },
                      icon: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Einloggen',
                            style: TextStyle(
                              color: Theme.of(context).primaryColorDark,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (showLogin || showRegister)
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.8,
                  child: Column(
                    children: [
                      if (showRegister)
                        TextFormField(
                          controller: displayNameController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Benutzername',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'E-Mail',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Passwort',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      IconButton(
                        onPressed: () async {
                          setState(() {
                            isLoading = true;
                          });
                          UserCredential? userCredential;
                          if (showLogin) {
                            userCredential = await authServiceNotifier.value
                                .signInWithEmailAndPassword(
                                  emailController.text,
                                  passwordController.text,
                                );
                          } else {
                            userCredential = await authServiceNotifier.value
                                .registerWithEmailAndPassword(
                                  emailController.text,
                                  passwordController.text,
                                  displayNameController.text,
                                );
                          }

                          if (userCredential != null) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MyHomePage(title: 'RIZE'),
                              ),
                            );
                          } else {
                            //Show error
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Fehler beim Einloggen. Bitte überprüfe deine Eingaben.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.transparent),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: isLoading
                                ? CircularProgressIndicator()
                                : Text(
                                    showLogin ? 'Einloggen' : 'Registrieren',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColorDark,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //init state
  @override
  void initState() {
    loadUserData(authServiceNotifier.value.currentUser!.uid).then((
      userData,
    ) async {
      List<IntensityLevel> levels = await loadIntensityLevels();
      userData.intensityLevel = levels.firstWhere(
        (level) =>
            userData.intensityScore >= level.minScore &&
            userData.intensityScore <= level.maxScore,
      );
      globals.userData = userData;
    });
    super.initState();
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
        onTap: (value) {
          setState(() {
            globals.navBarIndex = value;
          });
        },
        currentIndex: globals.navBarIndex,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Fortschritt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmarks),
            label: 'Bibliothek',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
      body: switch (globals.navBarIndex) {
        0 => const HomePageSlotMachineWidget(),
        1 => ProgressOverviewContent(userId: globals.authenticatedUserId!),
        2 => const WorkoutLibraryPage(),
        3 => ProfilePage(),
        _ => const Center(child: Text('Unknown')),
      },
    );
  }
}

class HomePageSlotMachineWidget extends StatefulWidget {
  const HomePageSlotMachineWidget({super.key});

  @override
  State<HomePageSlotMachineWidget> createState() =>
      _HomePageSlotMachineWidgetState();
}

class _HomePageSlotMachineWidgetState extends State<HomePageSlotMachineWidget> {
  final controller = SlotMachineController();

  List<int> lastResult = [];
  ScheduledWorkout? selectedWorkout;

  bool showSlotMachine = false;

  TextStyle baseTextStyle = const TextStyle(fontSize: 22, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    //TODO: Check that user data is always loaded. Currently, if it is not loaded, it will be disregarded
    List<Workout> intensityFilteredWorkouts = globals.userData != null
        ? globals.workoutLibrary
              .where(
                (workout) =>
                    workout.impactScore >
                        globals.userData!.intensityScore -
                            globals.intensityScoreTolerance &&
                    workout.impactScore <
                        globals.userData!.intensityScore +
                            globals.intensityScoreTolerance,
              )
              .toList()
        : globals.workoutLibrary;
    List<String> workoutTypeNames = intensityFilteredWorkouts
        .map((e) => e.name)
        .toSet()
        .toList();
    List<int> intensities = [];
    IntensityLevel userLevel =
        globals.userData?.intensityLevel ?? IntensityLevel.unknown();
    for (int i = userLevel.minFactor; i <= userLevel.maxFactor; i++) {
      intensities.add(i);
    }

    List<List<WorkoutStep>> schedules = [];

    for(int i = 1; i <= userLevel.setsPerDayMax; i++) {
      TimeOfDay timeOfDay = TimeOfDay.any;
      schedules.add(List.generate(
        i,
        (index) => WorkoutStep.fromTuple((timeOfDay, 1, 0)),
      ));

    }
    
    // [
    //   if (!timeOfDayIsPast(TimeOfDay.morning))
    //     [
    //       WorkoutStep.fromTuple((TimeOfDay.morning, 1, 0)),
    //       WorkoutStep.fromTuple((TimeOfDay.evening, 1, 0)),
    //     ],
    //   [
    //     WorkoutStep.fromTuple((TimeOfDay.any, 1, 0)),
    //     WorkoutStep.fromTuple((TimeOfDay.any, 1, 0)),
    //     WorkoutStep.fromTuple((TimeOfDay.any, 1, 0)),
    //   ],
    //   [
    //     WorkoutStep.fromTuple((TimeOfDay.any, 1, 0)),
    //     WorkoutStep.fromTuple((TimeOfDay.any, 1, 0)),
    //   ],
    //   if (!timeOfDayIsPast(TimeOfDay.morning))
    //     [WorkoutStep.fromTuple((TimeOfDay.morning, 1, 0))],
    //   [WorkoutStep.fromTuple((TimeOfDay.any, 1, 0))],
    // ];

    SharedPreferences.getInstance().then((prefs) async {
      bool questionnaireSubmitted =
          (prefs.getBool('anamnesisDone') ?? false) ||
          globals.userData?.intensityScore != 0.0;
      if (!questionnaireSubmitted) {
        AnamnesisQuestionnaire questionnaire =
            await loadAnamnesisQuestionnaire();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                AnamnesisQuestionnaireWidget(questionnaire: questionnaire),
          ),
        );
      }
    });

    Widget scheduleEntryWidget((TimeOfDay, int, int) entry) {
      String timeText;
      switch (entry.$1) {
        case TimeOfDay.any:
          timeText = 'Irgendwann am Tag';
        case TimeOfDay.morning:
          timeText = 'Morgens';
        case TimeOfDay.evening:
          timeText = 'Abends';
        default:
          timeText = 'Unbekannt';
      }

      int scheduledUnits = entry.$2;
      int completedUnits = entry.$3;

      bool allDone = completedUnits >= scheduledUnits;

      return Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(100),
          border: Border.all(),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(timeText),
            SizedBox(width: 10),
            Text('× ${scheduledUnits}'),
            SizedBox(width: 10),
            Icon(
              allDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: allDone ? Colors.green : Colors.grey,
            ),
          ],
        ),
      );
    }

    Widget dailyWorkoutChosenWidget = globals.dailyWorkoutPlan != null
        ? Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: AlignmentGeometry.topLeft,
                  child: Text(
                    'Hey, ${authServiceNotifier.value.currentUser?.displayName ?? 'Sportler'}!',
                    textAlign: TextAlign.left,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium!.copyWith(color: Colors.white),
                  ),
                ),
              ),
              Text(
                'Dein heutiges Workout:',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium!.copyWith(color: Colors.white),
              ),
              SizedBox(height: 10),
              Text(
                globals.dailyWorkoutPlan!.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorkoutDetailsPage(
                        workout: globals.dailyWorkoutPlan!,
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle,
                      color: Theme.of(context).primaryColorDark,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Technik ansehen',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 100),
              WorkoutScheduleWidget(workout: globals.dailyWorkoutPlan!),
              Expanded(child: SizedBox(height: 20)),
              // Text(
              //   globals.dailyWorkoutPlan!.durationString,
              //   style: TextStyle(color: Colors.white),
              // ),
              // SizedBox(height: 20),
              IconButton(
                onPressed: () async {
                  await deleteDailyWorkoutPlan();
                  setState(() {
                    globals.dailyWorkoutPlan = null;
                    selectedWorkout = null;
                  });
                },
                icon: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.amber,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        : SizedBox();

    Widget workoutCompletedWidget = globals.dailyWorkoutPlan != null
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 100),
                    SizedBox(height: 10),
                    Text(
                      'GESCHAFFT!',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium!.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                Text(globals.dailyWorkoutPlan!.name, style: baseTextStyle),
                Text(
                  'Impact ${globals.dailyWorkoutPlan!.impactLevel.name}',
                  style: baseTextStyle,
                ),
                Text(
                  'Score ${globals.dailyWorkoutPlan!.impactScore}',
                  style: baseTextStyle,
                ),
                Text(
                  'Nächster Spin in ${24 - DateTime.now().hour} Stunden',
                  style: baseTextStyle,
                ),
                LinearProgressIndicator(value: DateTime.now().hour / 24),
              ],
            ),
          )
        : SizedBox();

    bool dailyPlanActionable = false;
    if (globals.dailyWorkoutPlan != null) {
      for (WorkoutStep workoutStep in globals.dailyWorkoutPlan!.schedule) {
        bool workoutStepActionable = true;

        if (workoutStep.completedUnits > 0) {
          workoutStepActionable = false;
          continue;
        }
        TimeOfDay timeOfDay = workoutStep.timeOfDay;
        bool inCorrectTime = !timeOfDayIsPast(timeOfDay);
        print(
          'tod debug: $timeOfDay is future? $inCorrectTime. Completed units: ${workoutStep.completedUnits}',
        );

        if (!inCorrectTime) {
          workoutStepActionable = false;
          continue;
        }
        if (workoutStepActionable) {
          dailyPlanActionable = true;
          break;
        }
      }
    }

    bool dailyPlanResettable = true;
    if (globals.dailyWorkoutPlan != null) {
      for (WorkoutStep workoutStep in globals.dailyWorkoutPlan!.schedule) {
        if (workoutStep.completedUnits > 0) {
          dailyPlanResettable = false;
        }
      }
    }

    return Center(
      child: globals.dailyWorkoutPlan != null
          ? (!dailyPlanActionable
                ? workoutCompletedWidget
                : dailyWorkoutChosenWidget)
          : Column(
              mainAxisAlignment: showSlotMachine
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: AlignmentGeometry.topLeft,
                    child: Text(
                      'Hey, ${authServiceNotifier.value.currentUser?.displayName ?? 'Sportler'}!',
                      textAlign: TextAlign.left,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium!.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                if (!showSlotMachine) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(50, 20, 50, 20),
                    child: Text(
                      'Bereit für deinen heutigen Spin?',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium!.copyWith(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        showSlotMachine = true;
                      });
                    },
                    icon: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'TAGESWORKOUT ZIEHEN',
                          style: TextStyle(
                            color: Theme.of(context).primaryColorDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (showSlotMachine) ...[
                  // Padding(
                  //   padding: const EdgeInsets.all(8.0),
                  //   child: Container(
                  //     decoration: BoxDecoration(
                  //       border: Border.all(color: Colors.transparent),
                  //       borderRadius: BorderRadius.circular(20),
                  //       color: Colors.amber,
                  //     ),
                  //     child: ExpansionTile(
                  //       dense: true,
                  //       showTrailingIcon: true,
                  //       subtitle: null,
                  //       trailing: null,
                  //       title: Row(
                  //         spacing: 5,
                  //         mainAxisSize: MainAxisSize.min,
                  //         children: [
                  //           Icon(Icons.fitness_center),
                  //           Text('Filter'),
                  //         ],
                  //       ),
                  //       children: [
                  //         Text('Muskelgruppen:'),
                  //         Text('Anstrengung:'),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Bereit für deinen heutigen Spin?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SlotMachine(
                      height: 280,
                      staggerMs: 100,
                      controller: controller,
                      showLever: false,
                      symbolsPerReel: [
                        List.generate(
                          workoutTypeNames.length,
                          (idx) => Text(workoutTypeNames[idx]),
                        ),
                        List.generate(intensities.length, (idx) {
                          return Text(intensities[idx].toString());
                        }),
                        List.generate(schedules.length, (idx) {
                          return Text(workoutScheduleToString(schedules[idx]));
                        }),
                      ],
                      reelTitles: const [
                        Text('Übung'),
                        Text('Intensität'),
                        Text('Häufigkeit'),
                      ],
                      onResult: (idx) => debugPrint('Result: $idx'),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      //Select a random workout
                      Random rng = Random();
                      int scheduleIdx = rng.nextInt(
                        schedules.length,
                      ); //random idx
                      int intensityIdx = rng.nextInt(intensities.length);
                      ScheduledWorkout _selectedWorkout =
                          ScheduledWorkout.fromBaseWorkout(
                            intensityFilteredWorkouts[rng.nextInt(
                              intensityFilteredWorkouts.length,
                            )],
                            schedules[scheduleIdx],
                            intensities[intensityIdx],
                          );
                      int workoutTypeIdx = workoutTypeNames.indexOf(
                        _selectedWorkout.name,
                      );

                      await controller.spinTo([
                        workoutTypeIdx,
                        intensityIdx,
                        scheduleIdx,
                      ]);

                      _selectedWorkout = userLevel.applyToWorkout(
                        _selectedWorkout,
                      );

                      setState(() {
                        selectedWorkout = _selectedWorkout;
                        globals.dailyWorkoutPlan = _selectedWorkout;
                      });

                      await selectedWorkout!.saveAsDailyWorkoutPlan();
                    },
                    icon: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'DREHEN',
                          style: TextStyle(
                            color: Theme.of(context).primaryColorDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (selectedWorkout != null) ...[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: WorkoutSummaryWidget(workout: selectedWorkout!),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'WEITER ZUR AUFGABE',
                            style: TextStyle(
                              color: Theme.of(context).primaryColorDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
                if (!showSlotMachine)
                FutureBuilder(future: loadWorkoutHistoryFromServer(), builder: 
                  (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Fehler beim Laden der Historie');
                    }
                    List<ScheduledWorkout> history = snapshot.data ?? [];
                    int currentStreak = computeCurrentStreakFromHistory(history);
                    return Text(
                      '🔥 Serie: $currentStreak Tage aktiv',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                ),
              ],
            ),
    );
  }
}

class WorkoutLibraryPage extends StatefulWidget {
  const WorkoutLibraryPage({super.key});

  @override
  State<WorkoutLibraryPage> createState() => _WorkoutLibraryPageState();
}

class _WorkoutLibraryPageState extends State<WorkoutLibraryPage> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, idx) {
        print('Library debug: ${globals.workoutLibrary[idx].workoutType}');
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: WorkoutSummaryWidget(workout: globals.workoutLibrary[idx]),
        );
      },
      itemCount: globals.workoutLibrary.length,
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(children: [SizedBox(height: 25)]),
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
          backgroundImage: NetworkImage(
            authServiceNotifier.value.currentUser?.photoURL ??
                'https://www.gravatar.com/avatar/?d=mp&f=y',
          ),
        ),
        Text(
          '${authServiceNotifier.value.currentUser?.displayName ?? 'Sportler'}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Dein RIZE-Fitnessscore: ${(globals.userData!.intensityScore * 100).toStringAsFixed(0) ?? 'Lade...'} von 100',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        _menuButton(
          'Konto',
          Icon(Icons.person, color: Theme.of(context).primaryColorDark),
          () {},
          Colors.white,
          Theme.of(context).primaryColorDark,
        ),
        _menuButton(
          'Einstellungen',
          Icon(Icons.settings, color: Theme.of(context).primaryColorDark),
          () {},
          Colors.white,
          Theme.of(context).primaryColorDark,
        ),
        _menuButton(
          'Hilfe & Support',
          Icon(Icons.help, color: Theme.of(context).primaryColorDark),
          () {},
          Colors.white,
          Theme.of(context).primaryColorDark,
        ),
        _menuButton(
          'Über RIZE',
          Icon(Icons.info, color: Theme.of(context).primaryColorDark),
          () {},
          Colors.white,
          Theme.of(context).primaryColorDark,
        ),
        _menuButton(
          'Abmelden',
          Icon(Icons.arrow_circle_left_rounded, color: Colors.white),
          () async {
            await authServiceNotifier.value.signOut();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const WelcomePage()),
            );
          },
          Colors.red,
          Colors.white,
        ),
      ],
    );
  }

  Widget _menuButton(
    String text,
    Widget icon,
    VoidCallback onPressed,
    Color backgroundColor,
    Color fontColor,
  ) {
    return IconButton(
      onPressed: onPressed,
      icon: Container(
        width: 300,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            spacing: 5,
            children: [
              icon,
              Text(
                text,
                style: TextStyle(
                  color: fontColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
              Expanded(child: SizedBox()),
              Icon(Icons.arrow_right_sharp, color: fontColor),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgressOverviewContent extends StatelessWidget {
  const ProgressOverviewContent({super.key, required this.userId});

  final String userId;

  @override
  Widget build(final BuildContext context) {
    final CollectionReference<Map<String, Object?>> col = FirebaseFirestore
        .instance
        .collection('users')
        .doc(userId)
        .collection('workoutHistory');

      final CollectionReference<Map<String, Object?>> scoreHistory = FirebaseFirestore
        .instance
        .collection('users')
        .doc(userId)
        .collection('scoreHistory');

    return StreamBuilder<QuerySnapshot<Map<String, Object?>>>(
  stream: col.limit(500).snapshots(),
  builder: (context, snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snap.hasError) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Fehler beim Laden: ${snap.error}'),
      );
    }

    // --- Parse workout history (as you already do) ---
    final docs = snap.data?.docs ?? <QueryDocumentSnapshot<Map<String, Object?>>>[];

    final List<WorkoutDayEntry> entries = <WorkoutDayEntry>[];
    for (final doc in docs) {
      final DateTime? date = _tryParseDocIdDate(doc.id);
      if (date == null) continue;

      final Map<String, dynamic> json = _toDynamicMap(doc.data());
      final ScheduledWorkout workout = ScheduledWorkout.fromJson(json);
      entries.add(WorkoutDayEntry(date: date, workout: workout));
    }

    entries.sort((a, b) => a.date.compareTo(b.date));

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final Stats stats = Stats.fromEntries(entries);

    final int currentStreak = _computeCurrentStreak(stats.activeDays, today);
    final int bestStreak = _computeBestStreak(stats.activeDays);

    final DayImpact? lastImpact = stats.lastImpact;
    final String lastImpactLabel = lastImpact == null
        ? '—'
        : '${_impactLevelLabel(lastImpact.impactLevel)} – ${_fmt(lastImpact.score)}';

    // Build impact series for last 30 days
    final List<DayImpactPoint> impactLast30 = _last30Points(stats.impactByDay, today);

    // --- Now load scoreHistory too ---
    return StreamBuilder<QuerySnapshot<Map<String, Object?>>>(
      stream: scoreHistory.limit(500).snapshots(),
      builder: (context, scoreSnap) {
        if (scoreSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (scoreSnap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Fehler beim Laden (Score History): ${scoreSnap.error}'),
          );
        }

        final scoreDocs = scoreSnap.data?.docs ?? <QueryDocumentSnapshot<Map<String, Object?>>>[];
        final Map<DateTime, double> scoreByDay = _parseScoreHistory(scoreDocs);

        final List<DayImpactPoint> scoreLast30 = _last30PointsScore(scoreByDay, today);

        final Color textColor = Colors.white;
        final Color card = Theme.of(context).colorScheme.surface.withOpacity(0.30);

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: textColor),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _HeaderRow(title: 'Serie & Erfolgsstatistik'),
                  const SizedBox(height: 14),

                  _StatRow(label: 'Aktuelle Serie', value: '🔥 $currentStreak Tage aktiv'),
                  _StatRow(label: 'Beste Serie', value: '$bestStreak Tage'),
                  _StatRow(label: 'Absolvierte Spins', value: '${stats.absoluteSpins}'),
                  _StatRow(label: 'Dynamische Wiederholungen', value: '${stats.dynamicReps}'),
                  _StatRow(label: 'Statisch gehalten', value: '${(stats.staticSeconds / 60).floor()} min'),
                  _ImpactRow(
                    label: 'Letzter Impact',
                    value: lastImpactLabel,
                    dot: _impactDotColor(lastImpact?.impactLevel),
                  ),

                  const SizedBox(height: 22),
                  Text(
                    'Impact Score-Entwicklung',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                  ),
                  const SizedBox(height: 10),

                  _ImpactChart(
                    impactPoints: impactLast30,
                    scorePoints: scoreLast30,
                    cardColor: card,
                    textColor: textColor,
                  ),

                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Letzten 30 Tage',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: textColor.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),

                  const SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: _LevelCard(
                          level: globals.userData!.intensityLevel.label,
                          progress: globals.userData!.intensityLevel
                              .progressToNextLevel(globals.userData!.intensityScore),
                          cardColor: card,
                          textColor: textColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _HistoryCalendarCard(
                          month: today,
                          activeDaysInMonth: _activeDaysInMonth(stats.activeDays, today),
                          cardColor: card,
                          textColor: textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  },
);

  }
}

/* ============================= Typed models ============================= */

@immutable
class WorkoutDayEntry {
  const WorkoutDayEntry({required this.date, required this.workout});

  final DateTime date; // normalized yyyy-MM-dd
  final ScheduledWorkout workout;
}

@immutable
class DayImpact {
  const DayImpact({required this.score, required this.impactLevel});

  final double score;
  final ImpactLevel impactLevel;
}

@immutable
class DayImpactPoint {
  const DayImpactPoint({
    required this.index,
    required this.date,
    required this.score,
  });

  final int index; // 0..29
  final DateTime date;
  final double? score; // null if no completed workout that day
}

@immutable
class Stats {
  const Stats({
    required this.absoluteSpins,
    required this.dynamicReps,
    required this.staticSeconds,
    required this.activeDays,
    required this.impactByDay,
    required this.lastImpact,
  });

  /// With 1 workout/day, "Spins" is best interpreted as completedUnits total.
  final int absoluteSpins;

  final int dynamicReps;
  final int staticSeconds;

  /// Active day = completedUnits > 0
  final Set<DateTime> activeDays;

  /// Only present if completedUnits > 0
  final Map<DateTime, DayImpact> impactByDay;

  final DayImpact? lastImpact;

  static Stats fromEntries(final List<WorkoutDayEntry> entries) {
    int spins = 0;
    int dyn = 0;
    int statSec = 0;

    final Set<DateTime> active = <DateTime>{};
    final Map<DateTime, DayImpact> impactByDay = <DateTime, DayImpact>{};

    DayImpact? lastImpact;

    for (final WorkoutDayEntry e in entries) {
      final DateTime day = DateTime(e.date.year, e.date.month, e.date.day);
      final ScheduledWorkout w = e.workout;

      final int completedUnits = _completedUnits(w.schedule);
      if (completedUnits <= 0) {
        continue;
      }

      active.add(day);
      spins += completedUnits;

      if (w.workoutType == WorkoutType.dynamic) {
        final int repsPerUnit = (w.baseReps ?? 0) * w.intensityFactor;
        dyn += repsPerUnit * completedUnits;
      } else {
        final int secPerUnit = (w.baseSeconds ?? 0) * w.intensityFactor;
        statSec += secPerUnit * completedUnits;
      }

      final DayImpact impact = DayImpact(
        score: w.impactScore,
        impactLevel: w.impactLevel,
      );
      impactByDay[day] = impact;
      lastImpact = impact;
    }

    return Stats(
      absoluteSpins: spins,
      dynamicReps: dyn,
      staticSeconds: statSec,
      activeDays: active,
      impactByDay: impactByDay,
      lastImpact: lastImpact,
    );
  }
}

int _completedUnits(final List<WorkoutStep> schedule) {
  int sum = 0;
  for (final WorkoutStep entry in schedule) {
    sum += entry.completedUnits;
  }
  return sum;
}

/* ============================= Firestore parsing ============================= */

DateTime? _tryParseDocIdDate(final String id) {
  // yyyy-MM-dd
  final List<String> parts = id.split('-');
  if (parts.length == 3) {
    final int? y = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    final int? d = int.tryParse(parts[2]);
    if (y != null && m != null && d != null) return DateTime(y, m, d);
  }
  // yyyymmdd
  if (id.length == 8) {
    final int? y = int.tryParse(id.substring(0, 4));
    final int? m = int.tryParse(id.substring(4, 6));
    final int? d = int.tryParse(id.substring(6, 8));
    if (y != null && m != null && d != null) return DateTime(y, m, d);
  }
  return null;
}

Map<String, dynamic> _toDynamicMap(final Map<String, Object?> src) {
  final Map<String, dynamic> out = <String, dynamic>{};
  for (final MapEntry<String, Object?> e in src.entries) {
    out[e.key] = _toDynamicValue(e.value);
  }
  return out;
}

dynamic _toDynamicValue(final Object? v) {
  if (v == null) return null;
  if (v is Map<String, Object?>) return _toDynamicMap(v);
  if (v is List<Object?>) {
    final List<dynamic> out = <dynamic>[];
    for (final Object? x in v) {
      out.add(_toDynamicValue(x));
    }
    return out;
  }
  return v;
}

/* ============================= Streaks / last 30 ============================= */

int _computeCurrentStreak(
  final Set<DateTime> activeDays,
  final DateTime today,
) {
  if (activeDays.isEmpty) return 0;

  DateTime cursor = today;
  if (!activeDays.contains(cursor)) {
    final DateTime yesterday = cursor.subtract(const Duration(days: 1));
    if (activeDays.contains(yesterday)) {
      cursor = yesterday;
    } else {
      return 0;
    }
  }

  int streak = 0;
  while (activeDays.contains(cursor)) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

int _computeBestStreak(final Set<DateTime> activeDays) {
  if (activeDays.isEmpty) return 0;
  final List<DateTime> dates = activeDays.toList()..sort();

  int best = 1;
  int cur = 1;

  for (int i = 1; i < dates.length; i++) {
    final int diff = dates[i].difference(dates[i - 1]).inDays;
    if (diff == 1) {
      cur += 1;
      if (cur > best) best = cur;
    } else if (diff > 0) {
      cur = 1;
    }
  }
  return best;
}

List<DayImpactPoint> _last30Points(
  final Map<DateTime, DayImpact> impactByDay,
  final DateTime today,
) {
  final DateTime start = today.subtract(const Duration(days: 29));
  final List<DayImpactPoint> out = <DayImpactPoint>[];

  for (int i = 0; i < 30; i++) {
    final DateTime d = DateTime(start.year, start.month, start.day + i);
    final DayImpact? imp = impactByDay[d];
    out.add(DayImpactPoint(index: i, date: d, score: imp?.score));
  }
  return out;
}

Set<int> _activeDaysInMonth(
  final Set<DateTime> activeDays,
  final DateTime month,
) {
  final Set<int> out = <int>{};
  for (final DateTime d in activeDays) {
    if (d.year == month.year && d.month == month.month) out.add(d.day);
  }
  return out;
}

/* ============================= Formatting / colors ============================= */

String _fmt(final double v) => v.toStringAsFixed(2).replaceAll('.', ',');

String _impactLevelLabel(final ImpactLevel level) {
  switch (level) {
    case ImpactLevel.low:
      return 'Low';
    case ImpactLevel.medium:
      return 'Medium';
    case ImpactLevel.high:
      return 'High';
  }
}

Color _impactDotColor(final ImpactLevel? level) {
  if (level == null) return Colors.grey;
  switch (level) {
    case ImpactLevel.low:
      return Colors.green;
    case ImpactLevel.medium:
      return Colors.orange;
    case ImpactLevel.high:
      return Colors.red;
  }
}

/* ============================= UI (typed) ============================= */

class _HeaderRow extends StatelessWidget {
  _HeaderRow({required this.title});

  final String title;

  @override
  Widget build(final BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(final BuildContext context) {
    //final Color c = Theme.of(context).colorScheme.onSurface.withOpacity(0.95);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 17),
            ), //, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: c)),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 17),
            //style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            //color: c,
            //       fontWeight: FontWeight.w800,
            //    ),
          ),
        ],
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({
    required this.label,
    required this.value,
    required this.dot,
  });

  final String label;
  final String value;
  final Color dot;

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: TextStyle(fontSize: 17))),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(value, style: TextStyle(fontSize: 17)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactChart extends StatelessWidget {
  const _ImpactChart({
    required this.impactPoints,
    required this.scorePoints,
    required this.cardColor,
    required this.textColor,
  });

  final List<DayImpactPoint> impactPoints;
  final List<DayImpactPoint> scorePoints;

  final Color cardColor;
  final Color textColor;

  @override
  Widget build(final BuildContext context) {
    // Series 1: Impact
    final List<FlSpot> impactSpots = <FlSpot>[];
    for (final DayImpactPoint p in impactPoints) {
      if (p.score != null) impactSpots.add(FlSpot(p.index.toDouble(), p.score!));
    }

    // Series 2: Score history
    final List<FlSpot> scoreSpots = <FlSpot>[];
    for (final DayImpactPoint p in scorePoints) {
      if (p.score != null) scoreSpots.add(FlSpot(p.index.toDouble(), p.score!));
    }

    // Compute y-range from BOTH series
    final List<double> ys = <double>[
      ...impactSpots.map((s) => s.y),
      ...scoreSpots.map((s) => s.y),
    ];

    final double minY = ys.isEmpty ? 0.0 : ys.reduce((a, b) => a < b ? a : b);
    final double maxY = ys.isEmpty ? 0.25 : ys.reduce((a, b) => a > b ? a : b);

    final double paddedMin = (minY - 0.02).clamp(0.0, 10.0);
    final double paddedMax = (maxY + 0.02).clamp(0.0, 10.0);

    final Color axis = textColor.withOpacity(0.85);
    final Color grid = textColor.withOpacity(0.12);

    // Pick explicit colors so it’s deterministic
    final Color impactColor = Colors.greenAccent;
    final Color scoreColor = Colors.blue;

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          // Legend
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: <Widget>[
                _LegendItem(color: impactColor, label: 'Übung'),
                const SizedBox(width: 14),
                _LegendItem(color: scoreColor, label: 'RIZE-Score'),
              ],
            ),
          ),

          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 29,
                minY: paddedMin,
                maxY: paddedMax,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (paddedMax - paddedMin) <= 0
                      ? 0.05
                      : (paddedMax - paddedMin) / 4,
                  getDrawingHorizontalLine: (final double _) =>
                      FlLine(color: grid, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text('Datum', style: TextStyle(color: axis, fontSize: 12)),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 7,
                      reservedSize: 18,
                      getTitlesWidget: (final double value, final TitleMeta meta) {
                        final int idx = value.round();
                        if (idx < 0 || idx >= impactPoints.length) {
                          return const SizedBox.shrink();
                        }
                        final DateTime d = impactPoints[idx].date;
                        final String txt = '${d.day}.${d.month}.';
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(txt, style: TextStyle(color: axis, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text('Score', style: TextStyle(color: axis, fontSize: 12)),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: (paddedMax - paddedMin) <= 0
                          ? 0.05
                          : (paddedMax - paddedMin) / 4,
                      getTitlesWidget: (final double value, final TitleMeta meta) {
                        return Text(
                          _fmt(value),
                          style: TextStyle(color: axis, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    spots: impactSpots,
                    isCurved: false,
                    barWidth: 0,
                    color: impactColor,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: impactColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: scoreSpots,
                    isCurved: false,
                    barWidth: 3,
                    color: scoreColor,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white.withOpacity(0.9),
              ),
        ),
      ],
    );
  }
}


class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.progress,
    required this.cardColor,
    required this.textColor,
  });

  final String level;
  final double progress;
  final Color cardColor;
  final Color textColor;

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Level',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            level,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Fortschritt',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: textColor),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: textColor.withOpacity(0.12),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCalendarCard extends StatelessWidget {
  const _HistoryCalendarCard({
    required this.month,
    required this.activeDaysInMonth,
    required this.cardColor,
    required this.textColor,
  });

  final DateTime month;
  final Set<int> activeDaysInMonth;
  final Color cardColor;
  final Color textColor;

  @override
  Widget build(final BuildContext context) {
    final DateTime first = DateTime(month.year, month.month, 1);
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final int firstWeekday = first.weekday; // Mon=1 .. Sun=7
    final int leadingEmpty = (firstWeekday - DateTime.monday) % 7;

    const List<String> dow = <String>['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Historie',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dow
                .map(
                  (final String s) => SizedBox(
                    width: 22,
                    child: Text(
                      s,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textColor.withOpacity(0.85),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          _CalendarGrid(
            leadingEmpty: leadingEmpty,
            daysInMonth: daysInMonth,
            activeDays: activeDaysInMonth,
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.leadingEmpty,
    required this.daysInMonth,
    required this.activeDays,
    required this.textColor,
  });

  final int leadingEmpty;
  final int daysInMonth;
  final Set<int> activeDays;
  final Color textColor;

  @override
  Widget build(final BuildContext context) {
    final int totalCells = leadingEmpty + daysInMonth;
    final int rows = (totalCells / 7).ceil().clamp(1, 6);

    return Column(
      children: List<Widget>.generate(rows, (final int row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(7, (final int col) {
              final int idx = row * 7 + col;
              final int day = idx - leadingEmpty + 1;

              if (idx < leadingEmpty || day < 1 || day > daysInMonth) {
                return const SizedBox(width: 22, height: 22);
              }

              final bool isActive = activeDays.contains(day);

              return SizedBox(
                width: 22,
                height: 22,
                child: Center(
                  child: isActive
                      ? Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          '$day',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: textColor.withOpacity(0.75),
                          ),
                        ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

Map<DateTime, double> _parseScoreHistory(
  final List<QueryDocumentSnapshot<Map<String, Object?>>> docs,
) {
  final Map<DateTime, double> out = <DateTime, double>{};

  for (final doc in docs) {
    final Map<String, Object?> data = doc.data();

    // Prefer workoutId because it aligns with your workoutHistory doc ids (yyyy-MM-dd)
    DateTime? day;
    final Object? workoutIdRaw = data['workoutId'];
    if (workoutIdRaw is String) {
      day = _tryParseDocIdDate(workoutIdRaw);
    }

    // Fallback: ts
    if (day == null) {
      final Object? tsRaw = data['ts'];
      if (tsRaw is Timestamp) {
        final DateTime dt = tsRaw.toDate();
        day = DateTime(dt.year, dt.month, dt.day);
      }
    }

    if (day == null) continue;

    // Choose the series you want to plot:
    // - newScore (overall score after workout)
    // - or impactScore (per-workout impact)
    final double? v = _asDouble(data['newScore']); // <— recommend this
    if (v == null) continue;

    out[DateTime(day.year, day.month, day.day)] = v;
  }

  return out;
}

double? _asDouble(final Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '.'));
  return null;
}


List<DayImpactPoint> _last30PointsScore(
  final Map<DateTime, double> scoreByDay,
  final DateTime today,
) {
  final DateTime start = today.subtract(const Duration(days: 29));
  final List<DayImpactPoint> out = <DayImpactPoint>[];

  for (int i = 0; i < 30; i++) {
    final DateTime d = DateTime(start.year, start.month, start.day + i);
    final double? v = scoreByDay[d];
    out.add(DayImpactPoint(index: i, date: d, score: v));
  }
  return out;
}

