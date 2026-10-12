import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/firebase_auth_repository.dart';
import '../data/repositories/firestore_user_data_repository.dart';
import '../domain/models/authenticated_user.dart';
import '../domain/repositories/auth_repository.dart';
import 'firebase_configuration.dart';

final firebaseEnabledProvider = Provider<bool>((ref) => false);
final firebaseSetupMessageProvider = Provider<String?>((ref) => null);
final firebaseLocalConfigurationProvider =
    Provider<FirebaseLocalConfiguration?>((ref) => null);

final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  if (!ref.watch(firebaseEnabledProvider)) return null;
  final configuration = ref.watch(firebaseLocalConfigurationProvider);
  if (configuration == null) return null;
  return FirebaseAuthRepository(FirebaseAuth.instance, configuration);
});

final authStateProvider = StreamProvider<AuthenticatedUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository?.authChanges ?? Stream.value(null);
});

final firestoreUserDataRepositoryProvider =
    Provider<FirestoreUserDataRepository?>((ref) {
      if (!ref.watch(firebaseEnabledProvider)) return null;
      return FirestoreUserDataRepository(FirebaseFirestore.instance);
    });
