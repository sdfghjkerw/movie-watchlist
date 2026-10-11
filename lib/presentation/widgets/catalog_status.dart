import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

class CatalogStatus extends StatelessWidget {
  const CatalogStatus({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message.tr(context), textAlign: TextAlign.center),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: Text('Повторить'.tr(context))),
      ],
    ),
  );
}
