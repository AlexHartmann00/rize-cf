library;

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rize/auth_service.dart';
import 'package:rize/types/anamnesis.dart';
import 'package:rize/types/config.dart' show IntensityLevel;
import 'package:rize/types/user.dart';
import 'package:rize/types/workout.dart';
import 'package:intl/intl.dart';

Future<List<Workout>> loadWorkoutCollection() async {
  CollectionReference<Map<String, dynamic>> collection = FirebaseFirestore
      .instance
      .collection('workouts');

  QuerySnapshot<Map<String, dynamic>> snapshot = await collection.get();

  List<Workout> workouts = [];

  for (QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
    if (doc.data().isEmpty) continue;
    print('FS debug: ${doc.data()['type']}');
    workouts.add(Workout.fromJson(doc.data()));
  }

  return workouts;
}

Future<AnamnesisQuestionnaire> loadAnamnesisQuestionnaire() async {
  //Questionnaire entries are stored as auto ID documents in the anamnesisQuestions collection
  CollectionReference<Map<String, dynamic>> collection = FirebaseFirestore
      .instance
      .collection('anamnesisQuestions');

  QuerySnapshot<Map<String, dynamic>> snapshot = await collection.get();

  List<QuestionnaireEntry> entries = [];

  for (QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
    if (doc.data().isEmpty) continue;
    entries.add(QuestionnaireEntry.fromJson(doc.data()));
  }

  return AnamnesisQuestionnaire(entries: entries);
}

Future<void> saveAnamnesisResponse(AnamnesisQuestionnaire questionnaire) async {
  CollectionReference<Map<String, dynamic>> collection = FirebaseFirestore
      .instance
      .collection('userAnamnesis');

  await collection.add({
    'completionTime': FieldValue.serverTimestamp(),
    'responses': questionnaire.entries.map((entry) {
      return {
        'questionText': entry.questionText,
        'chosenResponseText': entry.responseOptions
            .firstWhere((option) => option.isSelected)
            .optionText,
        'questionScore': entry.responseOptions
            .firstWhere((option) => option.isSelected)
            .optionValue,
      };
    }).toList(),
    'totalScore': questionnaire.totalScore,
    'userId': authServiceNotifier.value.currentUser!.uid,
  });

  //update the user's document to set intensityScore to total score. The user id is the document name
  CollectionReference<Map<String, dynamic>> usersCollection = FirebaseFirestore
      .instance
      .collection('users');

  await usersCollection.doc(authServiceNotifier.value.currentUser!.uid).update({
    'intensityScore': questionnaire.totalScore,
  });
}

// Future<void> updateUserIntensityScore(double intensityScore) async {
//   CollectionReference<Map<String, dynamic>> usersCollection = FirebaseFirestore
//       .instance
//       .collection('users');

//   //Create document if it does not exist
//   await usersCollection.doc(authServiceNotifier.value.currentUser!.uid).set({
//     'intensityScore': intensityScore,
//   }, SetOptions(merge: true));
// }

Future<void> createUserDocument(String userId) {
  CollectionReference<Map<String, dynamic>> usersCollection = FirebaseFirestore
      .instance
      .collection('users');

  return usersCollection.doc(userId).set({'intensityScore': 0.0});
}

Future<UserData> loadUserData(String userId) async {
  DocumentReference<Map<String, dynamic>> docRef = FirebaseFirestore.instance
      .collection('users')
      .doc(userId);

  DocumentSnapshot<Map<String, dynamic>> docSnap = await docRef.get();

  if (docSnap.exists && docSnap.data() != null) {
    return UserData.fromJson(docSnap.data()!);
  } else {
    // Return default UserData if no data exists
    return UserData(intensityScore: 0.0);
  }
}

Future<void> uploadWorkoutToServer(ScheduledWorkout workout) async {
  Map<String, dynamic> jsonData = workout.toJson();
  String jsonString = jsonEncode(jsonData);

  //upload to Firestore collection users/{userId}/workoutHistory/{datestring}
  // with datestring = yyyy-MM-dd

  String userId = authServiceNotifier.value.currentUser?.uid ?? '';
  DateFormat df = DateFormat('yyyy-MM-dd');
  String dateString = df.format(DateTime.now());

  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('workoutHistory')
      .doc(dateString)
      .set(jsonData);

    await workout.saveAsDailyWorkoutPlan();
  }


Future<List<ScheduledWorkout>> loadWorkoutHistoryFromServer() async {
    String userId = authServiceNotifier.value.currentUser?.uid ?? '';

    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
      .instance
      .collection('users')
      .doc(userId)
      .collection('workoutHistory')
      .get();

    List<ScheduledWorkout> workouts = [];

    for (QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      if (doc.data().isEmpty) continue;
      ScheduledWorkout workout = ScheduledWorkout.fromJson(doc.data());
      workout.scheduledDay = DateTime.parse(doc.id);
      workouts.add(workout);
    }

    return workouts;
  }


Future<List<IntensityLevel>> loadIntensityLevels() async {
  DocumentReference<Map<String, dynamic>> docRef = FirebaseFirestore.instance
      .collection('config')
      .doc('intensityLevels');
  DocumentSnapshot<Map<String, dynamic>> docSnap = await docRef.get();
  List<IntensityLevel> levels = [];
  if (docSnap.exists && docSnap.data() != null) {
    Map<String, dynamic> data = docSnap.data()!;
    for (MapEntry entry in data.entries) {
      levels.add(IntensityLevel.fromJson(entry.value));
    }
  }

  return levels;
}


Future<ScheduledWorkout?> loadDailyWorkoutPlan() async {
  String userId = authServiceNotifier.value.currentUser?.uid ?? '';
  if(userId.isEmpty) return null;

    DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
      .instance
      .collection('users')
      .doc(userId)
      .collection('workoutHistory')
      .doc(DateFormat('yyyy-MM-dd').format(DateTime.now()))
      .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    ScheduledWorkout workout = ScheduledWorkout.fromJson(snapshot.data()!);
    workout.scheduledDay = DateTime.now();
    return workout;
}

Future<void> deleteDailyWorkoutPlan() async {
  String userId = authServiceNotifier.value.currentUser?.uid ?? '';

    await FirebaseFirestore
      .instance
      .collection('users')
      .doc(userId)
      .collection('workoutHistory')
      .doc(DateFormat('yyyy-MM-dd').format(DateTime.now()))
      .delete();
}