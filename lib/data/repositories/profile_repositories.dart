import 'dart:typed_data';

import 'package:hive/hive.dart';

import '../../domain/models/local_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class InMemoryProfileRepository implements ProfileRepository {
  LocalProfile _profile = const LocalProfile();
  @override
  LocalProfile get profile => _profile;
  @override
  Future<void> save(LocalProfile profile) async {
    _profile = profile;
  }
}

class HiveProfileRepository implements ProfileRepository {
  HiveProfileRepository(this.box);
  final Box<dynamic> box;
  @override
  LocalProfile get profile {
    final value = box.get('identity');
    if (value is! Map) return const LocalProfile();
    final bytes = value['avatar'];
    return LocalProfile(
      name: value['name'] as String? ?? '',
      email: value['email'] as String? ?? '',
      avatar: bytes is Uint8List ? bytes : null,
    );
  }

  @override
  Future<void> save(LocalProfile profile) => box.put('identity', {
    'name': profile.name,
    'email': profile.email,
    'avatar': profile.avatar,
  });
}
