import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:rize/base_widgets.dart';
import 'package:rize/firebase_options.dart';
import 'package:rize/firestore.dart';
import 'package:rize/globals.dart' as globals;
import 'package:rize/helpers/auth_service.dart';
import 'package:rize/pages/home_page.dart';
import 'package:rize/pages/welcome_page.dart';
import 'package:rize/widgets/muscle_visualizer.dart';
import 'package:rize/pages/progress_overview_content.dart';
import 'package:rize/pages/workout_library_page.dart';

import 'package:rize/widgets/slot_machine.dart' show SlotMachine, SlotMachineController;
import 'package:rize/types/anamnesis.dart';
import 'package:rize/types/config.dart' show IntensityLevel;
import 'package:rize/types/user.dart' show UserData;
import 'package:rize/types/workout.dart';
import 'package:rize/utils.dart'
    show timeOfDayIsCurrent, timeOfDayIsPast, workoutScheduleToString, computeCurrentStreakFromHistory, Time;
import 'package:rize/widgets.dart';
import 'package:rize/widgets/workout_library_widgets.dart' show WorkoutSummaryWidget;
import 'package:rize/workout_library.dart';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'dart:convert';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

//TODO: Daily workout in shared preferences
// Creation day; workout id; schedule & schedule progress; intensity
// On app start, if saved workout day was before today, clear saved workout

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: true,
      sound: true,
      providesAppNotificationSettings: true
    );
    await Future.delayed(Duration(seconds: 1));
    String? apnsToken = await messaging.getAPNSToken();
    print('APNs Token: $apnsToken');
    await Future.delayed(Duration(seconds: 1));
    String? fcmToken = await messaging.getToken();
    await updateUserFCMToken(fcmToken);

    //SharedPreferences prefs = await SharedPreferences.getInstance();
    //prefs.setBool('anamnesisDone', false);

    globals.userData = userData;
  }

  //TODO: remove this; only for testing
  //await authServiceNotifier.value.signOut();
  globals.workoutLibrary = await loadWorkoutCollection();

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
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
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


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Time? reminderTime;
  bool reminderChangesMade = false;
  bool reminderChangesSaving = false;

  @override
  void initState() {
    super.initState();
    reminderTime = globals.userData?.spinReminderTime;
  }

  @override
  Widget build(BuildContext context) {
    return RizeScaffold(
      appBar: rizeAppBar,
      bottomNavigationBar: null,
      body: Column(
        children: [
          SizedBox(height: 18, width: MediaQuery.sizeOf(context).width,),
          Text(
            'Einstellungen',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hier kannst du deine App-Einstellungen anpassen.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            )
          ),
          _sectionHeader('Benachrichtigungen'),
          _menuItemContainer(
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('Tägliche Erinnerung, den Spin auszuführen', style: TextStyle(color: Colors.white),),
                    Switch(value: reminderTime != null, onChanged: (x){
                      if(reminderTime == null){
                        setState(() {
                          reminderChangesMade = true;
                          reminderTime = Time(7,0);
                        });
                      }else{
                        setState(() {
                          reminderChangesMade = true;
                          reminderTime = null;
                        });
                      }
                      
                      
                    })
                  ],
                ),
                if(reminderTime != null)
                  _reminderTimePicker(),
                if(reminderChangesMade)
                  ElevatedButton(onPressed: ()async {
                    setState(() {
                      reminderChangesMade = false;
                      reminderChangesSaving = true;
                      
                    });
                    await updateSpinReminderTime(reminderTime);
                    setState(() {
                      reminderChangesSaving = false;
                    });
                  }, child: reminderChangesSaving ? CircularProgressIndicator() : Text('Speichern'))
              ],
            )
          )
        ]
      ),  
    );
  }

  Widget _reminderTimePicker(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
      NumberPicker(minValue: 0, maxValue: 23, value: reminderTime!.hour, onChanged: (value) {
        setState(() {
          reminderChangesMade = true;
          reminderTime = Time(value, reminderTime!.minute);
        });
      },
        textStyle: TextStyle(color: Colors.white),
        selectedTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
      ),
      Text(':', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
      NumberPicker(minValue: 0, step:30, maxValue: 59, value: reminderTime!.minute, onChanged: (value) {
        setState(() {
          reminderChangesMade = true;
          reminderTime = Time(reminderTime!.hour, value);
        });
      },
        textStyle: TextStyle(color: Colors.white),
        selectedTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),),
      Text('Uhr', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),)
    ],);
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 12),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItemContainer(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

}
