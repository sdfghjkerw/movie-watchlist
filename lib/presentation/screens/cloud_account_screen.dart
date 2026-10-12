import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/firebase_providers.dart';
import '../state/cloud_sync_controller.dart';
import '../state/diary_controller.dart';
import '../state/profile_controller.dart';
import '../state/watchlist_controller.dart';
import '../localization/app_strings.dart';

class CloudAccountScreen extends ConsumerStatefulWidget {
  const CloudAccountScreen({super.key});

  @override
  ConsumerState<CloudAccountScreen> createState() => _CloudAccountScreenState();
}

class _CloudAccountScreenState extends ConsumerState<CloudAccountScreen> {
  Future<void> _sync() async {
    try {
      await ref.read(cloudSyncProvider.notifier).syncNow();
    } catch (_) {
      // The controller publishes the error without replacing the local copy.
    }
  }

  Future<void> _registerPush() async {
    try {
      await ref.read(cloudSyncProvider.notifier).registerForPush();
    } catch (_) {
      // The controller status below explains why registration did not finish.
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider)?.signOut();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref
        .watch(authStateProvider)
        .whenOrNull(data: (value) => value);
    final sync = ref.watch(cloudSyncProvider);
    final diary = ref.watch(diaryProvider);
    final watchlist = ref.watch(watchlistProvider);
    final profile = ref.watch(profileProvider);
    final colors = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Аккаунт'.tr(context)),
        actions: [
          IconButton(
            key: const ValueKey('account-home'),
            tooltip: 'На главную'.tr(context),
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.home_outlined),
          ),
          IconButton(
            key: const ValueKey('account-sign-out'),
            tooltip: 'Выйти'.tr(context),
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth > 760
                ? (constraints.maxWidth - 600) / 2
                : 20,
            vertical: 24,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colors.secondaryContainer,
                    child: Icon(
                      Icons.person_rounded,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName?.isNotEmpty == true
                              ? user!.displayName!
                              : user?.email ?? 'Аккаунт Firebase'.tr(context),
                          style: type.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: type.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.cloud_done_rounded, color: colors.secondary),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('Синхронизация'.tr(context), style: type.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Локальные данные объединяются с этим аккаунтом. При совпадении ID сохраняется запись с этого устройства; уникальные записи из облака и Hive остаются в обоих местах.'
                  .tr(context),
              style: type.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _SyncCount(
              icon: Icons.bookmarks_outlined,
              label: 'Фильмы в списке просмотра'.tr(context),
              value: watchlist.length,
            ),
            _SyncCount(
              icon: Icons.auto_stories_outlined,
              label: 'Записи дневника'.tr(context),
              value: diary.length,
            ),
            _SyncCount(
              icon: Icons.person_outline_rounded,
              label: 'Локальный профиль'.tr(context),
              value: profile.name.isEmpty
                  ? 'Не заполнен'.tr(context)
                  : 'Заполнен'.tr(context),
            ),
            if (sync.lastSyncedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Синхронизировано: ${MaterialLocalizations.of(context).formatMediumDate(sync.lastSyncedAt!)}',
                style: type.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
            if (sync.error != null) ...[
              const SizedBox(height: 12),
              Text(
                sync.error!.tr(context),
                key: const ValueKey('cloud-sync-error'),
                style: TextStyle(color: colors.error),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('cloud-sync-now'),
              onPressed: sync.isSyncing ? null : _sync,
              icon: sync.isSyncing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded),
              label: Text('Синхронизировать сейчас'.tr(context)),
            ),
            const SizedBox(height: 32),
            Text('Push-уведомления'.tr(context), style: type.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Разрешение запрашивается только после нажатия. Токен этого устройства хранится в собственном разделе аккаунта в Firestore.'
                  .tr(context),
              style: type.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            if (sync.fcmTokenPreview != null) ...[
              const SizedBox(height: 8),
              Text(
                'Устройство зарегистрировано: ${sync.fcmTokenPreview}',
                key: const ValueKey('fcm-token-preview'),
                style: type.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('enable-push'),
              onPressed: sync.isSyncing ? null : _registerPush,
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text('Включить уведомления'.tr(context)),
            ),
            if (sync.lastNotification != null) ...[
              const SizedBox(height: 12),
              Text(
                'Последнее уведомление: ${sync.lastNotification}',
                key: const ValueKey('last-push-message'),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Выход не удаляет локальные записи с этого устройства.'.tr(
                context,
              ),
              style: type.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncCount extends StatelessWidget {
  const _SyncCount({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final Object value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(label),
    trailing: Text('$value'),
  );
}
