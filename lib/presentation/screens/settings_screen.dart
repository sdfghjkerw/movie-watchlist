import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';
import '../state/settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _saving = false;
  String? _message;
  bool _failed = false;
  Future<void> _update({String? theme, String? language}) async {
    setState(() {
      _saving = true;
      _message = 'Сохраняем…';
      _failed = false;
    });
    try {
      await ref
          .read(settingsProvider.notifier)
          .update(theme: theme, language: language);
      if (mounted) setState(() => _message = 'Сохранено');
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'Не удалось сохранить. Попробуй ещё раз.';
          _failed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final colors = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Настройки'.tr(context))),
      body: LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth > 720
                ? (constraints.maxWidth - 640) / 2
                : 20,
            vertical: 24,
          ),
          children: [
            Icon(Icons.tune_rounded, size: 40, color: colors.secondary),
            const SizedBox(height: 20),
            Text(
              'Твой комфортный просмотр'.tr(context),
              style: type.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Настрой оформление и язык приложения.'.tr(context),
              style: type.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            Text('Тема'.tr(context), style: type.titleLarge),
            const SizedBox(height: 12),
            for (final option in [
              ('dark', 'Тёмная', Icons.dark_mode_outlined),
              ('light', 'Светлая', Icons.light_mode_outlined),
              ('system', 'Системная', Icons.brightness_auto_outlined),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: settings.theme == option.$1
                      ? colors.primary.withValues(alpha: .15)
                      : colors.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: settings.theme == option.$1
                          ? colors.primary
                          : colors.outlineVariant,
                    ),
                  ),
                  child: ListTile(
                    key: ValueKey('settings-theme-${option.$1}'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    enabled: !_saving,
                    leading: Icon(option.$3),
                    title: Text(option.$2.tr(context)),
                    subtitle: option.$1 == 'system'
                        ? Text('Следовать настройкам устройства'.tr(context))
                        : null,
                    trailing: settings.theme == option.$1
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: colors.primary,
                          )
                        : null,
                    onTap: () => _update(theme: option.$1),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text('Язык'.tr(context), style: type.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final option in [('ru', 'Русский'), ('en', 'English')])
                  ChoiceChip(
                    key: ValueKey('settings-language-${option.$1}'),
                    label: Text(option.$2),
                    selected: settings.language == option.$1,
                    onSelected: _saving
                        ? null
                        : (_) => _update(language: option.$1),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            if (_message != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  _message!.tr(context),
                  key: const ValueKey('settings-status'),
                  style: TextStyle(
                    color: _failed ? colors.error : colors.secondary,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Данные сохраняются на этом устройстве.'.tr(context),
              style: type.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
