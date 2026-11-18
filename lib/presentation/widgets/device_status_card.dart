import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../localization/app_strings.dart';

class DeviceStatusCard extends ConsumerWidget {
  const DeviceStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    final status = ref.watch(androidDeviceStatusProvider);

    return Card(
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: Icon(Icons.battery_5_bar_rounded, color: colors.secondary),
          title: Text('Состояние устройства'.tr(context)),
          subtitle: status.when(
            loading: () => Text('Читаем состояние батареи…'.tr(context)),
            error: (_, _) => Text(
              'Не удалось получить данные устройства.'.tr(context),
              style: type.bodySmall?.copyWith(color: colors.error),
            ),
            data: (value) => Text(
              '${value.deviceModel} · Android ${value.androidVersion}\n'
              '${value.batteryLevel == null ? 'Заряд недоступен'.tr(context) : '${value.batteryLevel}%'}'
              '${value.isCharging ? ' · Заряжается'.tr(context) : ''}',
            ),
          ),
          trailing: IconButton(
            tooltip: 'Обновить'.tr(context),
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(androidDeviceStatusProvider),
          ),
        ),
      ),
    );
  }
}
