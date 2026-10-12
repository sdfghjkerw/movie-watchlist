import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';

import '../../app/firebase_configuration.dart';
import '../../domain/models/authenticated_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(
    this._auth,
    this._configuration, {
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final firebase.FirebaseAuth _auth;
  final FirebaseLocalConfiguration _configuration;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleInitialization;

  AuthenticatedUser? _map(firebase.User? user) => user == null
      ? null
      : AuthenticatedUser(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );

  @override
  AuthenticatedUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AuthenticatedUser?> get authChanges => _auth.userChanges().map(_map);

  @override
  Future<void> createAccount({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _auth.signInWithPopup(firebase.GoogleAuthProvider());
      return;
    }

    _googleInitialization ??= _googleSignIn.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? _configuration.googleIosClientId
          : null,
      serverClientId: _configuration.googleWebClientId,
    );
    await _googleInitialization;
    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) throw StateError('Google не вернул ID token.');
    final credential = firebase.GoogleAuthProvider.credential(idToken: idToken);
    await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) await _googleSignIn.signOut();
  }
}
