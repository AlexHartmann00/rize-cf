library;

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rize/helpers/auth_service.dart';
import 'package:rize/types/anamnesis.dart';
import 'package:rize/types/config.dart' show IntensityLevel;
import 'package:rize/types/user.dart';
import 'package:rize/types/workout.dart';
import 'package:intl/intl.dart';
import 'package:rize/utils.dart' show Time;

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
  print('FB usage: Saving anamnesis response to Firestore');
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
  print('FB usage: Creating user document in Firestore');
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
    return UserData(intensityScore: 0.0, spinReminderTime: null);
  }
}

Future<void> updateUserFCMToken(String? fcmToken) async {
  print('FB usage: Updating user FCM token in Firestore');
  String userId = authServiceNotifier.value.currentUser?.uid ?? '';
  if (userId.isEmpty) return;

  CollectionReference<Map<String, dynamic>> usersCollection = FirebaseFirestore
      .instance
      .collection('users');

  await usersCollection.doc(userId).update({'fcmToken': fcmToken});
}

Future<void> uploadWorkoutToServer(ScheduledWorkout workout) async {
  final String userId = authServiceNotifier.value.currentUser?.uid ?? '';
  if (userId.isEmpty) return;
  final DateTime now = workout.scheduledDay ?? DateTime.now();
  final Map<String, dynamic> jsonData = workout.toJson()
    ..addAll(<String, dynamic>{
      'scheduledAt': Timestamp.fromDate(now),
      'dayKey': DateFormat('yyyy-MM-dd').format(now),
      'updatedAt': FieldValue.serverTimestamp(),
      'schemaVersion': 2,
    });
  final CollectionReference<Map<String, dynamic>> history = FirebaseFirestore
      .instance
      .collection('users')
      .doc(userId)
      .collection('workoutHistory');
  final bool isNewSession = workout.historyId == null;
  final DocumentReference<Map<String, dynamic>> reference =
      isNewSession
      ? history.doc()
      : history.doc(workout.historyId);
  workout.historyId = reference.id;
  jsonData['historyId'] = reference.id;
  if (isNewSession) jsonData['createdAt'] = FieldValue.serverTimestamp();
  await reference.set(jsonData, SetOptions(merge: true));
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
    workout.historyId = doc.id;
    workout.scheduledDay ??= DateTime.tryParse(doc.id);
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

Future<DailyWorkoutPlan?> loadDailyWorkoutPlan() async {
  String userId = authServiceNotifier.value.currentUser?.uid ?? '';
  if (userId.isEmpty) return null;

  final String dayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
      .instance
      .collection('users')
      .doc(userId)
      .collection('workoutHistory')
      .where('dayKey', isEqualTo: dayKey)
      .get();

  final List<ScheduledWorkout> workouts = <ScheduledWorkout>[];
  for (final doc in snapshot.docs) {
    final ScheduledWorkout workout = ScheduledWorkout.fromJson(doc.data());
    workout.historyId = doc.id;
    workout.scheduledDay ??= DateTime.now();
    workouts.add(workout);
  }
  // Read the old date-keyed document during the migration period.
  if (workouts.isEmpty) {
    final legacy = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('workoutHistory')
        .doc(dayKey)
        .get();
    if (legacy.data() != null) {
      final workout = ScheduledWorkout.fromJson(legacy.data()!);
      workout.historyId = legacy.id;
      workout.scheduledDay = DateTime.now();
      workouts.add(workout);
    }
  }
  if (workouts.isEmpty) return null;
  final String planId = workouts.first.planId ?? 'legacy-$dayKey';
  return DailyWorkoutPlan(id: planId, workouts: workouts);
}

Future<void> deleteDailyWorkoutPlan() async {
  print('FB usage: Deleting workout plan');
  String userId = authServiceNotifier.value.currentUser?.uid ?? '';

  final String dayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final history = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('workoutHistory');
  final snapshot = await history.where('dayKey', isEqualTo: dayKey).get();
  final batch = FirebaseFirestore.instance.batch();
  for (final doc in snapshot.docs) {
    final workout = ScheduledWorkout.fromJson(doc.data());
    if (!workout.isCompleted) batch.delete(doc.reference);
  }
  final legacy = await history.doc(dayKey).get();
  if (legacy.exists) batch.delete(legacy.reference);
  await batch.commit();
}

Future<void> updateSpinReminderTime(Time? newTime) async {
  print('FB usage: Updating spin reminder time');
  String userId = authServiceNotifier.value.currentUser?.uid ?? '';

  await FirebaseFirestore.instance.collection('users').doc(userId).update({
    'spinReminderTime': newTime != null
        ? '${newTime.hour}:${newTime.minute}'
        : null,
  });
}
