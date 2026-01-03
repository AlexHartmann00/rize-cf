import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rize/firestore.dart';

ValueNotifier<AuthService> authServiceNotifier = ValueNotifier<AuthService>(
  AuthService(),
);

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user?.updateDisplayName(displayName);
      //Create user document in firestore
      await createUserDocument(userCredential.user!.uid);
      return userCredential;
    } catch (e) {
      print('Error registering: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUsername(String displayName) async {
    if (currentUser != null) {
      await currentUser!.updateDisplayName(displayName);
      await currentUser!.reload();
    }
  }

  Future<void> deleteAccountWithReauthentication(
    String email,
    String password,
  ) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    if (currentUser != null) {
      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.delete();
    }
  }

  Future<void> updatePasswordWithCurrentPassword(
    String email,
    String currentPassword,
    String newPassword,
  ) async {
    if (currentUser != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.updatePassword(newPassword);
    }
  }
}
