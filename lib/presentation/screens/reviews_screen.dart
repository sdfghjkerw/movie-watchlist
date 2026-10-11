import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/diary_entry.dart';
import '../localization/app_strings.dart';
import '../state/diary_controller.dart';
import '../widgets/movie_poster.dart';

enum _ReviewFilter { all, withText, ratingOnly }

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});
  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  final _search = TextEditingController();
  _ReviewFilter _filter = _ReviewFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diary = ref.watch(diaryProvider);
    final colors = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    final query = _search.text.trim().toLowerCase();
    final matchingQuery = diary
        .where((entry) {
          if (entry.score == null && entry.review.trim().isEmpty) return false;
          return query.isEmpty ||
              entry.movie.title.toLowerCase().contains(query) ||
              entry.review.toLowerCase().contains(query);
        })
        .toList(growable: false);
    final entries = matchingQuery
        .where(
          (entry) => switch (_filter) {
            _ReviewFilter.all => true,
            _ReviewFilter.withText => entry.review.trim().isNotEmpty,
            _ReviewFilter.ratingOnly => entry.review.trim().isEmpty,
          },
        )
        .toList(growable: false);
    final allCount = matchingQuery.length;
    final reviewsCount = matchingQuery
        .where((entry) => entry.review.trim().isNotEmpty)
        .length;
    final ratingsCount = matchingQuery
        .where((entry) => entry.review.trim().isEmpty)
        .length;
    final writtenReviews = entries
        .where((entry) => entry.review.trim().isNotEmpty)
        .toList();
    final ratingOnly = entries
        .where((entry) => entry.review.trim().isEmpty)
        .toList();

    Widget section(String title, List<DiaryEntry> values, String key) => Column(
      key: ValueKey(key),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: type.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${values.length}',
                style: type.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        for (var index = 0; index < values.length; index++) ...[
          if (index > 0)
            Divider(
              height: 1,
              color: colors.outlineVariant.withValues(alpha: .6),
            ),
          _ReviewEntryRow(entry: values[index]),
        ],
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text('Мои отзывы'.tr(context))),
      body: LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth > 900
                ? (constraints.maxWidth - 820) / 2
                : 20,
            vertical: 20,
          ),
          children: [
            Text(
              'Твоя история — фильм за фильмом'.tr(context),
              style: type.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Оценки и впечатления, сохранённые для себя.'.tr(context),
              style: type.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextField(
              key: const ValueKey('review-search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Найти фильм или впечатление'.tr(context),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        key: const ValueKey('clear-review-search'),
                        tooltip: 'Очистить'.tr(context),
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                      ),
                filled: true,
                fillColor: colors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final option in [
                    (_ReviewFilter.all, 'Все записи', allCount),
                    (_ReviewFilter.withText, 'С отзывом', reviewsCount),
                    (_ReviewFilter.ratingOnly, 'Только оценка', ratingsCount),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        key: ValueKey('review-filter-${option.$1.name}'),
                        label: Text('${option.$2.tr(context)} · ${option.$3}'),
                        selected: _filter == option.$1,
                        onSelected: (_) => setState(() => _filter = option.$1),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (entries.isEmpty)
              _EmptyReviews(searching: query.isNotEmpty, filter: _filter),
            if (entries.isNotEmpty && writtenReviews.isNotEmpty)
              section('С отзывом', writtenReviews, 'written-reviews'),
            if (entries.isNotEmpty &&
                writtenReviews.isNotEmpty &&
                ratingOnly.isNotEmpty)
              const SizedBox(height: 22),
            if (entries.isNotEmpty && ratingOnly.isNotEmpty)
              section('Только оценка', ratingOnly, 'rated-only'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ReviewEntryRow extends StatelessWidget {
  const _ReviewEntryRow({required this.entry});
  final DiaryEntry entry;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    final personalScore = entry.score;
    final scaledScore = personalScore == null ? null : personalScore / 2;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('review-entry-${entry.movie.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          '/movie/${entry.movie.id}?focusDiary=true',
          extra: entry.movie,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'review-poster-${entry.movie.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 84,
                    height: 126,
                    child: MoviePoster(url: entry.movie.posterUrl),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: type.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${entry.movie.year ?? 'Год неизвестен'.tr(context)} · ${entry.movie.genre.tr(context)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: type.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (personalScore != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (var star = 1; star <= 5; star++)
                            Icon(
                              (scaledScore! - star + 1) >= 1
                                  ? Icons.star_rounded
                                  : (scaledScore - star + 1) >= .5
                                  ? Icons.star_half_rounded
                                  : Icons.star_outline_rounded,
                              size: 17,
                              color: colors.primary,
                            ),
                          const SizedBox(width: 7),
                          Text(
                            '$personalScore/10',
                            style: type.labelMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (entry.review.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        entry.review.trim(),
                        key: ValueKey('review-excerpt-${entry.movie.id}'),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: type.bodyMedium?.copyWith(
                          height: 1.45,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews({required this.searching, required this.filter});
  final bool searching;
  final _ReviewFilter filter;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(
            searching ? Icons.search_off_rounded : Icons.movie_filter_outlined,
            size: 48,
            color: colors.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            (searching
                    ? 'Ничего не найдено'
                    : filter == _ReviewFilter.all
                    ? 'Пока нет отзывов и оценок.'
                    : filter == _ReviewFilter.withText
                    ? 'Пока нет отзывов'
                    : 'Пока нет оценок без текста')
                .tr(context),
            textAlign: TextAlign.center,
            style: type.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            (searching
                ? 'Попробуй изменить запрос или очистить поиск.'.tr(context)
                : 'Поставь оценку или запиши впечатление на странице фильма — оно появится здесь.'
                      .tr(context)),
            textAlign: TextAlign.center,
            style: type.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
