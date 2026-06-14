
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:rize/firestore.dart';

ValueNotifier<AuthService> authServiceNotifier = ValueNotifier<AuthService>(
  AuthService(),
);

class AuthResult {
  const AuthResult._({
    required this.success,
    this.userCredential,
    this.errorMessage,
  });

  const AuthResult.success(UserCredential credential)
      : this._(
          success: true,
          userCredential: credential,
        );

  const AuthResult.failure(String message)
      : this._(
          success: false,
          errorMessage: message,
        );

  final bool success;
  final UserCredential? userCredential;
  final String? errorMessage;
}

class PasswordResetResult {
  const PasswordResetResult._({
    required this.success,
    this.errorMessage,
  });

  const PasswordResetResult.success()
      : this._(success: true);

  const PasswordResetResult.failure(String message)
      : this._(
          success: false,
          errorMessage: message,
        );

  final bool success;
  final String? errorMessage;
}

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseMessaging? firebaseMessaging,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firebaseMessaging =
            firebaseMessaging ?? FirebaseMessaging.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseMessaging _firebaseMessaging;

  StreamSubscription<String>? _tokenRefreshSubscription;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  Future<AuthResult> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final String normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty || password.isEmpty) {
      return const AuthResult.failure(
        'Bitte gib Deine E-Mail-Adresse und Dein Passwort ein.',
      );
    }

    try {
      final UserCredential credential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      await _configurePushNotifications();

      return AuthResult.success(credential);
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(
        _messageForFirebaseAuthException(error),
      );
    } catch (error, stackTrace) {
      debugPrint('Unexpected sign-in error: $error');
      debugPrintStack(stackTrace: stackTrace);

      return const AuthResult.failure(
        'Die Anmeldung ist gerade nicht möglich. Bitte versuche es erneut.',
      );
    }
  }

  Future<AuthResult> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    final String normalizedEmail = email.trim();
    final String normalizedDisplayName = displayName.trim();

    if (normalizedDisplayName.isEmpty) {
      return const AuthResult.failure(
        'Bitte gib Deinen Namen ein.',
      );
    }

    if (normalizedEmail.isEmpty) {
      return const AuthResult.failure(
        'Bitte gib Deine E-Mail-Adresse ein.',
      );
    }

    if (password.length < 6) {
      return const AuthResult.failure(
        'Dein Passwort muss mindestens sechs Zeichen lang sein.',
      );
    }

    try {
      final UserCredential credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final User? user = credential.user;

      if (user != null) {
        await user.updateDisplayName(normalizedDisplayName);
        await user.reload();

        await createUserDocument(user.uid);
        await _configurePushNotifications();
      }

      return AuthResult.success(credential);
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(
        _messageForFirebaseAuthException(error),
      );
    } catch (error, stackTrace) {
      debugPrint('Unexpected registration error: $error');
      debugPrintStack(stackTrace: stackTrace);

      return const AuthResult.failure(
        'Die Registrierung ist gerade nicht möglich. Bitte versuche es erneut.',
      );
    }
  }

  Future<PasswordResetResult> sendPasswordResetEmail(
    String email,
  ) async {
    final String normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty) {
      return const PasswordResetResult.failure(
        'Bitte gib zuerst Deine E-Mail-Adresse ein.',
      );
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: normalizedEmail,
      );

      return const PasswordResetResult.success();
    } on FirebaseAuthException catch (error) {
      return PasswordResetResult.failure(
        _messageForFirebaseAuthException(error),
      );
    } catch (error, stackTrace) {
      debugPrint('Unexpected password reset error: $error');
      debugPrintStack(stackTrace: stackTrace);

      return const PasswordResetResult.failure(
        'Die E-Mail konnte gerade nicht versendet werden.',
      );
    }
  }

  Future<void> signOut() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _firebaseAuth.signOut();
  }

  Future<void> updateUsername(String displayName) async {
    final User? user = currentUser;
    final String normalizedName = displayName.trim();

    if (user == null || normalizedName.isEmpty) {
      return;
    }

    await user.updateDisplayName(normalizedName);
    await user.reload();
  }

  Future<void> deleteAccountWithReauthentication(
    String email,
    String password,
  ) async {
    final User? user = currentUser;
    if (user == null) return;

    final AuthCredential credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
    await user.delete();
  }

  Future<void> updatePasswordWithCurrentPassword(
    String email,
    String currentPassword,
    String newPassword,
  ) async {
    final User? user = currentUser;
    if (user == null) return;

    final AuthCredential credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> _configurePushNotifications() async {
    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final String? token = await _firebaseMessaging.getToken();

      if (token != null && token.trim().isNotEmpty) {
        await updateUserFCMToken(token);
      }

      await _tokenRefreshSubscription?.cancel();

      _tokenRefreshSubscription =
          _firebaseMessaging.onTokenRefresh.listen(
        (String refreshedToken) async {
          try {
            await updateUserFCMToken(refreshedToken);
          } catch (error, stackTrace) {
            debugPrint(
              'Could not persist refreshed FCM token: $error',
            );
            debugPrintStack(stackTrace: stackTrace);
          }
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Push notification setup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  String _messageForFirebaseAuthException(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'invalid-email':
        return 'Diese E-Mail-Adresse ist nicht gültig.';
      case 'user-disabled':
        return 'Dieses Benutzerkonto wurde deaktiviert.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-Mail-Adresse oder Passwort sind nicht korrekt.';
      case 'email-already-in-use':
        return 'Für diese E-Mail-Adresse besteht bereits ein Konto.';
      case 'weak-password':
        return 'Bitte wähle ein stärkeres Passwort.';
      case 'too-many-requests':
        return 'Zu viele Versuche. Bitte warte kurz und versuche es erneut.';
      case 'network-request-failed':
        return 'Bitte überprüfe Deine Internetverbindung.';
      case 'operation-not-allowed':
        return 'Diese Anmeldemethode ist derzeit nicht aktiviert.';
      case 'requires-recent-login':
        return 'Bitte melde Dich erneut an und wiederhole den Vorgang.';
      default:
        return error.message ??
            'Es ist ein unbekannter Fehler aufgetreten.';
    }
  }
}
