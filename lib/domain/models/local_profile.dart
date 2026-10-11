import 'dart:typed_data';

/// Device-local identity, independent of any future authentication account.
class LocalProfile {
  const LocalProfile({this.name = '', this.email = '', this.avatar});
  final String name;
  final String email;
  final Uint8List? avatar;
}
