import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.bytes,
    this.radius = 46,
  });
  final String name;
  final Uint8List? bytes;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback = name.trim().isEmpty
        ? Icon(
            Icons.person_outline_rounded,
            size: radius,
            color: colors.primary,
          )
        : Text(
            name.trim().characters.first.toUpperCase(),
            style: TextStyle(fontSize: radius, color: colors.primary),
          );
    return Semantics(
      image: true,
      label: 'Фото профиля'.tr(context),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: colors.primary.withValues(alpha: .15),
        child: bytes == null
            ? fallback
            : ClipOval(
                child: Image.memory(
                  bytes!,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                ),
              ),
      ),
    );
  }
}
