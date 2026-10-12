import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/firebase_providers.dart';
import '../state/profile_controller.dart';
import '../state/diary_controller.dart';
import '../state/watchlist_controller.dart';
import '../localization/app_strings.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_editor.dart';
import '../widgets/movie_poster.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editing = false;
  final _editor = GlobalKey();
  final _scroll = ScrollController();
  void _closeEditor() {
    setState(() => _editing = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _edit() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _editor.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 250),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final diary = ref.watch(diaryProvider);
    final watchlist = ref.watch(watchlistProvider);
    final authUser = ref
        .watch(authStateProvider)
        .whenOrNull(data: (value) => value);
    final highlights = diary
        .where((entry) => entry.score != null || entry.review.isNotEmpty)
        .take(3)
        .toList();
    final colors = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ЛИЧНЫЙ КИНОДНЕВНИК'.tr(context),
          style: type.labelSmall?.copyWith(
            letterSpacing: 2,
            color: colors.secondary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          profile.name.isEmpty ? 'Твой кинодневник'.tr(context) : profile.name,
          key: const ValueKey('profile-display-name'),
          style: type.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          profile.email.isEmpty ? 'Email не указан'.tr(context) : profile.email,
          key: const ValueKey('profile-display-email'),
          style: type.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          key: const ValueKey('edit-profile'),
          onPressed: _editing ? null : _edit,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text('Редактировать профиль'.tr(context)),
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль'.tr(context)),
        actions: [
          IconButton(
            key: const ValueKey('open-settings'),
            tooltip: 'Настройки'.tr(context),
            onPressed: () => context.push('/profile/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => ListView(
          controller: _scroll,
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth > 900
                ? (constraints.maxWidth - 820) / 2
                : 20,
            vertical: 24,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primary.withValues(alpha: .14),
                    colors.surfaceContainerLow,
                  ],
                ),
                border: Border.all(
                  color: colors.primary.withValues(alpha: .15),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, bounds) => bounds.maxWidth >= 480
                    ? Row(
                        children: [
                          ProfileAvatar(
                            name: profile.name,
                            bytes: profile.avatar,
                            radius: 56,
                          ),
                          const SizedBox(width: 28),
                          Expanded(child: identity),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileAvatar(
                            name: profile.name,
                            bytes: profile.avatar,
                            radius: 48,
                          ),
                          const SizedBox(height: 24),
                          identity,
                        ],
                      ),
              ),
            ),
            if (_editing) ...[
              const SizedBox(height: 24),
              ProfileEditor(
                key: _editor,
                initial: profile,
                onClose: _closeEditor,
              ),
            ],
            const SizedBox(height: 32),
            Text('Твоя история в кино'.tr(context), style: type.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Фильмы, к которым ты возвращаешься, и те, что ещё впереди.'.tr(
                context,
              ),
              style: type.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.outlineVariant),
                  bottom: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in [
                    (
                      'Просмотрено',
                      diary.where((entry) => entry.watchedAt != null).length,
                      Icons.check_circle_outline,
                    ),
                    (
                      'Хочу посмотреть',
                      watchlist.length,
                      Icons.bookmark_border_rounded,
                    ),
                    (
                      'Избранное',
                      diary.where((entry) => entry.favorite).length,
                      Icons.favorite_border_rounded,
                    ),
                  ])
                    Expanded(
                      child: Column(
                        children: [
                          Icon(item.$3, color: colors.secondary, size: 22),
                          const SizedBox(height: 12),
                          Text(
                            '${item.$2}',
                            key: ValueKey('profile-stat-${item.$1}'),
                            style: type.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              item.$1.tr(context),
                              textAlign: TextAlign.center,
                              style: type.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Из твоего дневника'.tr(context), style: type.titleLarge),
            const SizedBox(height: 18),
            if (highlights.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_stories_outlined,
                      size: 32,
                      color: colors.secondary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Здесь будут твои впечатления'.tr(context),
                            style: type.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Открой фильм и сохрани первую оценку или отзыв.'
                                .tr(context),
                            style: type.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            for (final entry in highlights)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  key: ValueKey('profile-film-${entry.movie.id}'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push(
                    '/movie/${entry.movie.id}',
                    extra: entry.movie,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 72,
                            height: 108,
                            child: MoviePoster(url: entry.movie.posterUrl),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.movie.title,
                                style: type.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (entry.score != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 18,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${entry.score}/10',
                                      style: type.labelLarge,
                                    ),
                                  ],
                                ),
                              ],
                              if (entry.review.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  entry.review,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: type.bodyMedium?.copyWith(
                                    height: 1.5,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                key: const ValueKey('open-cloud-account'),
                leading: Icon(
                  authUser == null
                      ? Icons.cloud_outlined
                      : Icons.cloud_done_outlined,
                ),
                title: Text(
                  authUser == null
                      ? 'Аккаунт и синхронизация'.tr(context)
                      : 'Синхронизация включена'.tr(context),
                ),
                subtitle: Text(
                  authUser?.email ??
                      'Войди, чтобы перенести дневник в облако.'.tr(context),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/account'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
