import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fitness_app/auth_service.dart';
import 'package:fitness_app/base_widgets.dart';
import 'package:fitness_app/firebase_options.dart';
import 'package:fitness_app/firestore.dart';
import 'package:fitness_app/globals.dart' as globals;
import 'package:fitness_app/slot_machine.dart'
    show SlotMachine, SlotMachineController;
import 'package:fitness_app/types/anamnesis.dart';
import 'package:fitness_app/types/workout.dart';
import 'package:fitness_app/utils.dart' show loadDailyWorkoutPlan;
import 'package:fitness_app/widgets.dart';
import 'package:fitness_app/workout_library.dart';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fitness_app/globals.dart' as data;
import 'package:shared_preferences/shared_preferences.dart';

//TODO: Daily workout in shared preferences
// Creation day; workout id; schedule & schedule progress; intensity
// On app start, if saved workout day was before today, clear saved workout

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Current user: ${authServiceNotifier.value.currentUser}');
  await authServiceNotifier.value.signOut();
  loadWorkoutCollection().then((value) {
    data.workoutLibrary = value;
  });
  authServiceNotifier.value.authStateChanges.listen((user) {
    if (user != null) {
      loadUserData(user.uid).then((userData) {
        globals.userData = userData;
        print('User logged in: ${user.uid}');
        globals.authenticatedUserId = user.uid;
      });
    } else {
      print('User logged out');
      globals.authenticatedUserId = null;
    }
  });
  globals.dailyWorkoutPlan = null; //TODO = await loadDailyWorkoutPlan();
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
    loadUserData(authServiceNotifier.value.currentUser!.uid).then((userData) {
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
        1 => const Center(child: Text('Fortschritt')),
        2 => const WorkoutLibraryPage(),
        3 => const Center(child: Text('Profil')),
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

  @override
  Widget build(BuildContext context) {
    //TODO: Check that user data is always loaded. Currently, if it is not loaded, it will be disregarded
    List<Workout> intensityFilteredWorkouts = globals.userData != null
        ? globals.workoutLibrary
              .where(
                (workout) =>
                    workout.impactScore >
                        globals.userData!.intensityScore - 0.2 &&
                    workout.impactScore <
                        globals.userData!.intensityScore + 0.2,
              )
              .toList()
        : globals.workoutLibrary;
    List<String> workoutTypeNames = intensityFilteredWorkouts
        .map((e) => e.name)
        .toSet()
        .toList();
    List<int> intensities = [
      2,
      3,
      4,
      5,
      6,
      7,
      8,
    ]; //TODO: FIlter based on user fitness
    List<List<(TimeOfDay, int, bool)>> schedules = [
      [(TimeOfDay.morning, 1, false), (TimeOfDay.evening, 1, false)],
      [(TimeOfDay.any, 3, false)],
      [(TimeOfDay.morning, 1, false)],
    ];

    SharedPreferences.getInstance().then((prefs) async {
      bool questionnaireSubmitted = prefs.getBool('anamnesisDone') ?? true;
      if (questionnaireSubmitted) {
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

    Widget scheduleEntryWidget((TimeOfDay, int, bool) entry) {
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
            Text('× ${entry.$2}'),
            SizedBox(width: 10),
            Icon(
              entry.$3 ? Icons.check_circle : Icons.radio_button_unchecked,
              color: entry.$3 ? Colors.green : Colors.grey,
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
              WorkoutSummaryWidget(workout: globals.dailyWorkoutPlan!),
              SizedBox(height: 10),
              Text(
                'Zeitplan',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium!.copyWith(color: Colors.white),
              ),
              globals.dailyWorkoutPlan!.schedule.isEmpty
                  ? Text(
                      'Kein Zeitplan festgelegt',
                      style: TextStyle(color: Colors.white),
                    )
                  : Column(
                      children: globals.dailyWorkoutPlan!.schedule
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: scheduleEntryWidget(entry),
                            ),
                          )
                          .toList(),
                    ),
              SizedBox(height: 20),
              Text(
                globals.dailyWorkoutPlan!.durationString,
                style: TextStyle(color: Colors.white),
              ),
            ],
          )
        : SizedBox();

    return Center(
      child: globals.dailyWorkoutPlan != null
          ? dailyWorkoutChosenWidget
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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.amber,
                      ),
                      child: ExpansionTile(
                        dense: true,
                        showTrailingIcon: true,
                        subtitle: null,
                        trailing: null,
                        title: Row(
                          spacing: 5,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fitness_center),
                            Text('Filter'),
                          ],
                        ),
                        children: [
                          Text('Muskelgruppen:'),
                          Text('Anstrengung:'),
                        ],
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
                        [Text('Morgens / Abends'), Text('3x'), Text('1x')],
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
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'DREHEN',
                          style: TextStyle(
                            color: Theme.of(context).primaryColorDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
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
                  Text(
                    '🔥 Serie: 8 Tage aktiv',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: WorkoutSummaryWidget(workout: globals.workoutLibrary[idx]),
        );
      },
      itemCount: globals.workoutLibrary.length,
    );
  }
}
