import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/local_profile.dart';

final profileProvider = NotifierProvider<ProfileController, LocalProfile>(
  ProfileController.new,
);

class ProfileController extends Notifier<LocalProfile> {
  Future<void> _pending = Future.value();
  @override
  LocalProfile build() => ref.watch(profileRepositoryProvider).profile;
  Future<void> save(LocalProfile profile) {
    final result = _pending.then((_) async {
      await ref.read(profileRepositoryProvider).save(profile);
      if (ref.mounted) state = profile;
    });
    _pending = result.catchError((Object _) {});
    return result;
  }
}
