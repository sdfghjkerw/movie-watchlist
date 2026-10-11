import '../models/local_profile.dart';

abstract interface class ProfileRepository {
  LocalProfile get profile;
  Future<void> save(LocalProfile profile);
}
