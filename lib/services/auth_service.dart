  import 'package:flutter/foundation.dart' show kIsWeb;
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:google_sign_in/google_sign_in.dart';

  /// Handles Phone/OTP, Email/Password, and Google authentication, and ensures a
  /// matching `users` Firestore document exists after any successful sign-in.
  class AuthService {
    static final AuthService _instance = AuthService._internal();
    factory AuthService() => _instance;
    AuthService._internal();

    final FirebaseAuth _auth = FirebaseAuth.instance;

    String? _verificationId;

    Stream<User?> get authStateChanges => _auth.authStateChanges();
    User? get currentUser => _auth.currentUser;
    Future<void> signOut() async {
      if (!kIsWeb) {
        try {
          await GoogleSignIn().signOut();
        } catch (_) {}
      }
      await _auth.signOut();
    }

    // ---------------------------------------------------------------------
    // PHONE / OTP
    // ---------------------------------------------------------------------

    Future<void> sendOtp({
      required String phoneNumber,
      required Function(String verificationId) codeSentCallback,
      required Function(String message) errorCallback,
    }) async {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          try {
            final result = await _auth.signInWithCredential(credential);
            await _ensureUserDocument(
              result.user!,
              isNewUser: result.additionalUserInfo?.isNewUser ?? false,
            );
          } catch (e) {
            errorCallback('Sign-in succeeded but saving your profile failed. Please try logging in again.');
          }
        },
        verificationFailed: (e) => errorCallback(e.message ?? 'Verification failed'),
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          codeSentCallback(verificationId);
        },
        codeAutoRetrievalTimeout: (verificationId) => _verificationId = verificationId,
      );
    }
    Future<User?> verifyOtp(String smsCode) async {
      if (_verificationId == null) {
        throw FirebaseAuthException(
          code: 'session-expired',
          message: 'Verification ID not found. Please request a new OTP.',
        );
      }
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      await _ensureUserDocument(result.user!, isNewUser: result.additionalUserInfo?.isNewUser ?? false);
      return result.user;
    }

    // ---------------------------------------------------------------------
    // EMAIL / PASSWORD
    // ---------------------------------------------------------------------

    /// Throws a FirebaseAuthException on failure (e.g. wrong-password,
    /// user-not-found, invalid-email) — catch this in the UI to show a
    /// friendly error message.
    Future<User?> signInWithEmail({
      required String email,
      required String password,
    }) async {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _ensureUserDocument(result.user!, isNewUser: false);
      return result.user;
    }

    /// Throws a FirebaseAuthException on failure (e.g. email-already-in-use,
    /// weak-password, invalid-email).
    Future<User?> signUpWithEmail({
      required String email,
      required String password,
      required String name,
    }) async {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await result.user?.updateDisplayName(name);
      await _ensureUserDocument(result.user!, isNewUser: true, name: name);
      return result.user;
    }

    Future<void> sendPasswordResetEmail(String email) {
      return _auth.sendPasswordResetEmail(email: email.trim());
    }

    // ---------------------------------------------------------------------
    // GOOGLE SIGN-IN
    // ---------------------------------------------------------------------

    /// Initiates Google Sign-In with an account picker and authenticates with Firebase.
    /// Works seamlessly across Web and Mobile (Android / iOS).
    Future<User?> signInWithGoogle() async {
      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          // User cancelled the account selection dialog
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      if (userCredential.user != null) {
        await _ensureUserDocument(
          userCredential.user!,
          isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
          name: userCredential.user!.displayName,
        );
      }

      return userCredential.user;
    }

    // ---------------------------------------------------------------------
    // SHARED
    // ---------------------------------------------------------------------

    Future<void> _ensureUserDocument(User user, {required bool isNewUser, String? name}) async {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      if (isNewUser) {
        await docRef.set({
          'name': name ?? user.displayName,
          'phone': user.phoneNumber,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Make sure a doc exists even if this user was created before this
        // field/collection existed — avoids null-data surprises in Profile.
        final doc = await docRef.get();
        if (!doc.exists) {
          await docRef.set({
            'name': name ?? user.displayName,
            'phone': user.phoneNumber,
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          final updates = <String, dynamic>{};
          if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
            updates['phone'] = user.phoneNumber;
          }
          if (user.email != null && user.email!.isNotEmpty) {
            updates['email'] = user.email;
          }
          if (updates.isNotEmpty) {
            await docRef.set(updates, SetOptions(merge: true));
          }
        }
      }
    }
  }