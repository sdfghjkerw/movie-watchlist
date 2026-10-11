import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/diary_entry.dart';
import '../../domain/models/movie.dart';
import '../localization/app_strings.dart';
import '../state/diary_controller.dart';
import 'save_action.dart';

class DiaryActions extends ConsumerStatefulWidget {
  const DiaryActions({super.key, required this.movie, this.onDraftChanged});
  final Movie movie;
  final ValueChanged<bool>? onDraftChanged;
  @override
  ConsumerState<DiaryActions> createState() => DiaryActionsState();
}

class DiaryActionsState extends ConsumerState<DiaryActions> {
  final _text = TextEditingController();
  int? _score;
  int? _savedScore;
  String _savedReview = '';
  String _lastText = '';
  bool _saving = false;
  bool _actionSaving = false;
  bool _saved = false;
  String? _error;
  bool? _reportedDirty;
  bool get hasChanges => _score != _savedScore || _text.text != _savedReview;
  bool get isSaving => _saving;

  DiaryEntry get _entry =>
      ref
          .read(diaryProvider)
          .where((entry) => entry.movie.id == widget.movie.id)
          .firstOrNull ??
      DiaryEntry(movie: widget.movie);

  @override
  void initState() {
    super.initState();
    final entry = _entry;
    _score = _savedScore = entry.score;
    _text.text = _lastText = _savedReview = entry.review;
    _text.addListener(_textChanged);
  }

  void _textChanged() {
    // Cursor and focus changes also notify TextEditingController listeners.
    if (_lastText == _text.text) return;
    _lastText = _text.text;
    _changed();
  }

  void _changed() {
    setState(() {
      _saved = false;
      _error = null;
    });
    _reportDirty();
  }

  void _reportDirty() {
    final dirty = hasChanges;
    if (_reportedDirty == dirty) return;
    _reportedDirty = dirty;
    widget.onDraftChanged?.call(dirty);
  }

  Future<bool> save() async {
    if (_saving || _actionSaving) return false;
    if (!hasChanges) return true;
    final changeScore = _score != _savedScore;
    final changeReview = _text.text != _savedReview;
    setState(() {
      _saving = true;
      _error = null;
    });
    _reportDirty();
    try {
      await ref
          .read(diaryProvider.notifier)
          .update(
            widget.movie,
            updateScore: changeScore,
            score: _score,
            review: changeReview ? _text.text.trim() : null,
          );
      if (!mounted) return true;
      final entry = _entry;
      _text.removeListener(_textChanged);
      _text.text = _lastText = _savedReview = entry.review;
      _text.addListener(_textChanged);
      setState(() {
        _score = _savedScore = entry.score;
        _saved = true;
      });
      _reportDirty();
      return true;
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Не удалось сохранить. Попробуй ещё раз.');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        _reportDirty();
      }
    }
  }

  Future<void> _toggle({bool? favorite, bool? watched}) async {
    setState(() => _actionSaving = true);
    await saveAction(
      context,
      () => ref
          .read(diaryProvider.notifier)
          .update(widget.movie, favorite: favorite, watched: watched),
    );
    if (mounted) setState(() => _actionSaving = false);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry =
        ref
            .watch(diaryProvider)
            .where((entry) => entry.movie.id == widget.movie.id)
            .firstOrNull ??
        DiaryEntry(movie: widget.movie);
    final colors = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    final busy = _saving || _actionSaving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('toggle-watched'),
              onPressed: busy
                  ? null
                  : () => _toggle(watched: entry.watchedAt == null),
              icon: Icon(
                entry.watchedAt == null
                    ? Icons.check_circle_outline
                    : Icons.check_circle,
              ),
              label: Text(
                (entry.watchedAt == null
                        ? 'Отметить просмотренным'
                        : 'Убрать отметку просмотра')
                    .tr(context),
              ),
            ),
            OutlinedButton.icon(
              key: const ValueKey('toggle-favorite'),
              onPressed: busy ? null : () => _toggle(favorite: !entry.favorite),
              icon: Icon(
                entry.favorite ? Icons.favorite : Icons.favorite_border,
              ),
              label: Text(
                (entry.favorite
                        ? 'Убрать из избранного'
                        : 'Добавить в избранное')
                    .tr(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary.withValues(alpha: .13),
                colors.surfaceContainerLow,
              ],
            ),
            border: Border.all(color: colors.primary.withValues(alpha: .18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 20,
                    color: colors.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Мой кинодневник'.tr(context),
                      style: type.labelLarge?.copyWith(
                        color: colors.secondary,
                        letterSpacing: .6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  Text('Моя оценка'.tr(context), style: type.titleLarge),
                  Text(
                    _score == null ? 'Без оценки'.tr(context) : '$_score/10',
                    key: const ValueKey('personal-score'),
                    style: type.titleLarge?.copyWith(color: colors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 480 ? 10 : 5;
                  return Wrap(
                    children: [
                      for (var value = 1; value <= 10; value++)
                        SizedBox(
                          width: constraints.maxWidth / columns,
                          height: 48,
                          child: IconButton(
                            key: ValueKey('rating-star-$value'),
                            tooltip: '${'Оценка'.tr(context)} $value/10',
                            isSelected: _score != null && value <= _score!,
                            onPressed: busy
                                ? null
                                : () {
                                    _score = value;
                                    _changed();
                                  },
                            icon: Icon(
                              Icons.star_outline_rounded,
                              color: colors.onSurfaceVariant,
                            ),
                            selectedIcon: Icon(
                              Icons.star_rounded,
                              color: colors.primary,
                            ),
                            iconSize: 30,
                          ),
                        ),
                    ],
                  );
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const ValueKey('clear-score'),
                  onPressed: busy || _score == null
                      ? null
                      : () {
                          _score = null;
                          _changed();
                        },
                  child: Text('Убрать оценку'.tr(context)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Мои впечатления'.tr(context), style: type.titleMedium),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('review-text'),
                controller: _text,
                readOnly: busy,
                minLines: 4,
                maxLines: 12,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText: 'Что ты думаешь об этом фильме?'.tr(context),
                  filled: true,
                  fillColor: colors.surface.withValues(alpha: .65),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  contentPadding: const EdgeInsets.all(18),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (_error ??
                        (_saving
                            ? 'Сохраняем…'
                            : hasChanges
                            ? 'Есть несохранённые изменения'
                            : _saved
                            ? 'Сохранено'
                            : 'Данные сохраняются на этом устройстве.'))
                    .tr(context),
                key: const ValueKey('diary-status'),
                style: type.bodySmall?.copyWith(
                  color: _error != null
                      ? colors.error
                      : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const ValueKey('save-diary'),
                  onPressed: busy || !hasChanges ? null : save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text('Сохранить'.tr(context)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
