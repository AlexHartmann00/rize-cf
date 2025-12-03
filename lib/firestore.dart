library;

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rize/auth_service.dart';
import 'package:rize/types/anamnesis.dart';
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

    await FirebaseFirestore
      .instance
      .collection('users')
      .doc(userId)
      .collection('workoutHistory')
      .doc(dateString).set(jsonData);

    await workout.saveAsDailyWorkoutPlan();
  }