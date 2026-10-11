import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/movie.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../localization/app_strings.dart';
import '../state/watchlist_controller.dart';
import '../widgets/catalog_status.dart';
import '../widgets/diary_actions.dart';
import '../widgets/movie_poster.dart';
import '../widgets/save_action.dart';

class MovieDetailsScreen extends ConsumerStatefulWidget {
  const MovieDetailsScreen({
    super.key,
    required this.movie,
    this.focusDiary = false,
  });
  final Movie movie;
  final bool focusDiary;
  @override
  ConsumerState<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends ConsumerState<MovieDetailsScreen> {
  final _diary = GlobalKey<DiaryActionsState>();
  final _editorAnchor = GlobalKey();
  final _exitNotice = GlobalKey();
  bool _dirty = false;
  bool _confirmExit = false;
  bool _allowExit = false;

  void _focusDiaryEditor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.focusDiary) return;
      final target = _editorAnchor.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          alignment: .06,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _requestExit() {
    if (_diary.currentState?.isSaving ?? false) return;
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _confirmExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _exitNotice.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 250),
        );
      }
    });
  }

  void _exit() {
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(movieDetailsProvider(widget.movie.id));
    ref.listen(movieDetailsProvider(widget.movie.id), (previous, next) {
      if (next.hasValue) _focusDiaryEditor();
    });
    if (widget.focusDiary) _focusDiaryEditor();
    final repository = ref.watch(catalogRepositoryProvider);
    final movie = details.value ?? widget.movie;
    final colors = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    final isSaved = ref
        .watch(watchlistProvider)
        .any((item) => item.id == movie.id);
    final poster = SizedBox(
      width: 190,
      height: 285,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: .25),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MoviePoster(url: movie.posterUrl),
              if (movie.posterUrl == null)
                Positioned(
                  bottom: 18,
                  left: 12,
                  right: 12,
                  child: Text(
                    'Постер пока недоступен'.tr(context),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MOVIE WATCHLIST',
          style: type.labelSmall?.copyWith(
            letterSpacing: 3,
            color: colors.secondary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          movie.title,
          style: type.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        if (movie.originalTitle != null &&
            movie.originalTitle != movie.title) ...[
          const SizedBox(height: 8),
          Text(
            movie.originalTitle!,
            style: type.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 18),
        Text(
          [
            movie.year?.toString() ?? 'Год неизвестен'.tr(context),
            movie.genre.tr(context),
            if (movie.runtimeMinutes != null)
              '${movie.runtimeMinutes} ${'мин'.tr(context)}',
          ].join(' · '),
          style: type.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(Icons.star_rounded, color: colors.secondary, size: 20),
            const SizedBox(width: 8),
            Text(
              'TMDB ${movie.rating?.toStringAsFixed(1) ?? '—'}/10',
              style: type.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.tonalIcon(
          key: const ValueKey('toggle-watchlist'),
          onPressed: () => saveAction(
            context,
            () => ref.read(watchlistProvider.notifier).toggle(movie),
          ),
          icon: Icon(
            isSaved
                ? Icons.bookmark_added_outlined
                : Icons.bookmark_add_outlined,
          ),
          label: Text(
            (isSaved ? 'Удалить из списка' : 'В список просмотра').tr(context),
          ),
        ),
      ],
    );
    return PopScope(
      canPop: _allowExit || !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Navigator.canPop(context)
              ? BackButton(onPressed: _requestExit)
              : null,
          title: Text('О фильме'.tr(context)),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) => ListView(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth > 960
                  ? (constraints.maxWidth - 900) / 2
                  : 20,
              vertical: 24,
            ),
            children: [
              if (repository is CachedCatalogRepository &&
                  repository.detailsUseCache(movie.id))
                Text('Сохранённые сведения о фильме.'.tr(context)),
              if (details.isLoading) const LinearProgressIndicator(),
              if (details.hasError)
                CatalogStatus(
                  message: details.error.toString(),
                  onRetry: () =>
                      ref.invalidate(movieDetailsProvider(widget.movie.id)),
                ),
              if (constraints.maxWidth >= 650)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    poster,
                    const SizedBox(width: 36),
                    Expanded(child: heading),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: poster),
                    const SizedBox(height: 32),
                    heading,
                  ],
                ),
              const SizedBox(height: 32),
              if (_confirmExit)
                Container(
                  key: _exitNotice,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Сохранить изменения перед выходом?'.tr(context),
                        style: type.titleMedium,
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            key: const ValueKey('stay-diary'),
                            onPressed: () =>
                                setState(() => _confirmExit = false),
                            child: Text('Остаться'.tr(context)),
                          ),
                          TextButton(
                            key: const ValueKey('discard-diary'),
                            onPressed: (_diary.currentState?.isSaving ?? false)
                                ? null
                                : _exit,
                            child: Text('Выйти без сохранения'.tr(context)),
                          ),
                          FilledButton(
                            key: const ValueKey('save-and-exit'),
                            onPressed: () async {
                              final saved = await _diary.currentState!.save();
                              if (mounted && saved) _exit();
                            },
                            child: Text('Сохранить и выйти'.tr(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Container(
                key: _editorAnchor,
                child: DiaryActions(
                  key: _diary,
                  movie: movie,
                  onDraftChanged: (dirty) {
                    setState(() {
                      _dirty = dirty;
                      if (!dirty) _confirmExit = false;
                    });
                  },
                ),
              ),
              const SizedBox(height: 36),
              Text('О фильме'.tr(context), style: type.titleLarge),
              const SizedBox(height: 12),
              Text(
                movie.description.tr(context),
                style: type.bodyLarge?.copyWith(
                  height: 1.7,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
