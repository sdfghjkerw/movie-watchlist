import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

Future<void> saveAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось сохранить. Попробуй ещё раз.'.tr(context)),
        ),
      );
    }
  }
}
