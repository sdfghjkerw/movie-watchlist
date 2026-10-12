import '../models/authenticated_user.dart';

abstract interface class AuthRepository {
  Stream<AuthenticatedUser?> get authChanges;
  AuthenticatedUser? get currentUser;

  Future<void> createAccount({required String email, required String password});
  Future<void> signIn({required String email, required String password});
  Future<void> signInWithGoogle();
  Future<void> signOut();
}
